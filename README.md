# App Login Mongo

Aplicación Flutter conectada a una API Node.js/Express con MongoDB. El backend
está integrado en [`backend/`](backend/README.md) y organizado con MVC:
modelos, controladores y rutas separados.

## Iniciar el backend

1. Entra a `backend/` e instala dependencias con `npm install`.
2. Si todavía no existe `.env`, copia `.env.example` con
   `Copy-Item .env.example .env`; configura `MONGO_URI` y `JWT_SECRET`. No
   compartas ni subas `.env`.
3. Ejecuta `npm start`. El servidor escucha en `0.0.0.0:3000`, necesario para
   aceptar conexiones desde otros dispositivos de la red.
4. Verifica `http://localhost:3000/api/health`.

## Conectar Flutter

El valor predeterminado de la API se conserva como
`http://172.20.10.2:3000/api`. Si la dirección del equipo es distinta, inicia
Flutter con el valor correcto para tu entorno:

```powershell
flutter run --dart-define=API_BASE_URL=http://<IP_DEL_EQUIPO>:3000/api
```

Para el emulador Android, usa normalmente `http://10.0.2.2:3000/api`; para
Flutter Web en la misma computadora, usa `http://localhost:3000/api`.

## Carrito local (US09 y US10)

El carrito solo se muestra a usuarios Cliente. Sus artículos se guardan en
SharedPreferences en el dispositivo, separados por ID de usuario; no se envían
operaciones del carrito a la API. Al cerrar sesión se limpia el carrito activo.
La funcionalidad está organizada en `lib/models/cart_item.dart`,
`lib/services/cart_repository.dart`, `lib/controllers/cart_controller.dart` y
`lib/views/cart_view.dart`. El botón de pago permanece como punto de entrada
visual; la simulación de pago no forma parte de estas historias.

Las instrucciones de configuración de MongoDB y los endpoints están en
[`backend/README.md`](backend/README.md). La arquitectura y los flujos se
describen en [`MANUAL_TECNICO.md`](MANUAL_TECNICO.md).
