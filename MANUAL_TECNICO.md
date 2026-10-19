# Manual técnico de la aplicación

## Alcance y cómo leer este documento

Este manual describe la aplicación Flutter y el backend Node.js/Express conectado a MongoDB. Las rutas Flutter son relativas a la raíz de este proyecto; el backend MVC está integrado en [`backend/`](backend/README.md).

La app Flutter usa como raíz HTTP predeterminada `http://172.20.10.2:3000/api`, declarada como `baseUrl` en [product_service.dart](lib/services/product_service.dart#L7). Se puede cambiar al ejecutar Flutter mediante `--dart-define=API_BASE_URL=...`.

### Mapa de responsabilidades

| Responsabilidad | Archivo principal |
|---|---|
| Arranque, proveedores y rutas | [main.dart](lib/main.dart#L13) |
| Formulario de acceso y navegación al registro | [login_view.dart](lib/views/login_view.dart#L17) |
| Formulario de registro | [register_view.dart](lib/views/register_view.dart#L14) |
| Estado de autenticación | [auth_controller.dart](lib/controllers/auth_controller.dart#L7) |
| HTTP de autenticación, JWT y persistencia | [auth_service.dart](lib/services/auth_service.dart#L32) |
| Catálogo, detalle, filtros y operaciones de productos | [product_controller.dart](lib/controllers/product_controller.dart#L12) |
| HTTP de productos | [product_service.dart](lib/services/product_service.dart#L34) |
| Pantalla principal y catálogo | [home_view.dart](lib/views/home_view.dart#L13) |
| Detalle, edición y eliminación | [product_detail_view.dart](lib/views/product_detail_view.dart#L10) |
| Formulario de alta | [product_form_view.dart](lib/views/product_form_view.dart#L11) |
| Conversión JSON de producto | [product_model.dart](lib/models/product_model.dart#L1) |
| Conversión de ID numérico a rol | [user_model.dart](lib/models/user_model.dart#L1) |
| Etiquetas de rol | [user_role.dart](lib/models/enums/user_role.dart#L1) |
| Rutas de productos y usuarios | [product_routes.js](backend/routes/product_routes.js) y [user_routes.js](backend/routes/user_routes.js) |
| Controladores MVC | [product_controller.js](backend/controllers/product_controller.js) y [user_controller.js](backend/controllers/user_controller.js) |
| Modelos y conexión MongoDB | [product_model.js](backend/models/product_model.js), [user_model.js](backend/models/user_model.js) y [database.js](backend/config/database.js) |

### Contrato general Flutter ↔ API

- El cliente Flutter comprueba conectividad mediante `NetworkService.isConnected()` en [network_service.dart](lib/services/network_service.dart#L13). La comprobación identifica si el dispositivo tiene una interfaz de conectividad; no demuestra por sí sola que Internet, el servidor o MongoDB estén disponibles.
- Las peticiones de productos se realizan en `ProductService._request()` en [product_service.dart](lib/services/product_service.dart#L41). JSON se envía con `Content-Type: application/json` en POST y PUT. GET y DELETE no envían body ni cabeceras de autenticación.
- Las peticiones de autenticación se realizan directamente en `AuthService` en [auth_service.dart](lib/services/auth_service.dart#L42), también con `Content-Type: application/json`.
- La API de productos no recibe ni verifica el JWT. Las restricciones por rol que se describen abajo se implementan en Flutter, no como autorización del servidor.
- El ID de producto en Flutter es `String` y representa el `_id` hexadecimal de MongoDB. El ID de usuario usado para decidir el rol es el campo numérico `id` de `Usuarios`; no es el `_id` de Mongo.
- Android permite HTTP sin TLS en [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L10), y tiene permiso INTERNET en la línea 4. El backend escucha en `0.0.0.0:3000`; la disponibilidad desde el móvil también depende de la red local, la URL configurada en Flutter y el firewall del equipo.

## Inicialización del backend

No es una acción de pantalla Flutter: ocurre al ejecutar `npm start` desde [`backend/`](backend/README.md).

1. [server.js](backend/server.js) carga la configuración con `dotenv` y valida `PORT` y `JWT_SECRET`.
2. [database.js](backend/config/database.js) conecta MongoClient usando `MONGO_URI` y selecciona la base `appLogin`; los modelos consultan `Productos` y `Usuarios`.
3. Solo después de conectar, `server.js` inicia Express en `0.0.0.0` y el puerto configurado (3000 por defecto), para admitir solicitudes de dispositivos de la red.
4. [app.js](backend/app.js) monta CORS, JSON, `/api/health` y los routers MVC. Si falla la conexión a MongoDB, el servidor no empieza a escuchar y el proceso termina con error.
5. Configura `.env` a partir de [`backend/.env.example`](backend/.env.example); las credenciales no deben copiarse a archivos públicos.

---

## 1. Arranque y restauración de sesión

### 1. Disparador

El usuario abre la aplicación o el proceso de Flutter monta el widget raíz.

### 2. Lado Flutter

1. `main()` en [main.dart](lib/main.dart#L13) ejecuta `runApp(const MyApp())`.
2. `MyApp.build()` en [main.dart](lib/main.dart#L22) configura `AuthController` y `CartController` como proveedores compartidos usando `MultiProvider`; también configura el tema, la ruta inicial `SessionGate` y las rutas nombradas.
3. `SessionGate.initState()` en [main.dart](lib/main.dart#L60) llama a `_checkSession()`, definido en la línea 66.
4. `_checkSession()` obtiene `AuthController` y llama `restoreSession()` en [auth_controller.dart](lib/controllers/auth_controller.dart#L30).
5. `restoreSession()` llama a `AuthService.getStoredUser()` en [auth_service.dart](lib/services/auth_service.dart#L140). Este método comprueba la existencia del token en `FlutterSecureStorage` bajo la clave `auth_token`; después recupera `user_data` de `SharedPreferences`. Si ambos existen, decodifica el JSON guardado con `UserModel.fromJson()` de [user_model.dart](lib/models/user_model.dart#L35).
6. `SessionGate._checkSession()` termina la pantalla de carga si el widget sigue montado. `SessionGate.build()` en [main.dart](lib/main.dart#L75) muestra `HomeView` si `AuthController.isAuthenticated` es verdadero; de lo contrario muestra `LoginView`.

### 3. Lado backend

No se hace petición al backend al restaurar la sesión. El servidor no valida en este momento el token almacenado ni se consulta MongoDB.

### 4. De vuelta en Flutter y errores

- Si hay token y datos del usuario guardados, `AuthController.user` se restaura y se abre el catálogo.
- Si no hay token o no hay `user_data`, `getStoredUser()` devuelve `null` y se muestra el login.
- `AuthController.restoreSession()` captura excepciones de lectura o parseo, pone el usuario en `null` y notifica a los listeners; no muestra un mensaje de error al usuario.
- La sesión restaurada no se contrasta con el estado actual de MongoDB. El token actual se firma sin una expiración explícita en el código de autenticación de [user_controller.js](backend/controllers/user_controller.js), y al restaurar Flutter solo comprueba que el token exista.

### 5. Datos involucrados

- Almacenamiento seguro del dispositivo: `auth_token`.
- `SharedPreferences`: `user_data`, que contiene `id`, `username` y `role`.
- MongoDB: ninguno durante esta operación de restauración.

---

## 2. Inicio de sesión exitoso

### 1. Disparador

El usuario escribe username y contraseña en `LoginView` y toca **Ingresar**.

### 2. Lado Flutter

1. El botón está en `LoginView.build()` en [login_view.dart](lib/views/login_view.dart#L98); su callback invoca `_handleLogin()`, definido en la línea 46.
2. `_handleLogin()` valida el formulario con `FormState.validate()`. Los validadores de username y contraseña están en el widget `TextFormField` en las líneas 192 y 221: comprueban que cada valor no sea vacío.
3. Llama a `NetworkService.isConnected()` en [network_service.dart](lib/services/network_service.dart#L13). Si informa que no hay conectividad, muestra el SnackBar `Sin conexión a internet. Verifica tu red.` y no envía una petición.
4. Obtiene el `AuthController` del proveedor y llama `AuthController.login(username, password)`, definido en [auth_controller.dart](lib/controllers/auth_controller.dart#L42). Flutter recorta espacios al principio y final de ambos valores con `trim()`.
5. `AuthController.login()` activa `isLoading`, borra el error anterior e invoca `AuthService.login()` en [auth_service.dart](lib/services/auth_service.dart#L42).
6. `AuthService.login()` construye `POST http://172.20.10.2:3000/api/usuarios`. El body JSON es `{"username":"...","password":"..."}` y el único header explícito es `Content-Type: application/json`.
7. Para respuesta 200, `AuthService.login()` extrae `token`, decodifica el JWT con `JwtDecoder.decode()`, lee el claim `sub` y convierte su valor a entero mediante `_extractUserId()` (línea 155).
8. `UserModel.fromIdAndUsername()` en [user_model.dart](lib/models/user_model.dart#L15) deriva el rol del ID numérico. El modelo formado se guarda en `AuthController.user`; el token se guarda en `FlutterSecureStorage` (`auth_token`) y `user.toJson()` se guarda en `SharedPreferences` (`user_data`).
9. `AuthController` notifica el cambio de estado. `_handleLogin()` detecta el resultado correcto y usa `Navigator.pushNamedAndRemoveUntil()` para abrir el catálogo y quitar la pantalla de login del historial de navegación.

### 3. Lado backend (`server.js`)

1. `POST /api/usuarios` está definido en [user_routes.js](backend/routes/user_routes.js) y procesado por [user_controller.js](backend/controllers/user_controller.js). El backend comparte esa ruta entre login y registro: si el body **no** contiene la propiedad `email`, interpreta la petición como login.
2. Comprueba que `username` sea una cadena no vacía tras `trim()` y que `password` sea una cadena no vacía. Si falta o es inválido alguno, responde **400**: `{"error":"Se requieren username y password."}`.
3. Consulta `Usuarios` con `usuariosCollection.findOne({ username })`. La contraseña se compara exactamente con `user.password`; no se aplica hashing.
4. Si encuentra el usuario y coincide la contraseña, exige que `user.id` sea entero. Si no lo es, responde **500**: `{"error":"Error al iniciar sesión."}`.
5. Firma un JWT con `jsonwebtoken`, poniendo `sub` como cadena del campo numérico `user.id` y usando `process.env.JWT_SECRET`. Responde **200**: `{"token":"<JWT>"}`.

### 4. De vuelta en Flutter y errores

- Con HTTP 200 se guarda la sesión y se navega al catálogo.
- HTTP 400, 500 u otro estado distinto de 200/401 produce `AuthException("Error en el servidor: <código>")`.
- HTTP 401 produce `AuthException("Usuario o contraseña inválidos")`.
- Si falla la conexión de `http.post`, `AuthService` lanza `AuthException("Error de conexión: ...")`.
- `AuthController.login()` captura `AuthException`, conserva su mensaje en `errorMessage` y devuelve `false`. Errores inesperados (por ejemplo, respuesta JSON/token mal formado) se convierten en `Error inesperado: ...`.
- `LoginView._handleLogin()` muestra `errorMessage` en un SnackBar rojo; el formulario queda disponible para volver a intentar.

### 5. Datos involucrados

- Lectura de `Usuarios.username`, `Usuarios.password` y `Usuarios.id`.
- El campo `id` numérico es el `sub` del JWT y determina el rol. `_id` ObjectId no interviene en la asignación de rol.
- El cliente no envía ni recibe un campo `role` del backend. Lo deriva localmente.

---

## 3. Inicio de sesión rechazado o sin conexión

### 1. Disparador

El usuario intenta ingresar con campos vacíos, sin conectividad, con credenciales incorrectas o el servidor no está disponible.

### 2. Lado Flutter

El mismo `LoginView._handleLogin()` de [login_view.dart](lib/views/login_view.dart#L46) ejecuta las validaciones. Los campos vacíos se marcan debajo de sus respectivos `TextFormField` antes de iniciar HTTP. La prueba de conectividad precede a `AuthController.login()`.

### 3. Lado backend (`server.js`)

Cuando sí llega una petición a `POST /api/usuarios`:

- Body sin username o password válido: **400**, `{"error":"Se requieren username y password."}`.
- Username inexistente o password distinto: **401**, `{"error":"Usuario o contraseña inválidos"}`.
- Usuario encontrado sin `id` entero: **500**, `{"error":"Error al iniciar sesión."}`.
- Excepción consultando MongoDB o firmando el JWT: **500**, el mismo mensaje de error de login.

El servidor compara la contraseña como texto plano y de forma exacta. El username enviado se busca tal cual; Flutter elimina espacios externos antes de enviarlo.

### 4. De vuelta en Flutter y errores

- La respuesta 401 se transforma en `Usuario o contraseña inválidos` y se presenta como SnackBar desde `LoginView`.
- Los demás estados HTTP se resumen como `Error en el servidor: <código>`; Flutter no presenta el JSON del servidor en el flujo de login.
- Una excepción de transporte produce `Error de conexión: ...`.
- Si `NetworkService` no encuentra una interfaz conectada, no se realiza HTTP; la vista muestra `Sin conexión a internet. Verifica tu red.`
- Si la conectividad existe pero Node no está escuchando, la conexión falla en `http.post` y entra en el mensaje de error de conexión.

### 5. Datos involucrados

No se modifican documentos. Se leen los campos `username`, `password` e `id` de `Usuarios` cuando el request llega a la base.

---

## 4. Abrir registro y crear una cuenta

### 1. Disparador

En la pantalla de login, el usuario toca **¿No tienes cuenta? Regístrate**.

### 2. Lado Flutter

1. El botón, en [login_view.dart](lib/views/login_view.dart#L253), invoca `_openRegistration()`, definido en la línea 32.
2. `_openRegistration()` abre `RegisterView` con `Navigator.push()`. La vista de registro está en [register_view.dart](lib/views/register_view.dart#L7).
3. El formulario pide `email`, `username` y `password`; no solicita rol ni confirmación de contraseña. `_validateEmail()` (línea 60) comprueba el patrón básico con `@` y un punto de dominio. Los validadores de username y password rechazan valores vacíos.
4. El botón **Crear cuenta** invoca `_submit()` (línea 32). Evita un segundo envío simultáneo, valida el formulario y activa el indicador de carga.
5. `_submit()` consulta `NetworkService.isConnected()`. Si la comprobación falla, construye `AuthException("Sin conexión a internet. Verifica tu red.")`.
6. Llama `AuthService.register(email, username, password)` en [auth_service.dart](lib/services/auth_service.dart#L89), recortando espacios externos de email y username, pero no los de password.
7. El servicio arma `POST http://172.20.10.2:3000/api/usuarios`, header `Content-Type: application/json`, body `{"email":"...","username":"...","password":"..."}`.
8. Si el servicio termina correctamente, la vista cierra el registro devolviendo el username ingresado. `LoginView._openRegistration()` recibe ese username, lo prellena, limpia el campo contraseña y muestra `Cuenta creada. Ya puedes iniciar sesión.`.
9. El usuario debe iniciar sesión por separado; el registro no crea automáticamente una sesión ni emite token.

### 3. Lado backend (`server.js`)

1. La misma ruta `POST /api/usuarios`, definida en [user_routes.js](backend/routes/user_routes.js) y procesada por [user_controller.js](backend/controllers/user_controller.js), decide que es registro porque el body incluye la propiedad `email`.
2. Comprueba que `email`, `username` y `password` sean strings no vacíos. En caso de faltantes responde **400** con `{"error":"Faltan campos obligatorios: <campos>."}`.
3. Recorta espacios externos de email y username. Busca primero `{ username: normalizedUsername }` y luego `{ email: normalizedEmail }` en la colección `Usuarios`.
4. Si el username ya existe responde **409** `{"error":"El username ya está en uso."}`; si ya existe el email, **409** `{"error":"El email ya está en uso."}`.
5. Busca el mayor `id` numérico usando filtro `{ id: { $type: 'number' } }`, orden descendente, proyección de `id` y límite 1. El nuevo ID es el valor hallado + 1; si no hay documento numérico, usa 1.
6. Inserta `{ email, username, password, id }` mediante `insertOne()`. La contraseña se almacena en texto plano, de acuerdo con la implementación actual.
7. Responde **201** con `{"_id":"<ObjectId>","email":"...","username":"...","id":N}`. En esta respuesta no incluye password.
8. Una excepción en las consultas o inserción responde **500**: `{"error":"Error al registrar el usuario."}`.

### 4. De vuelta en Flutter y errores

- **201:** `AuthService.register()` retorna normalmente. `_submit()` devuelve username al login; login muestra confirmación y prellena username.
- **400 o 409:** `AuthService.register()` trata de decodificar la propiedad `error` de la respuesta y la lanza como `AuthException`. `RegisterView._submit()` la muestra en un SnackBar rojo y mantiene el formulario abierto.
- **500 u otro estado no exitoso:** muestra el error textual del backend si la respuesta es JSON con propiedad `error`; de no ser así usa `Error en el servidor: <código>`.
- **Error de transporte:** el servicio lanza `Error de conexión: ...`; si la comprobación de conectividad detecta desconexión, se muestra el texto genérico de red antes de solicitar.
- En el código de `_submit()` se captura `AuthException`. La validación local muestra errores debajo de cada campo, sin request.

### 5. Datos involucrados

- Inserta en `Usuarios`: `email`, `username`, `password` e `id`.
- Mongo crea `_id` ObjectId automáticamente.
- El rol no se guarda en Mongo ni se envía durante el registro. Con los datos actuales, si el mayor `id` existente es 4, las cuentas siguientes reciben 5 o superior y Flutter las tratará como Cliente.
- El cálculo máximo + 1 no es una secuencia atómica entre peticiones concurrentes. Dos registros simultáneos podrían calcular el mismo ID; esta es una limitación del método actual.

---

## 5. Consultar el catálogo de productos

### 1. Disparador

Se abre `HomeView` después de iniciar sesión o restaurar una sesión; también cuando el usuario toca **Reintentar** después de un error de catálogo.

### 2. Lado Flutter

1. `HomeView.build()` en [home_view.dart](lib/views/home_view.dart#L18) crea un `ProductController` para la pantalla.
2. `_CatalogView.initState()` (línea 39) programa `ProductController.loadCatalog()` tras el primer frame.
3. `loadCatalog()` en [product_controller.dart](lib/controllers/product_controller.dart#L55) incrementa un identificador de petición, cambia estado a loading, vacía temporalmente la lista y comprueba conectividad.
4. Llama `ProductService.getProducts()` en [product_service.dart](lib/services/product_service.dart#L89).
5. El servicio hace `GET http://172.20.10.2:3000/api/productos`, sin body ni headers explícitos.
6. Debe recibir una lista JSON. Cada elemento se convierte con `ProductModel.fromJson()` en [product_model.dart](lib/models/product_model.dart#L17): `_id` se asigna a `id` String, `price` se convierte a double y también se parsean `title`, `description`, `category` e `image`.
7. El controlador deriva `categories` de los valores `product.category`, selecciona la opción “Todos” (`null`) y publica estado loaded.
8. `_catalogBody()` en [home_view.dart](lib/views/home_view.dart#L235) presenta carga, error, lista vacía o una cuadrícula de tarjetas `ProductCard`.

### 3. Lado backend (`server.js`)

`GET /api/productos` está definido en [product_routes.js](backend/routes/product_routes.js). [product_controller.js](backend/controllers/product_controller.js) consulta el modelo y responde **200** con una lista JSON de los documentos. Si la consulta falla, responde **500** `{"error":"Error al obtener los productos"}`.

### 4. De vuelta en Flutter y errores

- **200 y lista JSON:** `ProductService.getProducts()` convierte cada mapa a `ProductModel`; el controlador guarda lista y categorías y la UI crea una tarjeta por producto.
- **Respuesta no exitosa:** `_request()` lanza `ProductException("El servidor no pudo completar la operación (código N).")`. La respuesta de error no se interpreta ni muestra literalmente.
- **Respuesta exitosa que no sea lista:** `ProductService.getProducts()` lanza `El servidor devolvió un catálogo inválido.`
- **JSON mal formado:** `_request()` lanza `La respuesta del servidor no es válida.`
- **Sin conectividad:** `loadCatalog()` registra `No hay conexión a Internet.`
- **Excepción de red/otra excepción:** se registra `No se pudo cargar el catálogo: ...`
- `_CatalogView._catalogBody()` muestra `controller.errorMessage` y un botón Reintentar; en la lista vacía muestra `No hay productos disponibles.`
- Si falla la carga de una imagen remota en la tarjeta, `ProductCard` presenta el ícono de imagen no disponible; no cambia el documento ni detiene el catálogo.

### 5. Datos involucrados

Lectura completa de la colección `Productos`: `_id`, `title`, `price`, `description`, `category`, `image`. No modifica datos.

---

## 6. Filtrar productos por categoría

### 1. Disparador

El usuario toca un chip en la sección **Explorar por categoría** del catálogo.

### 2. Lado Flutter

1. `_CategoryChip` en [home_view.dart](lib/views/home_view.dart#L293) ejecuta el callback `onTap`.
2. El callback invoca `ProductController.selectCategory(category)` (definido en [product_controller.dart](lib/controllers/product_controller.dart#L78)); “Todos” pasa `null`.
3. El controlador comprueba conectividad y vuelve a llamar al servicio del catálogo.
4. Para categoría concreta usa `ProductService.getProductsByCategory()` (línea 108), que primero obtiene el catálogo completo y filtra localmente con `product.category == category`. No existe endpoint HTTP de categoría.
5. Para “Todos”, solicita el catálogo completo directamente. El controlador actualiza la lista y `selectedCategory`, y la vista reconstruye los chips/productos.
6. Si se toca otra vez la categoría no nula que ya estaba activa, `selectCategory()` llama `loadCatalog()`; eso vuelve a mostrar todos y reinicia la categoría seleccionada a `null`.

### 3. Lado backend (`server.js`)

No hay ruta `/api/productos/:category` ni filtro de categoría en el servidor. Toda consulta se atiende con `GET /api/productos`, definido en [product_routes.js](backend/routes/product_routes.js), que devuelve todos los documentos de `Productos`.

### 4. De vuelta en Flutter y errores

Se aplican los mismos resultados y manejo de error que al cargar catálogo: `ProductException` se refleja en `ProductController.errorMessage`; la UI muestra estado de error y permite Reintentar. Las categorías se filtran en memoria, después de recibir la lista.

### 5. Datos involucrados

Lectura de `Productos.category` y de los campos del catálogo asociados a cada producto. No hay escritura.

---

## 7. Abrir el detalle de un producto

### 1. Disparador

El usuario toca una tarjeta del catálogo.

### 2. Lado Flutter

1. En `_catalogBody()`, `ProductCard.onTap` llama `_openProduct(product.id)`, método definido en [home_view.dart](lib/views/home_view.dart#L59).
2. `_openProduct()` navega a `ProductDetailView(productId: id)` y espera un ID String de retorno por si el producto se elimina.
3. `ProductDetailView.build()` en [product_detail_view.dart](lib/views/product_detail_view.dart#L35) crea un `ProductController` y llama `loadProduct(productId)`.
4. `ProductController.loadProduct()` en [product_controller.dart](lib/controllers/product_controller.dart#L109) comprueba conectividad y llama a `ProductService.getProduct(id)` ([product_service.dart](lib/services/product_service.dart#L114)).
5. No hay endpoint HTTP de producto individual. `getProduct()` hace `GET /api/productos` completo y busca localmente el elemento cuyo `product.id == id`.
6. `_ProductDetailContent.build()` muestra imagen, categoría, título, precio y descripción. Si el usuario es Administrador, añade acciones Editar y Eliminar; los otros roles ven el detalle en modo lectura.

### 3. Lado backend (`server.js`)

La búsqueda usa el endpoint `GET /api/productos` en [product_routes.js](backend/routes/product_routes.js), que consulta todos los productos. No se envía el ObjectId al servidor en una ruta individual para este flujo.

### 4. De vuelta en Flutter y errores

- Si encuentra el producto, `loadProduct()` devuelve `true` y la vista presenta los campos.
- Si no está en la lista, el controlador devuelve `false` y guarda `Producto no disponible`. La pantalla programa `_showUnavailable()`, que abre un diálogo y vuelve al catálogo.
- Error de conectividad, respuesta HTTP, JSON o excepción se conserva como error del controlador; al quedar el producto vacío, la pantalla usa el flujo de no disponible. El detalle no presenta un panel separado con el mensaje técnico.
- La carga/error de imagen usa un ícono de reemplazo, igual que el catálogo.

### 5. Datos involucrados

Lectura de `_id`, `title`, `price`, `description`, `category` e `image` de documentos en `Productos`. No modifica MongoDB.

---

## 8. Crear un producto

### 1. Disparador

Un Administrador toca el botón **Agregar producto** (ícono `+`) en la barra superior del catálogo, completa el formulario y toca **Guardar producto**.

### 2. Lado Flutter

1. El botón solo se construye si `user.role == UserRole.admin`; navega a `AppRoutes.createProduct`. La ruta `/products/create` está declarada en [app_routes.dart](lib/routes/app_routes.dart#L1) y se configura en [main.dart](lib/main.dart#L22), donde también se vuelve a decidir si se muestra `ProductFormView` o `HomeView`.
2. `ProductFormView.build()` en [product_form_view.dart](lib/views/product_form_view.dart#L16) crea un `ProductController` y renderiza el formulario.
3. `_ProductFormContentState.didChangeDependencies()` (línea 50) comprueba nuevamente `_isAdmin`; si no lo es, programa una redirección al catálogo. El `build()` interno no presenta el formulario a un usuario no administrador.
4. El botón invoca `_submit()` en [product_form_view.dart](lib/views/product_form_view.dart#L108). Verifica rol y que no haya envío activo; valida campos requeridos, precio numérico finito y URL de imagen HTTP o HTTPS.
5. Si el formulario es válido, construye `ProductModel` con ID vacío y campos `title`, `price`, `description`, `image`, `category`, y llama `ProductController.createProduct()` en [product_controller.dart](lib/controllers/product_controller.dart#L162).
6. El controlador comprueba el rol otra vez, conectividad y llama `ProductService.createProduct()` en [product_service.dart](lib/services/product_service.dart#L123).
7. El servicio comprueba su callback `_isAdmin`, luego envía:
   - Verbo: `POST`
   - URL: `http://172.20.10.2:3000/api/productos`
   - Header: `Content-Type: application/json`
   - Body: `{"title":"...","price":12.5,"description":"...","category":"...","image":"https://..."}`
8. El servicio exige un objeto JSON de respuesta con `_id` String, lo convierte a `ProductModel` y lo devuelve.
9. `_submit()` muestra un diálogo **Producto registrado** con el ID Mongo generado. Al cerrar el diálogo, limpia el formulario y deja al usuario en el formulario de alta. Si navega manualmente al catálogo, la instancia existente de este no se recarga automáticamente por el alta; tampoco el éxito llama a `loadCatalog()`.

### 3. Lado backend (`server.js`)

`POST /api/productos` está definido en [product_routes.js](backend/routes/product_routes.js); la validación y la inserción se realizan en [product_controller.js](backend/controllers/product_controller.js) y [product_model.js](backend/models/product_model.js).

1. `parseProduct(req.body)` en la línea 22 exige `title`, `description`, `category`, `image` como strings no vacíos y `price` como número finito. Recorta espacios externos en los strings.
2. Si un campo no es válido, responde **400**: `{"error":"Se requieren title, price, description, category e image válidos."}`.
3. Si los datos son válidos, inserta el objeto filtrado en `Productos` con `insertOne()`.
4. Responde **201** con `{"_id":"<ObjectId>","title":"...","price":12.5,"description":"...","category":"...","image":"..."}`.
5. Si MongoDB falla, responde **500**: `{"error":"Error al crear el producto"}`.

### 4. De vuelta en Flutter y errores

- **201 con `_id`:** se crea el modelo, se muestra el diálogo con ID y se limpian los campos después de cerrar. El usuario sigue en la pantalla de alta.
- **400/500 u otra respuesta no 2xx:** `ProductService._request()` lanza un mensaje genérico que incluye el código HTTP; no extrae el texto `error` del backend. El controlador conserva el mensaje y devuelve `null`; el formulario muestra un SnackBar con el error.
- **Respuesta 2xx sin `_id` String:** el servicio lanza `El servidor no devolvió el ID Mongo del producto creado.`
- **Sin conectividad/fallo de transporte:** el controlador muestra el error en el mismo SnackBar; el estado de red reportado queda disponible en `errorMessage`.

### 5. Datos involucrados

Se insertan `title`, `price`, `description`, `category` e `image`; MongoDB genera `_id`. No se manda un rol ni un ID de producto.

---

## 9. Editar un producto

### 1. Disparador

Un Administrador abre el detalle y toca **Editar**; cambia los datos del diálogo y toca **Guardar**.

### 2. Lado Flutter

1. La acción Editar solo se muestra para el rol Administrador en `_ProductDetailContent.build()` de [product_detail_view.dart](lib/views/product_detail_view.dart#L60).
2. `_edit()` en [product_detail_view.dart](lib/views/product_detail_view.dart#L205) abre `_ProductEditDialog` con el producto y el controlador vigente.
3. `_ProductEditDialogState.initState()` (línea 287) prepara controladores de texto con título, precio, descripción y categoría existentes. No hay campo para editar imagen; la imagen anterior se conserva.
4. El botón Guardar llama `_save()` (línea 304). Valida título, precio numérico finito, descripción y categoría. Si hay un error guardado se presenta dentro del diálogo.
5. `_save()` crea `widget.product.copyWith(...)`, preserva ID e imagen y llama `ProductController.updateProduct()` en [product_controller.dart](lib/controllers/product_controller.dart#L135).
6. El controlador comprueba rol, conectividad y llama `ProductService.updateProduct()` en [product_service.dart](lib/services/product_service.dart#L145).
7. El servicio hace:
   - Verbo: `PUT`
   - URL: `http://172.20.10.2:3000/api/productos/<product.id>`
   - Header: `Content-Type: application/json`
   - Body: `{"title":"...","price":12.5,"description":"...","category":"...","image":"<imagen existente>"}`
   `product.id` es el `_id` Mongo convertido a String.
8. La respuesta JSON se convierte de nuevo a `ProductModel` y el controlador actualiza su producto actual.
9. Con éxito, el diálogo devuelve `true` y `_edit()` muestra el SnackBar `Producto actualizado.`. El controlador retiene la representación actualizada del detalle. Como el catálogo de Home y el detalle tienen controladores separados, volver al catálogo no actualiza automáticamente la tarjeta existente con los nuevos campos.

### 3. Lado backend (`server.js`)

`PUT /api/productos/:id` está definido en [product_routes.js](backend/routes/product_routes.js) y se procesa en [product_controller.js](backend/controllers/product_controller.js).

1. `parseObjectId(req.params.id)` (línea 44) exige exactamente 24 caracteres hexadecimales. Si no es válido, responde **400**: `{"error":"El ID debe ser un ObjectId válido."}`.
2. Valida body con `parseProduct()`; si falla, **400** con el mensaje de campos inválidos.
3. Actualiza con filtro `{ _id: objectId }` y operación `{ $set: producto }` en `Productos`.
4. Si `matchedCount === 0`, responde **404**: `{"error":"Producto no encontrado."}`.
5. Si encontró el producto, vuelve a leerlo con `findOne({ _id: objectId })` y responde **200** con el documento actualizado, incluidos `_id` y los campos del producto.
6. Una excepción responde **500**: `{"error":"Error al actualizar el producto"}`.

### 4. De vuelta en Flutter y errores

- **200 con documento:** servicio convierte respuesta; el diálogo se cierra y el detalle muestra `Producto actualizado.`
- **400/404/500 o cualquier no-2xx:** el servicio lanza `El servidor no pudo completar la operación (código N).` El controlador devuelve `null`; `_save()` deja el diálogo abierto y presenta el mensaje dentro de él.
- **JSON no válido:** `La respuesta del servidor no es válida.`; se muestra dentro del diálogo como error de guardado.
- **Error de conectividad/transporte:** el controlador devuelve `null` con texto de conectividad/servidor y el diálogo permite volver a intentar.

### 5. Datos involucrados

Filtro de actualización: `_id` ObjectId derivado de `product.id`. Se reemplazan mediante `$set`: `title`, `price`, `description`, `category`, `image`. Desde el formulario actual, imagen no puede editarse, por lo que se reenvía sin cambios.

---

## 10. Eliminar un producto

### 1. Disparador

Un Administrador toca **Eliminar** en el detalle y confirma en el diálogo.

### 2. Lado Flutter

1. El botón solo aparece a Administradores. Su callback invoca `_delete(context, product.id)` en [product_detail_view.dart](lib/views/product_detail_view.dart#L226).
2. `_delete()` primero pregunta “¿Estás seguro de eliminar este producto?”. Cancelar devuelve `false` y termina sin request; solo confirmar continúa.
3. La vista llama `ProductController.deleteProduct(id)` en [product_controller.dart](lib/controllers/product_controller.dart#L188).
4. El controlador verifica rol y conectividad, luego llama `ProductService.deleteProduct(id)` en [product_service.dart](lib/services/product_service.dart#L167).
5. El servicio hace `DELETE http://172.20.10.2:3000/api/productos/<id>`, donde `<id>` es el `_id` Mongo String. No envía body ni Authorization header.
6. Si la respuesta confirma `producto`, el detalle muestra `Producto eliminado.` y hace `Navigator.pop(context, id)`.
7. `_openProduct()` en [home_view.dart](lib/views/home_view.dart#L59) recibe el ID y llama `ProductController.removeById()` en [product_controller.dart](lib/controllers/product_controller.dart#L214), quitando esa tarjeta del estado local sin volver a consultar todo el catálogo.

### 3. Lado backend (`server.js`)

`DELETE /api/productos/:id` está definido en [product_routes.js](backend/routes/product_routes.js) y se procesa en [product_controller.js](backend/controllers/product_controller.js).

1. Valida el ID con `parseObjectId()`. Un ID inválido responde **400** `{"error":"El ID debe ser un ObjectId válido."}`.
2. Ejecuta `findOneAndDelete({ _id: objectId })` en `Productos`.
3. Si no encuentra documento, responde **404** `{"error":"Producto no encontrado."}`.
4. Si lo elimina, responde **200** `{"message":"Producto eliminado correctamente.","producto":{...documento eliminado...}}`.
5. Si MongoDB falla, responde **500** `{"error":"Error al eliminar el producto"}`.

### 4. De vuelta en Flutter y errores

- **200 con `producto`:** `_request()` parsea JSON; `deleteProduct()` verifica que sea mapa y que incluya `producto`; controlador devuelve `true`; la vista notifica éxito y vuelve al catálogo, que elimina la tarjeta localmente.
- **400/404/500 o respuesta no exitosa:** el servicio lanza un `ProductException` con código HTTP; el controlador devuelve `false`; el detalle permanece abierto y muestra SnackBar con `errorMessage`.
- **2xx sin `producto`:** `El servidor no confirmó la eliminación.`
- **Error de red:** el controlador informa el error en la misma ubicación visual y no navega al catálogo.
- **Cancelar:** no se invoca controlador ni endpoint.

### 5. Datos involucrados

Elimina el documento de `Productos` cuya clave `_id` coincide con el ObjectId de la URL. El documento eliminado aparece en `producto` de la respuesta. No se borra por título u otro campo.

---

## 11. Cerrar sesión

### 1. Disparador

El usuario toca el ícono **Cerrar sesión** en la barra superior del catálogo.

### 2. Lado Flutter

1. El botón en [home_view.dart](lib/views/home_view.dart#L125) invoca `_handleLogout()`, definido en la línea 48.
2. `_handleLogout()` llama `CartController.clear()` en [cart_controller.dart](lib/controllers/cart_controller.dart#L20), eliminando artículos de la lista local y notificando a los listeners.
3. Llama `AuthController.logout()` en [auth_controller.dart](lib/controllers/auth_controller.dart#L66).
4. `AuthController.logout()` llama `AuthService.logout()` en [auth_service.dart](lib/services/auth_service.dart#L131), pone `_user` en `null` y notifica.
5. `AuthService.logout()` borra `FlutterSecureStorage` mediante `deleteAll()` y limpia `SharedPreferences` mediante `clear()`.
6. Si la vista sigue montada, `_handleLogout()` elimina las pantallas previas de la pila y navega a `AppRoutes.login`.

### 3. Lado backend

No hay petición HTTP de cierre de sesión y no se revoca token en MongoDB/servidor. La sesión se termina limpiando los datos locales.

### 4. De vuelta en Flutter y errores

El login queda como única pantalla del historial. Al abrir nuevamente el `SessionGate`, no encontrará `auth_token`/`user_data` y mostrará el login. No hay diálogo de confirmación de cierre.

### 5. Datos involucrados

- En memoria: se limpia la lista `_items` del carrito.
- Dispositivo: se borran entradas de almacenamiento seguro y preferencias.
- MongoDB: no se modifica.

---

## 12. Restricciones según rol

### 1. Disparador

Las comprobaciones ocurren al construir el catálogo, abrir una ruta administrativa o intentar una operación de alta, edición o eliminación.

### 2. Lado Flutter

1. El rol se asigna en [user_model.dart](lib/models/user_model.dart#L15): ID `1` o `2` → Administrador; ID `3` → Auditor; cualquier otro entero → Cliente.
2. `UserRole` define las etiquetas visibles en [user_role.dart](lib/models/enums/user_role.dart#L1).
3. `HomeView` muestra nombre de usuario y etiqueta de rol en la AppBar. El botón `+` se incluye únicamente cuando `user.role == UserRole.admin` (código en [home_view.dart](lib/views/home_view.dart#L72)).
4. La ruta nombrada `/products/create` vuelve a comprobar el rol en [main.dart](lib/main.dart#L22). Si no es Administrador, devuelve `HomeView`.
5. `ProductFormView` vuelve a comprobar rol en `didChangeDependencies()` y en `_submit()`. `ProductController` comprueba rol para create/update/delete y `ProductService` tiene otra comprobación `_requireAdmin()` en [product_service.dart](lib/services/product_service.dart#L80).
6. En el detalle, Editar y Eliminar solo se dibujan para Administrador. Auditor y Cliente pueden leer detalle y catálogo, pero no ven esos botones.

### 3. Lado backend (`server.js`)

Los endpoints de productos `POST`, `PUT` y `DELETE` en [product_routes.js](backend/routes/product_routes.js) no verifican JWT, identidad ni rol. Tampoco reciben header Authorization desde `ProductService`.

### 4. De vuelta en Flutter y comportamiento de cada rol

| Operación/pantalla | Administrador (ID 1 o 2) | Auditor (ID 3) | Cliente (ID 4+) |
|---|---|---|---|
| Catálogo | Lee y filtra productos; ve botón `+` | Lee y filtra; sin botón `+` | Lee y filtra; sin botón `+` |
| Detalle | Ve Editar y Eliminar | Solo lectura | Solo lectura |
| Ruta de alta | Puede abrir formulario | Se devuelve a Home | Se devuelve a Home |
| Crear/editar/borrar vía controladores/servicio | Permitido en Flutter; API se invoca | Bloqueado en Flutter | Bloqueado en Flutter |

El mensaje de denegación de los controladores/servicio es `Acceso denegado: solo un Administrador puede modificar productos.`. Esta protección es de interfaz/cliente: un cliente que invoque directamente los endpoints backend podría operar si tiene acceso de red. El servidor debe validar autorización para que el rol sea un control de seguridad efectivo; el código actual no lo hace.

### 5. Datos involucrados

Se usa `Usuarios.id` numérico, convertido en `UserModel.role`. El backend no almacena `role`; no se modifica ningún documento al evaluar permisos.

---

## 13. Endpoint de consulta de usuarios (no llamado por Flutter)

### 1. Disparador

Un cliente externo de pruebas, navegador o herramienta HTTP solicita la lista de usuarios. Ninguna pantalla Flutter de la aplicación llama este endpoint.

### 2. Lado Flutter

No existe método consumidor en `AuthService` ni en las vistas actuales para `GET /api/usuarios`.

### 3. Lado backend (`server.js`)

`GET /api/usuarios` está definido en [user_routes.js](backend/routes/user_routes.js). El modelo [user_model.js](backend/models/user_model.js) excluye el campo `password` de la proyección y responde **200** con los demás campos. Si falla, responde **500** `{"error":"Error al obtener los usuarios"}`.

### 4. De vuelta en Flutter

No hay flujo de respuesta en Flutter porque la app no consume esta ruta.

### 5. Datos involucrados

Lectura de documentos de `Usuarios`, sin el campo `password`.

---

## 14. Carrito: estado local sin flujo de compra visible

### 1. Disparador

En el código revisado no existe pantalla, botón de compra ni otro flujo visible que invoque `CartController.addItem()`.

### 2. Lado Flutter

`MyApp` registra `CartController` en [main.dart](lib/main.dart#L22). El controlador guarda una lista local de String, expone una vista no modificable mediante `items`, y expone `itemCount`. `addItem()` añade a la lista y notifica, pero no tiene consumidor en las vistas actuales. `clear()` sí se invoca durante logout.

### 3. Lado backend

No hay colección ni endpoint de carrito en el backend MVC.

### 4. De vuelta en Flutter

No existe confirmación de compra o persistencia del carrito. Al cerrar sesión se vacía.

### 5. Datos involucrados

Solo la lista `_items` en memoria del proceso Flutter. No se escribe en MongoDB ni en almacenamiento persistente.

---

## 15. Consulta de catálogo fallida, catálogo vacío e imagen no disponible

### 1. Disparador

Al fallar el GET inicial, al volver una lista vacía, al fallar la carga de una imagen o al tocar **Reintentar**.

### 2. Lado Flutter

La carga usa `loadCatalog()` y `_catalogBody()` ya descritos en el escenario 5. El botón Reintentar llama otra vez `loadCatalog()`. `ProductCard` en [product_card.dart](lib/views/widgets/product_card.dart#L6) y la imagen del detalle en [product_detail_view.dart](lib/views/product_detail_view.dart#L60) utilizan `Image.network`; los `errorBuilder` muestran un ícono alternativo si la URL no carga.

### 3. Lado backend

Si se envía un GET, el endpoint es `GET /api/productos` de [product_routes.js](backend/routes/product_routes.js). Una lista vacía responde **200** `[]`; un fallo al consultar responde **500** `{"error":"Error al obtener los productos"}`. La descarga de imágenes remotas ocurre desde Flutter/dispositivo, no desde este endpoint.

### 4. De vuelta en Flutter y errores

- La lista vacía muestra `No hay productos disponibles.`
- Error HTTP o de red muestra una pantalla con el error del controlador y botón Reintentar.
- Error de imagen muestra el ícono, pero conserva el producto y todos sus datos.

### 5. Datos involucrados

GET solo lee documentos de `Productos`; el fallo de imagen no modifica ni elimina `image`.

---

## 16. Endpoint de productos: validación, IDs y forma de los documentos

El helper `parseProduct()` de [product_model.js](backend/models/product_model.js) se comparte entre creación y actualización. Acepta solo objetos JSON con `title`, `description`, `category`, `image` como strings no vacíos y `price` numérico finito; devuelve una versión con strings recortados. `parseObjectId()` admite únicamente 24 caracteres hexadecimales y construye un `ObjectId`.

El modelo Flutter [ProductModel](lib/models/product_model.dart#L1) representa:

| Campo Flutter | Campo Mongo/JSON | Tipo Flutter | Uso |
|---|---|---|---|
| `id` | `_id` | `String` | Identidad Mongo en rutas PUT/DELETE y búsqueda local |
| `title` | `title` | `String` | Título del producto |
| `price` | `price` | `double` | Precio numérico |
| `description` | `description` | `String` | Descripción |
| `category` | `category` | `String` | Filtro y etiqueta |
| `image` | `image` | `String` | URL mostrada por `Image.network` |

`toJson()` serializa el ID con la clave `_id`; las peticiones de alta y edición, sin embargo, preparan explícitamente el body en `ProductService` y no envían el ID como parte del body.

---

## Diagrama de flujo general

```text
Arranque
└── lib/main.dart: main()
    └── MyApp: MultiProvider(AuthController, CartController) + MaterialApp
        └── SessionGate.initState() -> _checkSession()
            └── AuthController.restoreSession()
                └── AuthService.getStoredUser()
                    ├── FlutterSecureStorage: lee auth_token
                    └── SharedPreferences: lee user_data
                        └── UserModel.fromJson()
            ├── sesión local presente -> HomeView
            │   └── _CatalogView.initState()
            │       └── ProductController.loadCatalog()
            │           ├── NetworkService.isConnected()
            │           └── ProductService.getProducts()
            │               └── GET /api/productos
            │                   └── server.js -> MongoDB Productos.find({})
            │                       └── JSON -> ProductModel.fromJson()
            │                           └── catálogo + chips ProductCard
            │                               ├── elegir categoría
            │                               │   └── selectCategory()
            │                               │       └── GET completo + filtro local
            │                               ├── tocar tarjeta
            │                               │   └── _openProduct()
            │                               │       └── ProductDetailView
            │                               │           └── loadProduct()
            │                               │               └── GET completo + búsqueda local
            │                               │                   ├── Administrador: Editar/Eliminar
            │                               │                   │   ├── PUT /api/productos/:id
            │                               │                   │   └── DELETE /api/productos/:id
            │                               │                   └── Auditor/Cliente: solo lectura
            │                               ├── Administrador toca +
            │                               │   └── ProductFormView -> _submit()
            │                               │       └── ProductController.createProduct()
            │                               │           └── ProductService.createProduct()
            │                               │               └── POST /api/productos
            │                               └── Cerrar sesión
            │                                   └── CartController.clear()
            │                                       -> AuthController.logout()
            │                                           -> AuthService.logout()
            │                                               ├── secure storage deleteAll()
            │                                               └── SharedPreferences clear()
            │                                                   -> LoginView
            └── no hay sesión local -> LoginView
                ├── Ingresar -> _handleLogin()
                │   └── NetworkService -> AuthController.login()
                │       -> AuthService.login()
                │           -> POST /api/usuarios {username,password}
                │               -> server.js -> MongoDB Usuarios.findOne()
                │                   -> JWT {sub: String(user.id)}
                │                       -> FlutterSecureStorage + SharedPreferences
                │                           -> UserModel.fromIdAndUsername()
                │                               -> rol -> HomeView
                └── Registrarse -> _openRegistration() -> RegisterView
                    └── _submit() -> AuthService.register()
                        -> POST /api/usuarios {email,username,password}
                            -> server.js detecta la propiedad email
                                -> valida duplicados y máximo id
                                -> MongoDB Usuarios.insertOne()
                                    -> HTTP 201 -> vuelve a LoginView
                                        -> username prellenado
```

## Nota de lectura línea por línea

Los números citados son líneas del estado del código inspeccionado para crear este documento. Si se agregan o quitan líneas después, pueden desplazarse. Los nombres de archivo, widgets, métodos, URLs, cuerpos y filtros explican el comportamiento del código actual, no una propuesta de cómo debería comportarse.
