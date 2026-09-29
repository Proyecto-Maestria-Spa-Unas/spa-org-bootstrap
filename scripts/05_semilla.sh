#!/usr/bin/env bash
# Publica el esqueleto inicial de cada repo (templates/) en 'main' y crea 'develop'.
source "$(dirname "$0")/../lib/common.sh"
log "05 · Contenido inicial (semilla) de cada repositorio"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

for repo in $(repos); do
  dir="$WORK/$repo"
  gh repo clone "$ORG/$repo" "$dir" -- --quiet 2>/dev/null || die "No se pudo clonar $repo"

  if git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1 && [[ "$FORCE_SEED" != "true" ]]; then
    info "$repo ya tiene commits → se omite (FORCE_SEED=true para forzar)"
    continue
  fi

  git -C "$dir" checkout -q -B "$DEFAULT_BRANCH"
  while read -r tpl; do
    [[ -z "$tpl" ]] && continue
    [[ -d "$TEMPLATES_DIR/$tpl" ]] || die "No existe templates/$tpl"
    cp -a "$TEMPLATES_DIR/$tpl/." "$dir/"
  done < <(repo_list_attr "$repo" plantillas)
  render_placeholders "$dir" "$repo"

  git -C "$dir" add -A
  git -C "$dir" -c commit.gpgsign=false commit -q -s -m "chore: estructura inicial de $repo" || { info "$repo sin cambios"; continue; }
  git -C "$dir" push -q -u origin "$DEFAULT_BRANCH"
  gh api -X PATCH "repos/$ORG/$repo" -f default_branch="$DEFAULT_BRANCH" --silent
  ok "$repo: semilla publicada en $DEFAULT_BRANCH"

  if [[ "$(repo_attr "$repo" rama_integracion)" == "true" ]]; then
    git -C "$dir" push -q origin "$DEFAULT_BRANCH:refs/heads/$INTEGRATION_BRANCH" 2>/dev/null || true
    ok "$repo: rama $INTEGRATION_BRANCH creada"
  fi
done
