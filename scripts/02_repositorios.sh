#!/usr/bin/env bash
# Crea repositorios, aplica configuración de merge, seguridad, topics y entornos.
source "$(dirname "$0")/../lib/common.sh"
log "02 · Repositorios"

for repo in $(repos); do
  vis="$(repo_attr "$repo" visibility)"; desc="$(repo_attr "$repo" description)"
  tpl="$(repo_attr "$repo" template)"

  if repo_exists "$repo"; then
    info "$repo ya existe"
  else
    gh repo create "$ORG/$repo" "--$vis" --description "$desc" >/dev/null
    ok "$repo creado ($vis)"
  fi

  # Estrategia de merge: solo squash → historial lineal y 1 commit por PR (trazable a una HU)
  # Squash para integrar; merge commit solo en repos con develop, para las liberaciones develop → main (ADR-0006)
  # (GitHub rechaza con 422 los títulos de merge commit si el merge commit está deshabilitado)
  merge_commit=false; merge_args=()
  if [[ "$(repo_attr "$repo" rama_integracion)" == "true" ]]; then
    merge_commit=true; merge_args=(-f merge_commit_title=PR_TITLE -f merge_commit_message=PR_BODY)
  fi
  gh api -X PATCH "repos/$ORG/$repo" \
    -f description="$desc" \
    -F has_issues=true -F has_projects=true -F has_wiki=false \
    -F allow_squash_merge=true -F allow_merge_commit="$merge_commit" -F allow_rebase_merge=false \
    "${merge_args[@]}" \
    -F delete_branch_on_merge=true -F allow_auto_merge=true -F allow_update_branch=true \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
    -F is_template="$tpl" --silent && info "  merge: squash (integración)$([[ $merge_commit == true ]] && echo " + merge commit (liberación)"), borrar rama, auto-merge"

  # Topics
  args=(); while read -r t; do [[ -n "$t" ]] && args+=(-f "names[]=$t"); done < <(repo_list_attr "$repo" topics)
  ((${#args[@]})) && gh api -X PUT "repos/$ORG/$repo/topics" "${args[@]}" --silent

  # Seguridad de dependencias
  gh api -X PUT "repos/$ORG/$repo/vulnerability-alerts" --silent 2>/dev/null && info "  alertas Dependabot activas" || warn "  $repo: sin alertas Dependabot"
  gh api -X PUT "repos/$ORG/$repo/automated-security-fixes" --silent 2>/dev/null || true

  # Entornos de despliegue
  while read -r env; do
    [[ -z "$env" ]] && continue
    gh api -X PUT "repos/$ORG/$repo/environments/$env" --silent 2>/dev/null \
      && info "  entorno '$env'" || warn "  $repo: no se pudo crear entorno '$env' (revise plan)"
  done < <(repo_list_attr "$repo" entornos)

  # Workflows reutilizables accesibles desde toda la organización
  if [[ "$(repo_attr "$repo" compartir_workflows)" == "true" ]]; then
    gh api -X PUT "repos/$ORG/$repo/actions/permissions/access" -f access_level=organization --silent \
      && info "  workflows reutilizables compartidos con la organización" \
      || warn "  no se pudo compartir workflows de $repo"
  fi
done
