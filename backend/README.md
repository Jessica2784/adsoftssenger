# Adsoftssenger Backend

Backend REST en Spring Boot para la Fase III de Adsoftssenger.

## Requisitos

- Java 17
- Maven
- PostgreSQL en `localhost:5432`
- Base de datos `adsoftssenger_db`
- Usuario `postgres`
- Password `postgres`

## Ejecutar

```bash
cd backend
mvn spring-boot:run
```

La API queda disponible en `http://localhost:8080/api`.

## Endpoints iniciales

- `GET /api/users`
- `POST /api/users`
- `GET /api/chats`
- `POST /api/chats`
- `GET /api/chats/{chatId}/messages`
- `POST /api/messages`
