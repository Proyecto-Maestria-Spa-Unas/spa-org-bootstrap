# Plantilla de Servicio Spa de Uñas - FastAPI

Plantilla para incorporar un nuevo servicio o una nueva tecnología a la plataforma sin alterar los repositorios existentes (por ejemplo: analítica con DuckDB, procesamiento geoespacial con PostGIS/GeoPandas, notificaciones o reportes). Incluye la misma arquitectura hexagonal, configuración, pruebas, Docker y pipeline de calidad del backend principal.

## 🚀 Tecnologías Principales

* FastAPI
* Uvicorn
* SQLAlchemy
* Pydantic Settings
* Python-JOSE (JWT)
* Python-dotenv

## 🧩 Crear un servicio a partir de esta plantilla

1. Registrar el nuevo repositorio en `config/repos.json` y `config/permisos.json` del paquete de bootstrap de la organización.
2. Crear el repositorio desde la plantilla:

```
gh repo create __ORG__/spa-svc-<dominio> --private --template __ORG__/spa-template-servicio
```

3. Aplicar el gobierno de la organización (ajustes, permisos, etiquetas y reglas):

```
./bootstrap.sh 02 03 04 06
```

4. Actualizar este README con el nombre y propósito del nuevo servicio.

Convención de nombres: `spa-svc-<dominio>` para servicios y `spa-lib-<nombre>` para librerías compartidas.

## ⚙️ Configuración del Entorno

### 1️⃣ Crear entorno virtual (venv)

#### 🐧 Linux / Mac

```
python3 -m venv venv
source venv/bin/activate
```

#### 🪟 Windows (PowerShell)

```
python -m venv venv
venv\Scripts\Activate.ps1
```

Si da error de políticas:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 🪟 Windows (CMD)

```
python -m venv venv
venv\Scripts\activate.bat
```

### 2️⃣ Instalar dependencias

Con el entorno virtual activado:

```
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

✅ El comando es el mismo en todos los sistemas si el entorno está activado correctamente.

## ▶️ Ejecutar el servicio

Desde la raíz del proyecto:

```
python -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

Acceder a:

* 📄 Documentación Swagger: http://127.0.0.1:8000/docs
* 📘 Documentación Redoc: http://127.0.0.1:8000/redoc
* 💚 Estado del servicio: http://127.0.0.1:8000/api/v1/health

## 🔐 Variables de Entorno

1. Crear un archivo `.env` en la raíz del proyecto.
2. Copiar el contenido de `.env.example`.
3. Ajustar los valores según tu entorno.

⚠️ El archivo `.env` no debe subirse al repositorio (ya está incluido en el `.gitignore`).

## 📁 Organización del proyecto y patrones

| Carpeta | Uso |
|---|---|
| `app/domain` | Entidades y reglas de negocio puras. |
| `app/application` | Casos de uso y puertos (interfaces). |
| `app/infrastructure` | Adaptadores: base de datos, seguridad, servicios externos. |
| `app/api/v1` | Routers de FastAPI y esquemas Pydantic. |
| `app/core` | Configuración y dependencias compartidas. |
| `tests` | Pruebas automatizadas. |

Detalle en `docs/ARQUITECTURA.md`.

## 🧪 Pruebas y calidad

```
ruff check .
ruff format --check .
mypy app
pytest --cov=app --cov-fail-under=80
```
