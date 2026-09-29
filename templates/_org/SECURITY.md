# Política de seguridad

Reporte vulnerabilidades de forma privada mediante **Security → Report a vulnerability** del repositorio afectado
o escribiendo al equipo `@__ORG__/plataforma-admins`. No abra issues públicos con detalles explotables.

Controles activos: revisión obligatoria por CODEOWNERS, escaneo de dependencias y secretos (Trivy) en cada PR,
alertas de Dependabot, principio de mínimo privilegio en permisos por equipo y autenticación OIDC GitHub→AWS
(sin llaves de larga duración).
