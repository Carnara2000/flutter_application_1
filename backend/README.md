# Backend MVC

API Node.js/Express que usa MongoDB. Estructura:

- `models/`: consultas y persistencia de productos y usuarios.
- `controllers/`: validación de solicitudes, reglas de negocio y respuestas HTTP.
- `routes/`: asociación de endpoints con controladores.
- `config/database.js`: conexión MongoDB.
- `app.js`: middleware y montaje de rutas.
- `server.js`: configuración y ciclo de vida del servidor.

## Requisitos e inicio

- Node.js 20.19.0 o posterior.
- Una instancia accesible de MongoDB.

Desde esta carpeta:

```powershell
npm install
if (!(Test-Path .env)) { Copy-Item .env.example .env }
```

Edita `.env` con una URI válida en `MONGO_URI` y un secreto privado en
`JWT_SECRET`, después inicia el backend:

```powershell
npm start
```

Por defecto conecta a la base `appLogin` y usa las colecciones `Productos` y
`Usuarios`. El puerto predeterminado es `3000` y se puede cambiar con `PORT`.
Escucha en todas las interfaces para permitir conexiones desde Flutter en otro
dispositivo. Autoriza el puerto en el firewall solo en la red que corresponda.

Comprueba que el proceso está activo en `http://localhost:3000/api/health`.
El backend requiere conexión a MongoDB antes de iniciar la escucha.

## API

| Método | Ruta | Uso |
|---|---|---|
| GET | `/api/health` | Estado del servidor |
| GET | `/api/productos` | Listar productos |
| POST | `/api/productos` | Crear producto |
| PUT | `/api/productos/:id` | Actualizar producto por ObjectId |
| DELETE | `/api/productos/:id` | Eliminar producto por ObjectId |
| GET | `/api/usuarios` | Listar usuarios sin contraseñas |
| POST | `/api/usuarios` | Iniciar sesión o crear cuenta |

El POST de usuarios conserva el contrato de la aplicación: `username` y
`password` inician sesión; al incluir `email` también se requiere `username` y
`password` y se registra una cuenta. Los documentos de usuarios existentes
deben conservar el campo numérico `id` esperado por Flutter.

El archivo `data/productos.json` contiene datos para importar en MongoDB
Compass. No se incluye una copia del archivo de usuarios original porque
contenía emails y contraseñas; el registro de la API crea usuarios nuevos.

El endpoint de productos conserva el formato que espera Flutter. La
autorización del rol administrador sigue siendo una regla del cliente; la API
no verifica JWT para operaciones CRUD de productos.

## Pruebas

```powershell
npm test
```
