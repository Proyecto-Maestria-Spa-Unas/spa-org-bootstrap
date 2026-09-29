#!/usr/bin/env bash
# Agrega a la portada (README) de cada repo de trabajo la sección "🌿 Cómo contribuir":
# clonación, nombre de ramas, commits, PR y actualización de la rama. Se publica por PR en cada repo
# (docs/guia-contribucion → develop o main) y se fusiona solo si los checks pasan. Idempotente.
# Uso: ./scripts/10_guia_contribucion.sh [repo ...]   (sin argumentos: los repos del sprint)
source "$(dirname "$0")/../lib/common.sh"

MARCA="## 🌿 Cómo contribuir"
RAMA="docs/guia-contribucion"
declare -A EJ_RAMA=(
  [spa-database]="feature/D2-migracion-catalogo"
  [spa-backend-api]="feature/B1-docker-compose"
  [spa-frontend-web]="feature/F3-design-tokens"
  [spa-qa]="test/Q1-plan-pruebas-catalogo"
  [spa-docs]="docs/F1-investigacion-marca"
)
declare -A EJ_COMMIT=(
  [spa-database]="feat(catalogo): migración de categoria, unidad_medida y producto (D2)"
  [spa-backend-api]="build(docker): entorno local con docker compose (B1)"
  [spa-frontend-web]="feat(marca): design tokens de color y tipografía (F3)"
  [spa-qa]="test(catalogo): plan y casos de prueba del catálogo (Q1)"
  [spa-docs]="docs(marca): investigación de marca y benchmark (F1)"
)

seccion() {   # $1 repo · $2 rama base
  cat <<'MD'

## 🌿 Cómo contribuir

### 1️⃣ Clonar el repositorio (solo la primera vez)

Use **Git Bash** en Windows o la terminal en Linux/Mac:

```
git config --global core.autocrlf input
git clone https://github.com/__ORG__/__REPO__.git
cd __REPO__
git switch __BASE__
```

### 2️⃣ Crear la rama de su tarea

Nunca se trabaja directamente sobre `main` ni `develop`: GitHub rechaza esos push. Cada tarea tiene su rama, creada desde `__BASE__` actualizada:

```
git switch __BASE__
git pull
git switch -c __EJ_RAMA__
```

Formato obligatorio: **`tipo/ID-descripcion-corta`**. El `ID` es el de la tarea del sprint en mayúscula (D1, B2, F3, Q1…) y la descripción va en minúsculas, con guiones y sin espacios ni tildes.

| Tipo | Úselo para |
|---|---|
| `feature/` | Funcionalidad nueva |
| `fix/` | Corrección de un defecto |
| `docs/` | Documentación |
| `test/` | Pruebas |
| `refactor/` | Mejora interna sin cambio funcional |
| `chore/` · `ci/` | Mantenimiento y automatización |

### 3️⃣ Guardar y subir los cambios

```
git add .
git commit -s -m "__EJ_COMMIT__"
git push -u origin __EJ_RAMA__
```

El mensaje sigue **Conventional Commits**: `tipo(alcance): descripción (ID)`. La opción `-s` firma el commit.

### 4️⃣ Abrir el Pull Request

```
gh pr create --base __BASE__ --fill
```

O desde GitHub con el botón **Compare & pull request**. En la descripción escriba `Closes __ORG__/__REPO__#<número de la tarea>`. El PR se fusiona cuando los checks obligatorios están en verde.

### 5️⃣ Mantener su rama al día

Si `__BASE__` avanzó mientras usted trabajaba:

```
git switch __BASE__
git pull
git switch -
git rebase __BASE__
git push --force-with-lease
```

`--force-with-lease` solo se usa sobre **su propia rama**, nunca sobre `main` ni `develop`.

### ❌ Qué no hacer

* No subir archivos `.env`, contraseñas ni llaves: el escaneo de seguridad bloqueará el PR.
* No mezclar varias tareas en una misma rama: una rama, una tarea, un PR.
MD
}

render() {   # $1 repo · $2 base → texto final
  seccion | ORG_V="$ORG" REPO_V="$1" BASE_V="$2" RAMA_V="${EJ_RAMA[$1]}" COMMIT_V="${EJ_COMMIT[$1]}" perl -pe '
    s/__ORG__/$ENV{ORG_V}/g; s/__REPO__/$ENV{REPO_V}/g; s/__BASE__/$ENV{BASE_V}/g;
    s/__EJ_RAMA__/$ENV{RAMA_V}/g; s/__EJ_COMMIT__/$ENV{COMMIT_V}/g'
}

[[ "${1:-}" == "--mostrar" ]] && { render "${2:-spa-database}" "${3:-develop}"; exit 0; }

REPOS=("$@"); ((${#REPOS[@]})) || REPOS=(spa-database spa-backend-api spa-frontend-web spa-qa spa-docs)
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
log "10 · Guía de contribución en la portada de cada repo"

for repo in "${REPOS[@]}"; do
  [[ -n "${EJ_RAMA[$repo]:-}" ]] || { warn "$repo: sin ejemplos definidos, se omite"; continue; }
  base="$DEFAULT_BRANCH"; [[ "$(repo_attr "$repo" rama_integracion)" == "true" ]] && base="$INTEGRATION_BRANCH"
  dir="$WORK/$repo"
  gh repo clone "$ORG/$repo" "$dir" -- --quiet --branch "$base" || { warn "$repo: no se pudo clonar"; continue; }
  if grep -Fq "$MARCA" "$dir/README.md"; then info "$repo: la guía ya existe en $base"; continue; fi

  git -C "$dir" switch -q -c "$RAMA"
  render "$repo" "$base" >> "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -s -m "docs(readme): guía de clonación, ramas y pull requests"
  git -C "$dir" push -q -u origin "$RAMA"
  (cd "$dir" && gh pr create --base "$base" --title "docs(readme): guía de clonación, ramas y pull requests" \
      --body "Agrega a la portada la sección 🌿 Cómo contribuir con ejemplos propios de $repo." >/dev/null)
  info "$repo: PR abierto hacia $base, esperando checks…"
  sleep 20
  if (cd "$dir" && gh pr checks --watch --fail-fast >/dev/null 2>&1) || \
     [[ "$(cd "$dir" && gh pr checks --json name --jq 'length' 2>/dev/null || echo 0)" == "0" ]]; then
    (cd "$dir" && gh pr merge --squash --delete-branch >/dev/null) && ok "$repo: guía publicada en $base" \
      || warn "$repo: PR listo pero no se pudo fusionar; revíselo en GitHub"
  else
    warn "$repo: checks fallidos; el PR queda abierto para revisión"
  fi
done
