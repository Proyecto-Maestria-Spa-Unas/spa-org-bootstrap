#!/usr/bin/env bash
# Rulesets por capas (ADR-0005 y ADR-0006). Los rulesets que aplican a una rama se SUMAN y rige lo más estricto.
#
# Repos con develop (flujo de integración + liberación):
#   calidad-ramas-principales (main+develop): PR obligatorio, checks, sin force-push ni borrado.
#   integracion-develop       (develop)     : solo squash + historial lineal  → 1 commit por historia.
#   liberacion-main           (main)        : solo merge commit (develop → main conserva la historia, sin divergencia).
#                                             Si liberacion_qa: aprobación obligatoria de equipo-qa.
#   solo-qa-promueve-a-main   (main)        : si liberacion_qa, solo equipo-qa (y admins) actualizan main.
# Repos solo con main:
#   calidad-ramas-principales (main)        : PR, checks, solo squash, historial lineal.
#
# El bypass de un ruleset omite TODAS sus reglas: por eso el permiso de QA vive aislado en solo-qa-promueve-a-main.
source "$(dirname "$0")/../lib/common.sh"
log "06 · Protección de ramas por capas · QA gate = $ENABLE_QA_GATE"

ADMIN_ID="$(team_id plataforma-admins)"
QA_ID="$(team_id equipo-qa)"
OBSOLETOS=("proteccion-ramas-principales" "aprobacion-liberacion")

upsert_ruleset() {   # $1 repo · $2 payload JSON
  local repo="$1" payload="$2" name id
  name="$(jq -r .name <<<"$payload")"
  id="$(gh api "repos/$ORG/$repo/rulesets" --jq ".[] | select(.name==\"$name\") | .id" 2>/dev/null || true)"
  if [[ -n "$id" ]]; then
    gh api -X PUT "repos/$ORG/$repo/rulesets/$id" --input - --silent <<<"$payload" && info "  ↻ $name" || warn "  $repo: falló $name"
  else
    gh api -X POST "repos/$ORG/$repo/rulesets" --input - --silent <<<"$payload" && info "  + $name" || warn "  $repo: falló $name"
  fi
}

delete_ruleset() {   # $1 repo · $2 nombre
  local id
  id="$(gh api "repos/$ORG/$1/rulesets" --jq ".[] | select(.name==\"$2\") | .id" 2>/dev/null || true)"
  [[ -n "$id" ]] && gh api -X DELETE "repos/$ORG/$1/rulesets/$id" --silent && info "  − $2 (reemplazado)"
  return 0
}

for repo in $(repos); do
  ok "$repo"
  main='["refs/heads/'"$DEFAULT_BRANCH"'"]'
  dev='["refs/heads/'"$INTEGRATION_BRANCH"'"]'
  con_develop="$(repo_attr "$repo" rama_integracion)"
  liberacion_qa="$(repo_attr "$repo" liberacion_qa)"

  checks="$(repo_json "$repo" | jq -c '.checks')"
  if [[ "$ENABLE_QA_GATE" == "true" && "$(repo_attr "$repo" qa_gate)" == "true" ]]; then
    checks="$(jq -c '. + ["qa-gate / qa"]' <<<"$checks")"
  fi

  for viejo in "${OBSOLETOS[@]}"; do delete_ruleset "$repo" "$viejo"; done

  if [[ "$con_develop" == "true" ]]; then
    refs='["refs/heads/'"$DEFAULT_BRANCH"'","refs/heads/'"$INTEGRATION_BRANCH"'"]'
    metodos='["squash","merge"]'; lineal=false
  else
    refs="$main"; metodos='["squash"]'; lineal=true
  fi

  # ── calidad-ramas-principales
  upsert_ruleset "$repo" "$(jq -n --argjson refs "$refs" --argjson checks "$checks" --argjson admin "$ADMIN_ID" \
        --argjson metodos "$metodos" --argjson lineal "$lineal" '
    { name: "calidad-ramas-principales", target: "branch", enforcement: "active",
      conditions: { ref_name: { include: $refs, exclude: [] } },
      bypass_actors: [ { actor_id: $admin, actor_type: "Team", bypass_mode: "pull_request" } ],
      rules: (
        [ {type: "deletion"}, {type: "non_fast_forward"} ]
        + ( if $lineal then [ {type: "required_linear_history"} ] else [] end )
        + [ {type: "pull_request", parameters: {
              required_approving_review_count: 0, dismiss_stale_reviews_on_push: true,
              require_code_owner_review: false, require_last_push_approval: false,
              required_review_thread_resolution: true, allowed_merge_methods: $metodos } } ]
        + ( if ($checks|length) > 0 then
              [ {type: "required_status_checks", parameters: {
                  strict_required_status_checks_policy: true,
                  required_status_checks: ($checks | map({context: .})) } } ]
            else [] end ) ) }')"

  [[ "$con_develop" == "true" ]] || continue

  # ── integracion-develop: 1 commit por historia
  upsert_ruleset "$repo" "$(jq -n --argjson refs "$dev" --argjson admin "$ADMIN_ID" '
    { name: "integracion-develop", target: "branch", enforcement: "active",
      conditions: { ref_name: { include: $refs, exclude: [] } },
      bypass_actors: [ { actor_id: $admin, actor_type: "Team", bypass_mode: "pull_request" } ],
      rules: [ {type: "required_linear_history"},
               {type: "pull_request", parameters: {
                  required_approving_review_count: 0, dismiss_stale_reviews_on_push: true,
                  require_code_owner_review: false, require_last_push_approval: false,
                  required_review_thread_resolution: true, allowed_merge_methods: ["squash"] } } ] }')"

  # ── liberacion-main: merge commit (+ aprobación de QA si aplica)
  if [[ "$liberacion_qa" == "true" ]]; then aprob="$REQUIRED_APPROVALS"; else aprob=0; fi
  upsert_ruleset "$repo" "$(jq -n --argjson refs "$main" --argjson admin "$ADMIN_ID" --argjson qa "$QA_ID" \
        --argjson n "$aprob" --argjson conqa "$( [[ $liberacion_qa == true ]] && echo true || echo false )" '
    { name: "liberacion-main", target: "branch", enforcement: "active",
      conditions: { ref_name: { include: $refs, exclude: [] } },
      bypass_actors: [ { actor_id: $admin, actor_type: "Team", bypass_mode: "pull_request" } ],
      rules: [ {type: "pull_request", parameters: (
                 { required_approving_review_count: $n, dismiss_stale_reviews_on_push: true,
                   require_code_owner_review: false, require_last_push_approval: $conqa,
                   required_review_thread_resolution: true, allowed_merge_methods: ["merge"] }
                 + ( if $conqa then { required_reviewers: [ { minimum_approvals: 1, file_patterns: ["*"],
                                                              reviewer: { id: $qa, type: "Team" } } ] }
                     else {} end ) ) } ] }')"

  # ── solo-qa-promueve-a-main
  if [[ "$liberacion_qa" == "true" ]]; then
    upsert_ruleset "$repo" "$(jq -n --argjson refs "$main" --argjson qa "$QA_ID" --argjson admin "$ADMIN_ID" '
      { name: "solo-qa-promueve-a-main", target: "branch", enforcement: "active",
        conditions: { ref_name: { include: $refs, exclude: [] } },
        bypass_actors: [ { actor_id: $qa,    actor_type: "Team", bypass_mode: "pull_request" },
                         { actor_id: $admin, actor_type: "Team", bypass_mode: "pull_request" } ],
        rules: [ {type: "update"} ] }')"
  fi
done

gh variable set ENABLE_QA_GATE --org "$ORG" --visibility all --body "$ENABLE_QA_GATE" >/dev/null 2>&1 || true
