# Workflows Spa de Uñas - GitHub Actions reutilizables

Repositorio central de la integración continua y la seguridad de la organización. Todos los repositorios consumen estos workflows, de modo que una mejora de CI se aplica a todo el proyecto desde un único lugar.

## 🚀 Tecnologías Principales

* GitHub Actions (workflows reutilizables con `workflow_call`)
* Trivy (vulnerabilidades, secretos y malas configuraciones)
* ruff, mypy, pytest, pip-audit (Python)
* ESLint, Vitest, npm audit (Node)
* PostgreSQL + PostGIS (pruebas de base de datos)
* Terraform y kubeconform (infraestructura)

## ⚙️ Cómo consumir un workflow

En el repositorio consumidor, archivo `.github/workflows/ci.yml`:

```yaml
jobs:
  calidad:
    uses: __ORG__/spa-devops-workflows/.github/workflows/python-ci.yml@main
    with:
      python-version: "3.12"
      coverage-min: 80
```

## 📦 Workflows disponibles

| Workflow | Check en el repo consumidor | Qué hace |
|---|---|---|
| `pr-policy.yml` | `politica / pr` | Valida el nombre de la rama según el flujo y el título en Conventional Commits |
| `python-ci.yml` | `calidad / pipeline` | ruff, formato, mypy, pytest con cobertura mínima y pip-audit (con PostGIS de servicio) |
| `node-ci.yml` | `calidad / pipeline` | npm ci, ESLint, Vitest con cobertura, build de Vite y npm audit |
| `db-ci.yml` | `calidad / pipeline` | Migraciones sobre PostGIS limpio, seeds, pruebas SQL e idempotencia |
| `iac-ci.yml` | `calidad / pipeline` | terraform fmt/validate por entorno y kubeconform |
| `security.yml` | `seguridad / scan` | Trivy: vulnerabilidades, secretos y malas configuraciones |
| `qa-gate.yml` | `qa-gate / qa` | Levanta la API o el frontend del PR y ejecuta la suite de `spa-qa` |

⚠️ Los nombres de los checks (`job-llamador / job-reutilizable`) son los que exigen las reglas de protección de ramas. No renombre jobs sin actualizar la configuración de la organización.

## 🔐 Variables y secretos de organización

| Nombre | Tipo | Uso |
|---|---|---|
| `ENABLE_QA_GATE` | Variable | `true` activa la puerta de QA en los PR de backend y frontend |
| `QA_READ_TOKEN` | Secreto | Token fine-grained con permiso de lectura sobre `spa-qa` |

## 🚦 Activar la puerta de QA

1. Crear un token fine-grained con permiso *Contents: Read* sobre `spa-qa` y guardarlo como secreto de organización `QA_READ_TOKEN`.
2. Poner `ENABLE_QA_GATE="true"` en `config/org.env` del paquete de bootstrap y ejecutar `./bootstrap.sh 06`.

## 📁 Organización del proyecto

| Carpeta | Uso |
|---|---|
| `.github/workflows` | Workflows reutilizables consumidos por toda la organización. |
| `.github/dependabot.yml` | Actualización semanal de las acciones usadas. |

## 🔢 Versionado

Mientras el proyecto está en fundación se consume `@main`. Cuando se estabilicen, los cambios que alteren contratos (inputs o nombres de jobs) se publican con tag `vX` y los consumidores fijan esa versión.

## 🔀 Flujo de trabajo

Rama desde `main` → Pull Request → aprobación del equipo de DevOps (y de QA si se modifica `qa-gate.yml`) → squash merge.
