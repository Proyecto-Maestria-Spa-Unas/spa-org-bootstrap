#!/usr/bin/env bash
# Tablero GitHub Projects (v2) de la organización, vinculado a los repos y con los issues de spa-docs.
source "$(dirname "$0")/../lib/common.sh"
log "08 · Tablero de proyecto '$PROJECT_TITLE'"

num="$(gh project list --owner "$ORG" --format json --limit 100 \
        --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number" 2>/dev/null || true)"
if [[ -z "$num" ]]; then
  num="$(gh project create --owner "$ORG" --title "$PROJECT_TITLE" --format json --jq .number)" \
    || die "No se pudo crear el proyecto (¿scope 'project'?)"
  ok "Proyecto #$num creado"
  gh project field-create "$num" --owner "$ORG" --name "Área" --data-type SINGLE_SELECT \
    --single-select-options "Backend,Frontend,Database,QA,DevOps,Docs" >/dev/null 2>&1 || true
  gh project field-create "$num" --owner "$ORG" --name "Puntos" --data-type NUMBER >/dev/null 2>&1 || true
else
  info "Proyecto #$num ya existe"
fi

for repo in $(repos); do
  gh project link "$num" --owner "$ORG" --repo "$ORG/$repo" >/dev/null 2>&1 && info "  vinculado $repo" || true
done

en_tablero="$(gh project item-list "$num" --owner "$ORG" --limit 500 --format json --jq '.items[].content.url' 2>/dev/null || true)"
gh issue list -R "$ORG/spa-docs" --state open --limit 500 --json url --jq '.[].url' | while read -r url; do
  grep -Fxq "$url" <<<"$en_tablero" && continue
  gh project item-add "$num" --owner "$ORG" --url "$url" >/dev/null && info "  + $url"
done
ok "Tablero: https://github.com/orgs/$ORG/projects/$num"
