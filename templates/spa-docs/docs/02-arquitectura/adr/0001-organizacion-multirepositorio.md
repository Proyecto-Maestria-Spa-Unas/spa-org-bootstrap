# ADR-0001 · Organización GitHub con múltiples repositorios por componente

- **Estado:** Aceptado
- **Fecha:** 2026-09-27

## Contexto

El sistema combina tecnologías con ciclos de vida distintos (PostgreSQL/Supabase, FastAPI, React/Vite,
Terraform/Kubernetes/Istio) y crecerá incorporando nuevos servicios o tecnologías por cada CRUD o capacidad.
Se requiere asignar integrantes por componente y una puerta de QA previa al merge.

## Decisión

Organización GitHub con un repositorio por componente desplegable (`spa-database`, `spa-backend-api`,
`spa-frontend-web`, `spa-infra-aws`), uno de QA (`spa-qa`), uno de workflows reutilizables
(`spa-devops-workflows`), uno de documentación (`spa-docs`) y un repositorio plantilla
(`spa-template-servicio`) para nuevos servicios. Permisos por equipos, reglas por rulesets.

## Consecuencias

- Permisos y CODEOWNERS granulares por componente; despliegues independientes.
- Un cambio funcional puede requerir PRs coordinados en varios repos: se enlazan a la misma HU.
- El esquema de BD tiene un único dueño (`spa-database`); la API no ejecuta DDL.
- Nuevas tecnologías se incorporan creando un repo desde la plantilla, sin alterar los existentes.
