# Guía de contribución

## Ramas

| Rama | Uso | Origen | Destino |
|---|---|---|---|
| `main` | Producción. Protegida. | — | — |
| `develop` | Integración. Protegida. | — | `main` (vía `release/*`) |
| `feature/HU-xx-desc` | Funcionalidad de una historia de usuario | `develop` | `develop` |
| `fix/desc` | Corrección no urgente | `develop` | `develop` |
| `release/x.y.z` | Estabilización de una versión | `develop` | `main` |
| `hotfix/desc` | Corrección urgente en producción | `main` | `main` y luego `develop` |
| `chore/`, `docs/`, `test/`, `refactor/`, `ci/` | Tareas técnicas | `develop` | `develop` |

Las ramas se validan automáticamente con el check `politica / pr`.

## Commits y títulos de PR — Conventional Commits

```
feat(movimientos): registrar salida con validación de stock (HU-07)
fix(auth): rechazar token expirado
docs(adr): 0004 anulación de movimientos
```

Tipos permitidos: `feat fix docs style refactor perf test build ci chore revert`.
Se fusiona **solo con squash**: el título del PR se convierte en el commit de `main`/`develop`.

## Requisitos para fusionar

1. Checks en verde: `politica / pr`, `calidad / pipeline`, `seguridad / scan` y, cuando esté activo, `qa-gate / qa`.
2. Aprobación de un integrante del equipo propietario (CODEOWNERS).
3. Conversaciones resueltas y rama actualizada con la base.
4. Commits firmados con `git commit -s` (DCO).

## Secretos

Nunca se suben `.env`, llaves ni tokens. Use `.env.example` y los secretos de GitHub/AWS/Supabase.
