# Hoja de ruta de infraestructura AWS

| Fase | Componente | Detalle |
|---|---|---|
| 1 | Estado remoto | S3 (versionado + cifrado) y DynamoDB para bloqueo |
| 1 | GitHub OIDC | Rol IAM asumible solo desde `__ORG__/*` en ramas protegidas; sin llaves estáticas |
| 1 | ECR | Repositorios inmutables con escaneo al subir (ya declarado) |
| 2 | VPC | 2–3 AZ, subredes privadas para EKS/RDS, NAT, endpoints VPC para ECR/S3 |
| 2 | EKS | Node group gestionado, IRSA, add-ons (VPC CNI, CoreDNS, EBS CSI), Cluster Autoscaler |
| 2 | Istio | Instalación por Helm, sidecar, ingress gateway con certificado de ACM, Kiali + Prometheus |
| 3 | Datos | Supabase (principal) o RDS PostgreSQL + PostGIS Multi-AZ con backups PITR (RNF-10) |
| 3 | Secretos | AWS Secrets Manager + External Secrets Operator → `backend-api-env` |
| 4 | Observabilidad | CloudWatch / Container Insights, alertas, retención de logs |

Despliegue de la API: imagen en ECR → manifiestos `k8s/` → canary Istio 90/10 → 50/50 → 0/100 con rollback
cambiando pesos del `VirtualService` (mismo procedimiento del laboratorio de Kubernetes + Istio).
