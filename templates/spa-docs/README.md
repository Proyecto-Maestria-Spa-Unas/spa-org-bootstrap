# Documentación Spa de Uñas - Requisitos, Historias y Arquitectura

Repositorio de documentación del sistema de gestión y control interno del inventario de un spa de uñas. Reúne la especificación de requisitos, las historias de usuario, la matriz de trazabilidad, las decisiones de arquitectura (ADR) y los procesos de trabajo del equipo.

## 🚀 Contenido Principal

* Especificación de requisitos funcionales (RF-01 a RF-20)
* Requisitos no funcionales (RNF-01 a RNF-10)
* Reglas de negocio (RN-01 a RN-14)
* Historias de usuario (HU-01 a HU-13) con criterios de aceptación
* Decisiones de arquitectura (ADR)
* Flujo de trabajo Git y Definición de Terminado

## ⚙️ Cómo trabajar con este repositorio

### 1️⃣ Clonar el repositorio

```
git clone https://github.com/__ORG__/__REPO__.git
cd __REPO__
```

### 2️⃣ Editar

La documentación se escribe en Markdown. Los diagramas se escriben con Mermaid dentro de los mismos archivos y GitHub los muestra directamente.

### 3️⃣ Proponer cambios

```
git checkout -b docs/descripcion-del-cambio
git commit -s -m "docs(requisitos): actualizar criterios de HU-07"
git push -u origin docs/descripcion-del-cambio
```

Luego abra un Pull Request hacia `main`. Lo aprueba el equipo de analistas.

## 📋 Historias de usuario y decisiones pendientes

Las historias de usuario no se editan como archivos: viven como **issues** de este repositorio con la etiqueta `historia-usuario`, organizadas en los milestones M0 a M5 y en el tablero del proyecto de la organización.

Las decisiones pendientes de la especificación (rol Gerente, permisos de la Manicurista, alertas obligatorias, filtro por fechas, eliminación de movimientos, métricas de rendimiento, políticas de contraseñas, respaldo y catálogo definitivo) están como issues con la etiqueta `decision-pendiente` (DEC-01 a DEC-10). Al resolver una, se registra su ADR y se cierra el issue.

## 📁 Organización del proyecto

| Carpeta | Uso |
|---|---|
| `docs/01-requisitos` | Especificación oficial y matriz de trazabilidad HU ↔ RF/RNF/RN ↔ repositorios. |
| `docs/02-arquitectura/adr` | Registros de decisiones de arquitectura (usar `0000-plantilla.md`). |
| `docs/03-procesos` | Flujo de trabajo Git, releases y Definición de Terminado. |

## 🏛️ Decisiones registradas

| ADR | Estado | Tema |
|---|---|---|
| 0001 | Aceptado | Organización GitHub con un repositorio por componente |
| 0002 | Aceptado | Flujo de ramas y puerta de QA antes del merge |
| 0003 | Propuesto | Anulación controlada de movimientos en lugar de eliminación |
