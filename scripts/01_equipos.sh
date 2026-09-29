#!/usr/bin/env bash
# Crea los equipos y agrega sus integrantes (config/teams.json, config/miembros.json).
source "$(dirname "$0")/../lib/common.sh"
log "01 · Equipos"

jq -c '.[]' "$CONFIG_DIR/teams.json" | while read -r t; do
  slug="$(jq -r .slug <<<"$t")"; desc="$(jq -r .description <<<"$t")"
  if team_exists "$slug"; then
    info "Equipo $slug ya existe"
  else
    gh api -X POST "orgs/$ORG/teams" -f name="$slug" -f description="$desc" -f privacy=closed --silent
    ok "Equipo $slug creado"
  fi
done

log "01 · Integrantes de equipos"
jq -r '.equipos | to_entries[] | .key as $t | .value[] | [$t, .usuario, (.rol // "member")] | @tsv' \
  "$CONFIG_DIR/miembros.json" | while IFS=$'\t' read -r team user rol; do
  [[ "$user" == LOGIN_* ]] && { warn "Omitiendo marcador '$user' en $team (edite config/miembros.json)"; continue; }
  if gh api -X PUT "orgs/$ORG/teams/$team/memberships/$user" -f role="$rol" --silent; then
    ok "$user → $team ($rol)  [si no es miembro, recibirá invitación]"
  else
    warn "No se pudo agregar $user a $team"
  fi
done
