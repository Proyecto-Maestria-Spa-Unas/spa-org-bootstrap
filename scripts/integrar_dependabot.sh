#!/usr/bin/env bash
# Integra PRs de Dependabot de forma segura, uno a la vez: actualiza la rama según su estado,
# espera el nuevo commit, exige checks en verde sobre ESE commit y fusiona con squash.
#
# Uso:
#   ./scripts/integrar_dependabot.sh --listar                 # PRs de Dependabot abiertos en la organización
#   ./scripts/integrar_dependabot.sh <repo> <pr> [<pr> ...]   # integra esos PRs en orden; se detiene al primer fallo
source "$(dirname "$0")/../lib/common.sh"

listar() {
  log "PRs de Dependabot abiertos en $ORG"
  gh search prs --owner "$ORG" --author "app/dependabot" --state open --limit 100 \
    --json repository,number,title \
    --jq 'if length == 0 then "  ✔ ninguno" else .[] | "  \(.repository.name) #\(.number) · \(.title)" end'
}

diagnosticar() {   # $1 repo · $2 PR
  local run
  run=$(gh pr checks "$2" -R "$ORG/$1" --json state,link \
        --jq '[.[] | select(.state=="FAILURE") | .link][0]' | sed -n 's#.*/runs/\([0-9]*\).*#\1#p')
  [[ -n "$run" ]] || { info "sin checks fallidos"; return 0; }
  gh run view "$run" -R "$ORG/$1" --log-failed | grep -o "##\[error\].*\|Error: .*" | head -5
}

integrar() {   # $1 repo · $2 PR
  local repo="$1" pr="$2" estado antes despues run concl i
  for i in $(seq 1 12); do
    estado=$(gh pr view "$pr" -R "$ORG/$repo" --json mergeStateStatus --jq .mergeStateStatus)
    [[ "$estado" != "UNKNOWN" ]] && break; sleep 5
  done
  antes=$(gh pr view "$pr" -R "$ORG/$repo" --json headRefOid --jq .headRefOid)
  case "$estado" in
    BEHIND) gh pr update-branch "$pr" -R "$ORG/$repo" --rebase >/dev/null && info "↻ $repo #$pr: actualizado sobre la rama base" ;;
    DIRTY)  gh pr comment "$pr" -R "$ORG/$repo" --body "@dependabot recreate" >/dev/null && info "↻ $repo #$pr: conflicto, Dependabot lo recrea" ;;
    *)      read -r run concl < <(gh run list -R "$ORG/$repo" --workflow ci --commit "$antes" --limit 1 \
                                   --json databaseId,conclusion --jq '.[0] | "\(.databaseId) \(.conclusion)"')
            if [[ "$concl" == "failure" ]]; then
              gh run rerun "$run" -R "$ORG/$repo" >/dev/null && info "↻ $repo #$pr: checks antiguos en rojo, se re-ejecutan"
            else
              info "· $repo #$pr: al día ($estado)"
            fi ;;
  esac
  if [[ "$estado" == "BEHIND" || "$estado" == "DIRTY" ]]; then
    for i in $(seq 1 36); do
      despues=$(gh pr view "$pr" -R "$ORG/$repo" --json headRefOid --jq .headRefOid)
      [[ "$despues" != "$antes" ]] && break; sleep 10
    done
    [[ "$despues" != "$antes" ]] || { warn "$repo #$pr: la rama no cambió en 6 minutos"; return 1; }
  fi
  sleep 20
  gh pr checks "$pr" -R "$ORG/$repo" --watch --fail-fast >/dev/null \
    || { warn "$repo #$pr: checks fallidos, no se fusiona"; diagnosticar "$repo" "$pr"; return 1; }
  gh pr merge "$pr" -R "$ORG/$repo" --squash --delete-branch >/dev/null \
    && ok "$repo #$pr integrado"
}

case "${1:-}" in
  --listar|"") listar ;;
  *) repo="$1"; shift
     (($#)) || die "Indique al menos un número de PR"
     log "Integrando PRs de Dependabot en $repo: $*"
     for pr in "$@"; do integrar "$repo" "$pr" || exit 1; done ;;
esac
