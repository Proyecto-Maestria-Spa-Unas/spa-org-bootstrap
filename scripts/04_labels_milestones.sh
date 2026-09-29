#!/usr/bin/env bash
# Etiquetas homogéneas en todos los repos y milestones (M0..M5) en los repos de producto.
source "$(dirname "$0")/../lib/common.sh"
log "04 · Etiquetas y milestones"

for repo in $(repos); do
  jq -r '.[] | [.name, .color, .description] | @tsv' "$CONFIG_DIR/labels.json" |
    while IFS=$'\t' read -r n c d; do
      gh label create "$n" -R "$ORG/$repo" --color "$c" --description "$d" --force >/dev/null
    done
  ok "$repo: $(jq length "$CONFIG_DIR/labels.json") etiquetas"

  [[ "$(repo_attr "$repo" milestones)" == "true" ]] || continue
  existentes="$(gh api "repos/$ORG/$repo/milestones?state=all&per_page=100" --jq '.[].title')"
  jq -r '.[] | [.title, .description] | @tsv' "$CONFIG_DIR/milestones.json" |
    while IFS=$'\t' read -r t d; do
      grep -Fxq "$t" <<<"$existentes" && continue
      gh api -X POST "repos/$ORG/$repo/milestones" -f title="$t" -f description="$d" --silent
      info "  milestone '$t'"
    done
done
