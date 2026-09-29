#!/usr/bin/env bash
# Crea las 13 historias de usuario y las 10 decisiones pendientes como issues en spa-docs.
source "$(dirname "$0")/../lib/common.sh"
log "07 · Historias de usuario y decisiones pendientes (issues en spa-docs)"

DOCS="$ORG/spa-docs"
existentes="$(gh issue list -R "$DOCS" --state all --limit 500 --json title --jq '.[].title')"

jq -c '.[]' "$CONFIG_DIR/historias.json" | while read -r hu; do
  title="$(jq -r '"\(.id) · \(.titulo)"' <<<"$hu")"
  grep -Fxq "$title" <<<"$existentes" && { info "Existe: $title"; continue; }

  body="$(jq -r --arg org "$ORG" '
    "## Historia de usuario\n\n**Como** \(.como), **requiero** \(.quiero) **para** \(.para).\n\n" +
    "## Criterios de aceptación\n\n" + ([.criterios[] | "- [ ] " + .] | join("\n")) + "\n\n" +
    "## Trazabilidad\n\n" + (.trazabilidad | join(" · ")) + "\n\n" +
    "## Repositorios impactados\n\n" + ([.repos[] | "- [ ] `\($org)/\(.)`"] | join("\n")) + "\n\n" +
    "## Definición de terminado\n\n" +
    "- [ ] Código fusionado en `develop` en todos los repositorios impactados\n" +
    "- [ ] Pruebas automatizadas en `spa-qa` marcadas con `@pytest.mark.hu(\"\(.id)\")`\n" +
    "- [ ] Criterios de aceptación verificados por QA\n" +
    "- [ ] Documentación / ADR actualizada si hubo decisiones\n"' <<<"$hu")"

  labels="$(jq -r '(["historia-usuario"] + .labels) | join(",")' <<<"$hu")"
  ms="$(jq -r .milestone <<<"$hu")"
  gh issue create -R "$DOCS" --title "$title" --body "$body" --label "$labels" --milestone "$ms" >/dev/null
  ok "$title"
done

jq -c '.[]' "$CONFIG_DIR/decisiones.json" | while read -r d; do
  title="$(jq -r .titulo <<<"$d")"
  grep -Fxq "$title" <<<"$existentes" && { info "Existe: $title"; continue; }
  body="$(jq -r '"## Decisión pendiente (sección 11 de la especificación)\n\n**Impacta:** " + (.impacta | join(" · ")) +
    "\n\n## Opciones evaluadas\n\n- \n\n## Decisión\n\n_Pendiente_\n\n## Consecuencias\n\n- \n\n> Al decidir: registrar ADR en `docs/02-arquitectura/adr/` y cerrar este issue enlazándolo."' <<<"$d")"
  gh issue create -R "$DOCS" --title "$title" --body "$body" \
    --label "decision-pendiente,area/docs" --milestone "M0 · Fundación" >/dev/null
  ok "$title"
done
