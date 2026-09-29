# Matriz de trazabilidad HU ↔ requisitos ↔ repositorios

| HU | Nombre | RF / RNF / RN | Milestone | DB | API | Web | QA |
|---|---|---|---|:-:|:-:|:-:|:-:|
| HU-01 | Autenticación | RF-01 · RNF-01 · RNF-07 | M1 | ● | ● | ● | ● |
| HU-02 | Registrar producto | RF-02 · RF-16 · RN-01 · RN-02 | M2 | ● | ● | ● | ● |
| HU-03 | Consultar inventario | RF-03 · RF-11 · RF-19 · RNF-08 | M2 | ● | ● | ● | ● |
| HU-04 | Filtrar por categoría | RF-12 | M2 |  | ● | ● | ● |
| HU-05 | Actualizar producto | RF-04 · RN-02 | M2 |  | ● | ● | ● |
| HU-06 | Registrar entrada | RF-06 · RF-09 · RF-10 · RN-03 · RN-04 · RN-07 · RNF-06 | M3 | ● | ● | ● | ● |
| HU-07 | Registrar salida | RF-07 · RF-08 · RF-09 · RF-10 · RN-03..RN-07 · RNF-02 | M3 | ● | ● | ● | ● |
| HU-08 | Consultar historial | RF-14 · RF-15 · RNF-06 | M3 | ● | ● | ● | ● |
| HU-09 | Gestionar usuarios | RF-01 · RF-13 · RNF-07 · RNF-09 | M1 | ● | ● | ● | ● |
| HU-10 | Alertas de bajo stock | RF-16 · RF-17 · RF-18 · RN-09 · RN-14 | M4 | ● | ● | ● | ● |
| HU-11 | Productos agotados | RF-08 · RF-19 · RN-05 · RN-10 | M3 | ● | ● | ● | ● |
| HU-12 | Descontinuar producto | RF-05 · RN-11 · RN-12 | M2 | ● | ● | ● | ● |
| HU-13 | Eliminar movimiento | RF-20 · RN-13 · RNF-06 | M4 | ● | ● | ● | ● |

RNF transversales: RNF-03 (usabilidad, Web), RNF-04/05 (rendimiento/disponibilidad, DEC-07),
RNF-10 (respaldo, DEC-09, `spa-infra-aws` + Supabase PITR).
