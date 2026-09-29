#!/usr/bin/env bash
# Crea un sprint a partir de config/sprint-NN.json (idempotente):
#   · milestone del sprint en cada repo participante
#   · un issue por tarea (labels, milestone, responsable), omitiendo los que ya existen por título
#   · cada issue en el tablero de la organización con sus campos Área y Puntos
#   · decisiones nuevas como issues decision-pendiente en spa-docs (M0)
# Uso: ./scripts/09_sprint.sh config/sprint-01.json
source "$(dirname "$0")/../lib/common.sh"

SPRINT_FILE="${1:-}"
[[ -f "$SPRINT_FILE" ]] || die "Uso: $0 config/sprint-NN.json"
jq empty "$SPRINT_FILE" || die "JSON inválido: $SPRINT_FILE"

MS="$(jq -r .milestone "$SPRINT_FILE")"
MS_DESC="$(jq -r .descripcion "$SPRINT_FILE")"
log "09 · Sprint '$MS'"

# ── Milestone en cada repo participante
for repo in $(jq -r '.repos[]' "$SPRINT_FILE"); do
  if gh api "repos/$ORG/$repo/milestones?state=all&per_page=100" --jq '.[].title' | grep -Fxq "$MS"; then
    info "$repo: milestone ya existe"
  else
    gh api -X POST "repos/$ORG/$repo/milestones" -f title="$MS" -f description="$MS_DESC" --silent && ok "$repo: milestone creado"
  fi
done

# ── Tablero y campos
PNUM="$(gh project list --owner "$ORG" --format json --limit 100 --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number")"
[[ -n "$PNUM" ]] || die "No existe el tablero '$PROJECT_TITLE' (ejecute el paso 08)"
PID="$(gh project view "$PNUM" --owner "$ORG" --format json --jq .id)"
CAMPOS="$(gh project field-list "$PNUM" --owner "$ORG" --format json --limit 50)"
AREA_FID="$(jq -r '.fields[] | select(.name=="Área") | .id' <<<"$CAMPOS")"
PUNTOS_FID="$(jq -r '.fields[] | select(.name=="Puntos") | .id' <<<"$CAMPOS")"

al_tablero() {   # $1 url · $2 área · $3 puntos
  local item opt
  item="$(gh project item-add "$PNUM" --owner "$ORG" --url "$1" --format json --jq .id)" || { warn "  no se pudo agregar al tablero"; return 0; }
  opt="$(jq -r --arg a "$2" '.fields[] | select(.name=="Área") | .options[] | select(.name==$a) | .id' <<<"$CAMPOS")"
  [[ -n "$AREA_FID" && -n "$opt" ]] && gh project item-edit --id "$item" --project-id "$PID" --field-id "$AREA_FID" --single-select-option-id "$opt" >/dev/null
  [[ -n "$PUNTOS_FID" ]] && gh project item-edit --id "$item" --project-id "$PID" --field-id "$PUNTOS_FID" --number "$3" >/dev/null
  info "  tablero: Área=$2 · Puntos=$3"
}

# ── Issues del sprint
jq -c '.issues[]' "$SPRINT_FILE" | while read -r t; do
  repo="$(jq -r .repo <<<"$t")"; titulo="$(jq -r .titulo <<<"$t")"
  if gh issue list -R "$ORG/$repo" --state all --limit 500 --json title --jq '.[].title' | grep -Fxq "$titulo"; then
    info "Existe: $titulo"; continue
  fi
  cuerpo="$(jq -r --arg ms "$MS" '
    "## Tarea del sprint\n\n**\($ms)** · Área: \(.area) · Estimación: \(.puntos) puntos\n\n" +
    "## Criterios de aceptación\n\n" + ([.criterios[] | "- [ ] " + .] | join("\n")) + "\n\n" +
    "## Definición de terminado\n\n- [ ] PR a develop (o main en repos sin develop) con checks en verde\n" +
    "- [ ] Título del PR en Conventional Commits con la referencia \(.id)\n- [ ] Documentación actualizada\n- [ ] Demostrado en la revisión del sprint\n"' <<<"$t")"
  labels="$(jq -r '.labels | join(",")' <<<"$t")"
  asignado="$(jq -r .asignado <<<"$t")"
  url="$(gh issue create -R "$ORG/$repo" --title "$titulo" --body "$cuerpo" --label "$labels" --milestone "$MS" --assignee "$asignado" 2>/dev/null)" \
    || { url="$(gh issue create -R "$ORG/$repo" --title "$titulo" --body "$cuerpo" --label "$labels" --milestone "$MS")"
         warn "  $asignado aún no puede ser asignado (¿invitación pendiente?): asígnelo cuando acepte"; }
  ok "$titulo → $asignado"
  al_tablero "$url" "$(jq -r .area <<<"$t")" "$(jq -r .puntos <<<"$t")"
done

# ── Decisiones nuevas
jq -c '.decisiones_nuevas[]?' "$SPRINT_FILE" | while read -r d; do
  titulo="$(jq -r .titulo <<<"$d")"
  if gh issue list -R "$ORG/spa-docs" --state all --limit 500 --json title --jq '.[].title' | grep -Fxq "$titulo"; then
    info "Existe: $titulo"; continue
  fi
  cuerpo="$(jq -r '"## Decisión pendiente\n\n\(.cuerpo)\n\n**Impacta:** " + (.impacta | join(" · ")) + "\n\n## Decisión\n\n_Pendiente_"' <<<"$d")"
  url="$(gh issue create -R "$ORG/spa-docs" --title "$titulo" --body "$cuerpo" --label "decision-pendiente,area/docs" --milestone "M0 · Fundación")"
  ok "$titulo"
  al_tablero "$url" "Docs" 0
done
