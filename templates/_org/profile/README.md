# 💅 Spa de Uñas · Sistema de Inventario

Aplicativo para la gestión y control interno del inventario de productos, materiales e insumos de un spa de uñas: autenticación por roles, catálogo de productos, entradas y salidas, historial de movimientos, estados del inventario y alertas de bajo stock.

## 🚀 Tecnologías

* **Frontend:** React, Vite, Tailwind CSS, JavaScript (ES6+), PostCSS · desplegado en Vercel
* **Backend:** FastAPI, Uvicorn, SQLAlchemy, Pydantic Settings, Python-JOSE (JWT), Python-dotenv
* **Base de datos:** PostgreSQL + PostGIS en Supabase
* **Nube:** AWS (ECR, EKS), Kubernetes, Istio, Terraform
* **Calidad y seguridad:** GitHub Actions, Pytest, Playwright, Vitest, Trivy

## 📁 Repositorios

| Repositorio | Equipo responsable | Propósito |
|---|---|---|
| `spa-docs` | equipo-analistas | Requisitos, historias de usuario, trazabilidad y ADR |
| `spa-database` | equipo-datos | Esquema PostgreSQL/PostGIS en Supabase: migraciones, RLS y reglas de stock |
| `spa-backend-api` | equipo-backend | API FastAPI con arquitectura hexagonal |
| `spa-frontend-web` | equipo-frontend | Interfaz React + Vite + Tailwind CSS |
| `spa-qa` | equipo-qa | Pruebas de API, E2E y carga · puerta de calidad antes del merge |
| `spa-devops-workflows` | equipo-devops | Workflows reutilizables de CI/CD y seguridad |
| `spa-infra-aws` | equipo-devops | Terraform, EKS, Kubernetes e Istio |
| `spa-template-servicio` | equipo-devops | Plantilla para nuevos servicios o tecnologías |

## 🔀 Flujo de trabajo

`feature/HU-xx-descripcion` → Pull Request a `develop` (checks automáticos + revisión + QA) → `release/x.y.z` → `main`.

Guía completa en `CONTRIBUTING.md`.
