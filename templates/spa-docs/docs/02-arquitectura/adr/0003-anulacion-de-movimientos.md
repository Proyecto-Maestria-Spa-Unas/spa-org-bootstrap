# ADR-0003 · Anulación controlada de movimientos en lugar de eliminación física

- **Estado:** Propuesto (depende de DEC-06)
- **Fecha:** 2026-09-27
- **Relacionado:** HU-13 · RF-20 · RN-13 · RNF-06

## Contexto

La especificación recomienda considerar corrección o anulación controlada para preservar trazabilidad.

## Propuesta

No borrar movimientos: registrar un movimiento compensatorio de tipo `ANULACION` que referencia al
original, con motivo obligatorio, usuario y marca de tiempo, restringido al rol autorizado y con confirmación.
El stock se recalcula por el efecto inverso. La historia HU-13 se reformula en esos términos si se aprueba.
