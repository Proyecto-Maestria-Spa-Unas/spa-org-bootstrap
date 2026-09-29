#!/usr/bin/env bash
# Asigna permisos equipo↔repositorio (config/permisos.json) y colaboradores externos.
source "$(dirname "$0")/../lib/common.sh"
log "03 · Permisos por repositorio"

jq -r 'to_entries[] | .key as $r | .value | to_entries[] | [$r, .key, .value] | @tsv' \
  "$CONFIG_DIR/permisos.json" | while IFS=$'\t' read -r repo team perm; do
  if gh api -X PUT "orgs/$ORG/teams/$team/repos/$ORG/$repo" -f permission="$perm" --silent; then
    ok "$team → $repo : $perm"
  else
    warn "Falló $team → $repo ($perm)"
  fi
done

log "03 · Colaboradores externos"
jq -r '.colaboradores_externos | to_entries[] | .key as $r | .value[] | [$r, .usuario, (.permiso // "push")] | @tsv' \
  "$CONFIG_DIR/miembros.json" | while IFS=$'\t' read -r repo user perm; do
  gh api -X PUT "repos/$ORG/$repo/collaborators/$user" -f permission="$perm" --silent \
    && ok "$user → $repo : $perm (invitación enviada)" || warn "Falló $user → $repo"
done
