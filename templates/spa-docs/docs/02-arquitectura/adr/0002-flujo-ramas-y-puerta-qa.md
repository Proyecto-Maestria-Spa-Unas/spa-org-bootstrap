# ADR-0002 · Flujo de ramas y puerta de QA antes del merge

- **Estado:** Aceptado
- **Fecha:** 2026-09-27

## Decisión

`main` (producción) y `develop` (integración) protegidas por rulesets: PR obligatorio, aprobación de
CODEOWNERS, historial lineal (solo squash), sin force-push ni borrado, y checks obligatorios
`politica / pr`, `calidad / pipeline`, `seguridad / scan`. Al activarse `spa-qa`, se agrega `qa-gate / qa`
como check obligatorio en backend y frontend, ejecutando la suite de QA contra el código del PR.

## Consecuencias

Ningún código llega a `develop` o `main` sin pruebas automáticas, escaneo de seguridad y revisión humana.
El equipo `plataforma-admins` puede omitir reglas solo a través de un PR (hotfix de emergencia), quedando auditado.
