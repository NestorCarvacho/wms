# WMS API - Sistema de Gestión de Almacén

API REST para Sistema de Gestión de Almacén (WMS) construida con **FastAPI**, arquitectura en capas y principios **SOLID**.

## 🏗️ Arquitectura

```
app/
├── domain/              # Modelos de dominio y entidades
│   └── models.py       # Modelos SQLAlchemy
├── application/         # Servicios de negocio y DTOs
│   ├── dto.py          # Data Transfer Objects (Pydantic)
│   └── services.py     # Servicios de negocio
├── infrastructure/      # Persistencia y acceso a datos
│   ├── database.py     # Configuración de BD
│   └── repositories.py # Repository pattern
├── interfaces/          # Endpoints y controllers
│   └── controllers.py  # Routers y endpoints
├── core/               # Configuración y seguridad
│   ├── config.py       # Configuración centralizada
│   └── security.py     # JWT, hashing, autenticación
├── tests/              # Tests unitarios e integración
└── main.py            # Aplicación FastAPI
```

## ✨ Características

- ✅ **Arquitectura en Capas**: Domain, Application, Infrastructure, Interface, Core
- ✅ **Principios SOLID**: Single Responsibility, Open/Closed, Liskov, Interface Segregation, Dependency Inversion
- ✅ **Autenticación JWT**: Access y Refresh tokens
- ✅ **SQLAlchemy ORM**: Manejo de base de datos
- ✅ **Pydantic DTOs**: Validación y documentación automática
- ✅ **Swagger/OpenAPI**: Documentación interactiva en `/docs`
- ✅ **Async/Await**: Endpoints asincronos
- ✅ **CORS Habilitado**: Para consumo desde frontend
- ✅ **Tests**: Ejemplos de tests unitarios

## 🚀 Quick Start

### 1. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
# Editar .env con valores propios
```

### 3. Ejecutar servidor

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

El servidor estará disponible en: `http://localhost:8000`

## 📚 Documentación API

### Swagger UI (Interactivo)
```
http://localhost:8000/api/v1/docs
```

### ReDoc
```
http://localhost:8000/api/v1/redoc
```

## 🔐 Autenticación

### Login

```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@wms.com", "password": "password123"}'
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

### Usar Token en Requests

```bash
curl -X GET "http://localhost:8000/api/v1/users/me" \
  -H "Authorization: Bearer <access_token>"
```

### Refrescar Token

```bash
curl -X POST "http://localhost:8000/api/v1/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "<refresh_token>"}'
```

## 👥 Endpoints

### Auth
- `POST /api/v1/auth/login` - Login de usuario
- `POST /api/v1/auth/refresh` - Refrescar access token

### Users
- `POST /api/v1/users` - Crear usuario
- `GET /api/v1/users/me` - Obtener usuario actual
- `GET /api/v1/users/{user_id}` - Obtener usuario por ID
- `PUT /api/v1/users/{user_id}` - Actualizar usuario
- `DELETE /api/v1/users/{user_id}` - Eliminar usuario

### Health
- `GET /health` - Health check
- `GET /` - Información de la API

## 🧪 Tests

```bash
# Ejecutar todos los tests
pytest app/tests -v

# Con cobertura
pytest app/tests --cov=app --cov-report=html

# Tests específicos
pytest app/tests/test_auth.py -v
```

## 📋 Requerimientos Implementados

### ✅ Implementado
- R.09 - Asignación de Roles Usuarios (Login con roles)
- R.10 - Acceso Seguro al Almacén (JWT)
- R.31 - Especificaciones de Seguridad (JWT, Bcrypt)
- R.41 - Autorización y Autenticación (JWT con tokens)

### 🔄 Próximamente
- R.01 - Mantenimiento Góndolas
- R.02 - Asignación de Productos a Góndolas
- R.05 - Ingreso de Productos al Almacén
- R.06 - Extracción de Productos
- R.27 - Mantenimiento de Almacenes
- R.30 - Gestión de Inventario en Tiempo Real

## 🔑 Variables de Entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Clave para firmar JWT | - |
| `DATABASE_URL` | URL de conexión a BD | `sqlite:///./wms.db` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Expiración de access token | 30 |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Expiración de refresh token | 7 |

## 🛠️ Stack Tecnológico

- **Framework**: FastAPI
- **Base de Datos**: SQLAlchemy + SQLite (configurable)
- **Validación**: Pydantic
- **Autenticación**: Python-jose (JWT)
- **Password Hashing**: Passlib + Bcrypt
- **Testing**: Pytest
- **Servidor**: Uvicorn

## 📖 Copilot Instructions

El proyecto incluye instrucciones específicas por capa:

- `.copilot-instructions` - Visión general del proyecto
- `app/domain/.copilot-instructions` - Domain Layer
- `app/application/.copilot-instructions` - Application Layer
- `app/infrastructure/.copilot-instructions` - Infrastructure Layer
- `app/interfaces/.copilot-instructions` - Interface Layer
- `app/core/.copilot-instructions` - Core Layer

## 📝 Principios SOLID

### Single Responsibility (S)
Cada clase tiene una única responsabilidad:
- `User` - Solo modelo de datos
- `UserRepository` - Solo acceso a datos
- `UserService` - Solo lógica de negocio
- Controllers - Solo endpoints

### Open/Closed (O)
- Interfaces (IUserRepository, IAuthService)
- Fácil extender sin modificar

### Liskov Substitution (L)
- Implementaciones intercambiables
- Herencia de interfaces consistente

### Interface Segregation (I)
- Interfaces pequeñas y específicas
- Servicios especializados

### Dependency Inversion (D)
- Servicios inyectados en constructores
- FastAPI Depends para inyección

## 🐛 Debugging

### Enable Debug Logging
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Database Inspect
```bash
sqlite3 wms.db ".tables"
sqlite3 wms.db ".schema users"
```

## 📞 Contacto & Soporte

Para preguntas o problemas:
1. Revisar `.copilot-instructions` de la capa relevante
2. Revisar tests en `app/tests/`
3. Documentación Swagger en `/api/v1/docs`

## 📄 Licencia

Interno - Visma
