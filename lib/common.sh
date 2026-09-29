#!/usr/bin/env bash
# Utilidades compartidas por todos los scripts de aprovisionamiento.
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$ROOT_DIR/config"
TEMPLATES_DIR="$ROOT_DIR/templates"
# shellcheck source=../config/org.env
source "$CONFIG_DIR/org.env"

log()  { printf '\n\033[1;34m[%s] %s\033[0m\n' "$(date +%H:%M:%S)" "$*"; }
ok()   { printf '  \033[1;32m✔\033[0m %s\n' "$*"; }
info() { printf '  · %s\n' "$*"; }
warn() { printf '  \033[1;33m⚠\033[0m %s\n' "$*" >&2; }
die()  { printf '  \033[1;31m✖\033[0m %s\n' "$*" >&2; exit 1; }

# Windows (Git Bash): jq.exe escribe finales de línea CRLF; se eliminan los \r para no contaminar variables.
jq() { command jq "$@" | tr -d '\r'; }

require() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || die "Falta '$c' en el PATH"; done; }

repo_exists() { gh api "repos/$ORG/$1" --silent >/dev/null 2>&1; }
team_exists() { gh api "orgs/$ORG/teams/$1" --silent >/dev/null 2>&1; }
team_id()     { gh api "orgs/$ORG/teams/$1" --jq '.id'; }

repos()                 { jq -r '.[].name' "$CONFIG_DIR/repos.json"; }
repo_json()             { jq -c --arg n "$1" '.[] | select(.name==$n)' "$CONFIG_DIR/repos.json"; }
repo_attr()             { repo_json "$1" | jq -r --arg k "$2" '.[$k] // empty'; }
repo_list_attr()        { repo_json "$1" | jq -r --arg k "$2" '.[$k] // [] | .[]'; }

# Reemplaza marcadores en todos los archivos de texto de un directorio.
render_placeholders() {
  local dir="$1" repo="$2"
  find "$dir" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -print0 |
    while IFS= read -r -d '' f; do
      if grep -Iq . "$f" 2>/dev/null; then
        ORG_V="$ORG" REPO_V="$repo" perl -pi -e 's/__ORG__/$ENV{ORG_V}/g; s/__REPO__/$ENV{REPO_V}/g' "$f"
      fi
    done
}
