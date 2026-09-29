#!/usr/bin/env bash
# Orquestador. Uso:
#   ./bootstrap.sh            → ejecuta todos los pasos 00..08 (idempotente)
#   ./bootstrap.sh 03 06      → ejecuta solo los pasos indicados
set -Eeuo pipefail
cd "$(dirname "$0")"
PASOS=("$@"); ((${#PASOS[@]})) || PASOS=(00 01 02 03 04 05 06 07 08)
for p in "${PASOS[@]}"; do
  script="$(ls scripts/"${p}"_*.sh 2>/dev/null | head -n1)"
  [[ -n "$script" ]] || { echo "Paso $p no existe"; exit 1; }
  bash "$script"
done
printf '\n\033[1;32mOrganización lista.\033[0m\n'
