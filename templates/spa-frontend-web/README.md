# Spa de Uñas Frontend – React + Vite + Tailwind CSS

Este proyecto corresponde al frontend del sistema de inventario de un spa de uñas, desarrollado con React, Vite y Tailwind CSS, con el objetivo de construir una interfaz moderna, rápida y mantenible para la consulta y actualización del inventario de productos, materiales e insumos.

## 🛠️ Tecnologías utilizadas

* React – Librería para construir interfaces de usuario
* Vite – Herramienta de desarrollo y build rápido
* Tailwind CSS – Framework de estilos utility-first
* JavaScript (ES6+)
* PostCSS
* React Router – Navegación entre páginas
* Axios – Cliente HTTP para consumir el API del backend
* Vitest + Testing Library – Pruebas de componentes

## 🚀 Instalación y ejecución

### 1️⃣ Clonar el repositorio

```
git clone https://github.com/__ORG__/__REPO__.git
cd __REPO__
git checkout develop
```

### 2️⃣ Instalar dependencias

```
npm install
```

### 3️⃣ Configurar variables de entorno

```
cp .env.example .env
```

En Windows (PowerShell):

```
Copy-Item .env.example .env
```

Contenido de `.env.example`:

```
VITE_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

⚠️ El archivo `.env` no debe subirse al repositorio (ya está incluido en el `.gitignore`). Solo las variables que empiezan con `VITE_` quedan disponibles en el navegador; nunca coloque secretos en ellas.

### 4️⃣ Ejecutar en modo desarrollo

```
npm run dev
```

La aplicación estará disponible en:

```
http://localhost:5173
```

## 📜 Scripts disponibles

| Comando | Uso |
|---|---|
| `npm run dev` | Servidor de desarrollo con recarga automática |
| `npm run build` | Build de producción en la carpeta `dist` |
| `npm run preview` | Sirve localmente el build de producción |
| `npm run lint` | Revisión de código con ESLint |
| `npm test` | Pruebas en modo observación |
| `npm run test:ci` | Pruebas con cobertura (lo que ejecuta la integración continua) |

## 🎨 Estilos

Los estilos del proyecto se manejan principalmente con Tailwind CSS, utilizando clases utilitarias directamente en los componentes React.

Esto permite:

* Desarrollo rápido
* Menor cantidad de CSS personalizado
* Consistencia visual
* Fácil mantenimiento

Tailwind se integra mediante PostCSS (`postcss.config.js`) y se importa en `src/index.css`. Los colores de los estados del inventario (Disponible, Bajo stock, Agotado, Descontinuado) están centralizados en `src/constants/theme.js`.

## 📁 Organización del proyecto y patrones

El código se organiza por capas y responsabilidades, con patrones que facilitan la reutilización y el mantenimiento.

### Estructura principal

| Carpeta | Uso |
|---|---|
| `src/components/ui` | Componentes base reutilizables (Button, Input, Card, Badge, Container, Spinner, Alert). Presentacionales, configurados por props. |
| `src/components/layout` | Componentes de estructura de página: Header, Footer, MainLayout, PageContainer. |
| `src/constants` | Tema (colores, estados de inventario) y constantes de rutas (ROUTES). Una sola fuente de verdad para diseño y navegación. |
| `src/utils` | Utilidades (p. ej. `cn` para clases CSS condicionales). |
| `src/services/api` | Cliente HTTP (axios) y endpoints para consumir el API del backend (repositorio `spa-backend-api`). |
| `src/services/auth` | Contexto de autenticación (AuthProvider, useAuth) y rutas protegidas por rol (ProtectedRoute). |
| `src/pages` | Páginas/vistas por módulo (auth, inventario, movimientos, historial, alertas, usuarios), que componen layout + componentes UI. |

## 🧪 Pruebas y calidad

Los mismos comandos que ejecuta la integración continua:

```
npm run lint
npm run test:ci
npm run build
```

Las pruebas se ubican junto al archivo que prueban con el sufijo `.test.jsx` o `.test.js`.

## ☁️ Despliegue

El despliegue se realiza en Vercel, conectado a este repositorio:

* `main` → producción.
* Cada Pull Request → Preview Deployment con URL propia.
* Variable requerida en Vercel: `VITE_API_BASE_URL`.

## 🔀 Flujo de trabajo

1. Crear la rama desde `develop`: `git checkout -b feature/HU-03-consultar-inventario`.
2. Hacer commits con Conventional Commits y firma: `git commit -s -m "feat(inventario): tabla de existencias (HU-03)"`.
3. Abrir un Pull Request hacia `develop`.
4. El PR solo se puede fusionar cuando pasan los checks `politica / pr`, `calidad / pipeline`, `seguridad / scan` (y `qa-gate / qa` cuando QA esté activo) y lo aprueba un integrante del equipo responsable.
