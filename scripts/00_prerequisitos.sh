#!/usr/bin/env bash
# Verifica herramientas, autenticación, rol de owner y aplica ajustes base de la organización.
source "$(dirname "$0")/../lib/common.sh"
log "00 · Prerrequisitos y ajustes de la organización '$ORG'"

require gh git jq perl
gh auth status >/dev/null 2>&1 || die "Ejecute: gh auth login"

scopes="$(gh auth status 2>&1 | grep -i 'scopes' || true)"
for s in admin:org repo workflow project; do
  grep -q "'$s'" <<<"$scopes" || warn "Falta scope '$s' → gh auth refresh -h github.com -s admin:org,repo,workflow,project"
done

gh api "orgs/$ORG" --silent || die "La organización '$ORG' no existe o no es accesible. Créela en https://github.com/account/organizations/new"
me="$(gh api user --jq .login)"
role="$(gh api "orgs/$ORG/memberships/$me" --jq .role 2>/dev/null || echo none)"
[[ "$role" == "admin" ]] || die "El usuario '$me' debe ser owner de '$ORG' (rol actual: $role)"
ok "Autenticado como $me (owner de $ORG)"

plan="$(gh api "orgs/$ORG" --jq '.plan.name // "desconocido"' 2>/dev/null || echo desconocido)"
info "Plan de la organización: $plan"
if [[ "$plan" == "free" ]]; then
  warn "Plan Free: los rulesets NO se aplican en repositorios privados."
  warn "Para proteger 'main'/'develop' con QA obligatorio en repos privados se requiere GitHub Team."
fi

gh api -X PATCH "orgs/$ORG" \
  -f default_repository_permission=none \
  -F members_can_create_repositories=false \
  -F members_can_create_public_repositories=false \
  -F members_can_create_private_repositories=false \
  -F web_commit_signoff_required=true \
  --silent && ok "Permiso base 'none', creación de repos solo por owners, sign-off obligatorio en commits web" \
  || warn "No se pudieron aplicar todos los ajustes de organización"

gh variable set ENABLE_QA_GATE --org "$ORG" --visibility all --body "$ENABLE_QA_GATE" \
  && ok "Variable de organización ENABLE_QA_GATE=$ENABLE_QA_GATE" \
  || warn "No se pudo crear la variable ENABLE_QA_GATE"

info "Pasos manuales (sin API pública): exigir 2FA en Settings → Authentication security."
