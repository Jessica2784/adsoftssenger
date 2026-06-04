# Adsoftssenger - Fase III

## 1. Nombre del proyecto

**Adsoftssenger** es una aplicación de mensajería estilo Messenger desarrollada como proyecto académico para la **Fase III Enterprise**.

El sistema integra una aplicación móvil/web construida con Flutter y un backend REST desarrollado con Spring Boot, conectado a una base de datos PostgreSQL.

## 2. Objetivo de la Fase III

El objetivo de la Fase III es transformar la aplicación en una solución con arquitectura enterprise, separando la interfaz de usuario, la lógica de negocio, la persistencia y la comunicación entre capas.

En esta fase se implementa:

- Consumo de datos reales desde un backend Spring Boot.
- Servicios REST para usuarios, conversaciones y mensajes.
- Persistencia de información en PostgreSQL.
- Uso de DTOs para intercambiar datos entre frontend y backend.
- Separación del backend en controllers, services y repositories.
- Simulación de actualización en tiempo real mediante consultas periódicas desde Flutter.
- Datos iniciales cargados automáticamente con un `CommandLineRunner`.

## 3. Tecnologías usadas

- **Flutter**: desarrollo del frontend y pantallas de la aplicación.
- **Spring Boot**: desarrollo del backend REST.
- **Java 17**: lenguaje principal del backend.
- **PostgreSQL**: base de datos relacional.
- **Maven**: gestión de dependencias y ejecución del backend.
- **HTTP REST**: comunicación entre Flutter y Spring Boot mediante JSON.

## 4. Arquitectura

La arquitectura del proyecto está dividida en tres capas principales: frontend, backend y base de datos.

### Frontend

El frontend está desarrollado en Flutter. Su responsabilidad es mostrar la interfaz de usuario, consumir los endpoints REST del backend y enviar o recibir información en formato JSON.

Funciones principales del frontend:

- Listar conversaciones reales por usuario.
- Mostrar mensajes por conversación.
- Enviar mensajes al backend.
- Simular actualización en tiempo real consultando mensajes cada 3 segundos.
- Mostrar estados de carga, errores y listas vacías.

La carpeta principal de servicios Flutter es:

```text
lib/services/
```

Servicios implementados:

- `api_service.dart`
- `usuario_service.dart`
- `conversacion_service.dart`
- `mensaje_service.dart`

### Backend

El backend está desarrollado con Spring Boot y expone una API REST bajo la URL base:

```text
http://localhost:8080/api
```

Su responsabilidad es recibir peticiones HTTP, validar datos, ejecutar lógica de negocio y persistir la información en PostgreSQL.

### Base de datos

La base de datos usada es PostgreSQL. El backend utiliza Spring Data JPA para mapear las entidades Java a tablas relacionales.

Base configurada en `application.properties`:

```text
adsoftssenger_bd
```

### Controllers

Los controllers reciben las peticiones HTTP y devuelven respuestas JSON.

Controllers principales:

- `UsuarioController`
- `ConversacionController`
- `MensajeController`

### Services

Los services contienen la lógica de negocio de la aplicación.

Services principales:

- `UsuarioService`
- `ConversacionService`
- `MensajeService`

### Repositories

Los repositories se encargan del acceso a datos usando Spring Data JPA.

Repositories principales:

- `UsuarioRepository`
- `ConversacionRepository`
- `MensajeRepository`
- `EstadoMensajeRepository`

### DTOs

Los DTOs permiten enviar y recibir datos sin exponer directamente las entidades internas.

DTOs principales:

- `UsuarioDTO`
- `ConversacionDTO`
- `MensajeDTO`
- `RegistroRequest`
- `LoginRequest`
- `CrearConversacionRequest`
- `EnviarMensajeRequest`

## 5. Entidades principales

### Usuario

Representa a una persona registrada en el sistema.

Campos principales:

- `id`
- `nombreUsuario`
- `nombreMostrar`
- `correo`
- `passwordHash`
- `fotoPerfilUrl`
- `fechaCreacion`
- `estadoActivo`

### Conversacion

Representa una conversación entre usuarios. En la fase actual se usan conversaciones individuales entre dos participantes.

Campos principales:

- `id`
- `fechaCreacion`
- `esGrupal`
- `nombreGrupo`
- `participantes`
- `mensajes`

### Mensaje

Representa un mensaje enviado dentro de una conversación.

Campos principales:

- `id`
- `contenido`
- `tipoMensaje`
- `urlAdjunto`
- `duracionAudioSeg`
- `fechaEnvio`
- `remitente`
- `conversacion`

### EstadoMensaje

Representa el estado de un mensaje para un destinatario.

Campos principales:

- `id`
- `mensaje`
- `destinatario`
- `estado`
- `fechaActualizacion`

Estados posibles:

- `ENVIADO`
- `ENTREGADO`
- `LEIDO`

## 6. Endpoints implementados

### Usuarios

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/api/usuarios/registro` | Registra un nuevo usuario. |
| `POST` | `/api/usuarios/login` | Inicia sesión con correo y contraseña. |
| `GET` | `/api/usuarios` | Lista los usuarios registrados. |
| `GET` | `/api/usuarios/{id}` | Obtiene un usuario por id. |

### Conversaciones

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/api/conversaciones` | Crea una conversación entre dos usuarios. |
| `GET` | `/api/conversaciones/usuario/{usuarioId}` | Lista las conversaciones de un usuario. |

### Mensajes

| Método | Endpoint | Descripción |
|---|---|---|
| `POST` | `/api/mensajes` | Envía un mensaje a una conversación. |
| `GET` | `/api/mensajes/conversacion/{conversacionId}` | Lista los mensajes de una conversación. |

### Endpoints auxiliares existentes

El backend también contiene endpoints CRUD auxiliares bajo:

- `/api/users`
- `/api/chats`
- `/api/messages`

La integración principal con Flutter usa los endpoints en español: `/api/usuarios`, `/api/conversaciones` y `/api/mensajes`.

## 7. Cómo ejecutar

### Requisitos previos

- Java 17 instalado.
- Maven instalado.
- Flutter SDK instalado.
- PostgreSQL instalado y ejecutándose.
- Un navegador o emulador/dispositivo para Flutter.

### Crear base de datos

Abrir PostgreSQL y crear la base de datos:

```sql
CREATE DATABASE adsoftssenger_bd;
```

También puede crearse desde terminal:

```bash
createdb -U postgres adsoftssenger_bd
```

La configuración esperada por el backend es:

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/adsoftssenger_bd
spring.datasource.username=postgres
spring.datasource.password=postgres
```

### Ejecutar backend

Desde la raíz del proyecto:

```bash
cd backend
mvn spring-boot:run
```

Si Maven no detecta Java 17, se puede ejecutar con `JAVA_HOME` explícito:

```bash
cd backend
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn spring-boot:run
```

El backend queda disponible en:

```text
http://localhost:8080/api
```

Al arrancar, el `DataSeeder` inserta usuarios, conversaciones y mensajes iniciales si la tabla de usuarios está vacía.

Usuarios iniciales:

- Jessica
- Luis García
- Mateo Fernández
- Elena Rodríguez
- Carlos Ruiz

Contraseña inicial para los usuarios sembrados:

```text
password123
```

### Ejecutar frontend

Desde la raíz del proyecto:

```bash
flutter pub get
flutter run
```

Para ejecutar en navegador:

```bash
flutter run -d chrome
```

La aplicación Flutter consume el backend configurado en:

```text
http://localhost:8080/api
```

Nota: si se ejecuta en emulador Android, puede ser necesario cambiar `localhost` por `10.0.2.2` en el servicio base de Flutter, porque `localhost` dentro del emulador apunta al propio emulador.

## 8. Capturas sugeridas para evidencia

Para la entrega universitaria se recomienda incluir capturas de:

1. Backend Spring Boot ejecutándose en consola.
2. Base de datos PostgreSQL con tablas creadas.
3. Registros iniciales en la tabla de usuarios.
4. Conversaciones creadas entre Jessica y los demás usuarios.
5. Lista de chats en Flutter consumiendo datos reales.
6. Pantalla de conversación mostrando mensajes desde el backend.
7. Envío de un mensaje nuevo desde Flutter.
8. Respuesta del endpoint en Postman, Insomnia o navegador.
9. Estructura del proyecto mostrando carpetas `controller`, `service`, `repository`, `dto` y `model`.

## 9. Cumplimiento de la Fase III Enterprise

El proyecto cumple con la Fase III Enterprise porque integra una arquitectura separada por responsabilidades y orientada a servicios.

Puntos principales de cumplimiento:

- **Separación frontend/backend**: Flutter se encarga de la interfaz y Spring Boot de la lógica de negocio.
- **API REST**: la comunicación se realiza mediante endpoints HTTP y datos JSON.
- **Persistencia real**: los datos se almacenan en PostgreSQL usando JPA.
- **Arquitectura por capas**: el backend está dividido en controllers, services, repositories, DTOs y entidades.
- **DTOs**: se usan objetos de transferencia para enviar datos limpios al frontend.
- **Servicios especializados**: existen servicios para usuarios, conversaciones y mensajes.
- **Repositorios JPA**: se utiliza Spring Data JPA para acceder a la base de datos.
- **Datos iniciales**: se implementa un `DataSeeder` con `CommandLineRunner` para cargar información de prueba al arrancar.
- **Integración real con Flutter**: la lista de chats y la pantalla de mensajes consumen endpoints reales.
- **Simulación de tiempo real**: la pantalla de chat consulta mensajes periódicamente cada 3 segundos sin usar WebSocket.
- **Manejo básico de errores**: tanto el backend como el frontend manejan errores y estados de carga.

En conjunto, Adsoftssenger Fase III demuestra una aplicación enterprise básica con comunicación cliente-servidor, persistencia en base de datos, servicios REST y una interfaz funcional conectada al backend.
