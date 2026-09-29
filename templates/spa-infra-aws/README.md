# Infraestructura Spa de Uñas - AWS + Kubernetes + Istio

Infraestructura como código de la plataforma del sistema de inventario de un spa de uñas. Define los recursos de AWS con Terraform y los manifiestos de Kubernetes e Istio para desplegar el backend con escalabilidad, recuperación automática, despliegues canary y cifrado mTLS entre servicios.

## 🚀 Tecnologías Principales

* Terraform
* AWS (ECR, EKS, VPC, IAM, Secrets Manager, RDS/PostGIS opcional)
* Kubernetes (kubectl)
* Istio (istioctl)
* Docker Desktop (clúster local para pruebas)
* AWS CLI

## ⚙️ Configuración del Entorno

### 1️⃣ Clonar el repositorio

```
git clone https://github.com/__ORG__/__REPO__.git
cd __REPO__
git checkout develop
```

### 2️⃣ Instalar herramientas

#### 🐧 Linux / Mac

```
brew install terraform kubectl awscli istioctl
```

#### 🪟 Windows (PowerShell)

```
winget install Hashicorp.Terraform
winget install Kubernetes.kubectl
winget install Amazon.AWSCLI
```

Para Istio en Windows, descargue `istioctl.exe` desde https://github.com/istio/istio/releases y ubíquelo en una carpeta del PATH (o en `tools\`, como en el laboratorio).

Verificar:

```
terraform version
kubectl version --client
aws --version
istioctl version --remote=false
```

### 3️⃣ Configurar credenciales de AWS (solo para trabajo local)

```
aws configure sso
```

⚠️ En GitHub Actions no se usan llaves de acceso: la autenticación se hace con OIDC (rol IAM asumido por el workflow).

## ▶️ Ejecutar Terraform

Desde la carpeta del entorno:

```
cd terraform/envs/staging
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

`terraform apply` sobre `staging` y `production` se ejecuta desde el pipeline con aprobación del entorno, no desde equipos personales.

## ☸️ Desplegar en Kubernetes (clúster local o EKS)

```
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/base/backend/
kubectl apply -f k8s/istio/
kubectl get pods -n spa-inventario
```

Cada Pod debe mostrar `READY 2/2`: el contenedor de la API y el proxy `istio-proxy`.

### Despliegue canary

Editar los pesos en `k8s/istio/virtual-service-canary.yaml` por etapas (90/10 → 50/50 → 0/100) y aplicar en cada una:

```
kubectl apply -f k8s/istio/virtual-service-canary.yaml
```

Rollback: devolver el 100 % del tráfico a `v1` y volver a aplicar.

## 📦 Componentes Principales

### 🔹 Terraform (`terraform/envs`)
Un directorio por entorno con estado aislado. Actualmente declara el repositorio ECR de la API (imágenes inmutables con escaneo al subir).

### 🔹 Deployments y Service (`k8s/base/backend`)
Versiones `v1` y `v2` de la API, Service `ClusterIP`, HPA por CPU, sondas de salud y contenedores sin privilegios.

### 🔹 DestinationRule (`k8s/istio`)
Define los subconjuntos `v1` y `v2` y expulsa réplicas con errores 5xx consecutivos.

### 🔹 VirtualService
Distribución ponderada del tráfico (canary), reintentos y tiempo máximo de respuesta.

### 🔹 PeerAuthentication
mTLS estricto entre los servicios del namespace, sin modificar el código.

### 🔹 AuthorizationPolicy
Solo el ingress gateway puede invocar la API.

## 🔐 Variables y secretos

* Las variables de Terraform se declaran en `variables.tf`; los valores por entorno van en archivos `*.tfvars` que no se suben al repositorio.
* Las variables de la API (`DB_URL`, `JWT_SECRET`, etc.) viven en AWS Secrets Manager y llegan al clúster como el Secret `backend-api-env`.

⚠️ Nunca suba `*.tfstate`, `*.tfvars` ni `kubeconfig` (ya están incluidos en el `.gitignore`).

## 📁 Organización del proyecto

| Carpeta | Uso |
|---|---|
| `terraform/envs/staging` | Infraestructura del entorno de pruebas. |
| `terraform/envs/production` | Infraestructura de producción (requiere aprobación de plataforma-admins). |
| `terraform/modules` | Módulos propios reutilizables (vpc, eks, rds-postgis, secrets, github-oidc). |
| `k8s/base` | Namespace con inyección de Istio y recursos del backend. |
| `k8s/istio` | Políticas de tráfico y seguridad de la malla de servicios. |
| `docs/ROADMAP_INFRA.md` | Fases de aprovisionamiento en AWS. |

## 🧪 Pruebas y calidad

La integración continua ejecuta:

* `calidad / pipeline`: `terraform fmt -check`, `terraform validate` por entorno y `kubeconform` sobre `k8s/`.
* `seguridad / scan`: Trivy sobre malas configuraciones y secretos.

## 🔀 Flujo de trabajo

1. Crear la rama desde `develop`: `git checkout -b feature/eks-cluster`.
2. Abrir un Pull Request hacia `develop` con la salida de `terraform plan` en la descripción.
3. El PR se fusiona cuando pasan los checks y lo aprueba el equipo de DevOps.
