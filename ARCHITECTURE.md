# Arquitectura WMS API

## 📐 Visión General

La WMS API está construida con una arquitectura en capas que separa responsabilidades y sigue principios SOLID. Esto facilita el mantenimiento, testing y extensión del sistema.

## 🏗️ Capas de la Arquitectura

### 1. **Interface Layer** (Interfaces)
**Ubicación**: `app/interfaces/controllers.py`

**Responsabilidad**: Exponer endpoints HTTP y manejar requests/responses

**Componentes**:
- FastAPI Routers (APIRouter)
- Endpoints REST
- Validación de requests con DTOs
- Respuestas estandarizadas

**Principios SOLID**:
- **S**: Cada router maneja un dominio (auth_router, user_router)
- **D**: Servicios inyectados vía Depends()

**Ejemplo**:
```python
@router.post("/login")
async def login(credentials: LoginRequest, db: Session = Depends(get_db)):
    auth_service = AuthService(db)
    return auth_service.login(...)
```

---

### 2. **Application Layer** (Servicios de Negocio)
**Ubicación**: `app/application/services.py`, `app/application/dto.py`

**Responsabilidad**: Implementar la lógica de negocio

**Componentes**:
- **Services**: Lógica de negocio (AuthService, UserService)
- **DTOs**: Validación de datos (LoginRequest, UserCreate, UserResponse)

**Principios SOLID**:
- **S**: Servicios especializados (AuthService solo autentica)
- **O**: Interfaces (IAuthService, IUserService) abiertas a extensión
- **D**: Repositorios inyectados

**Ejemplo de Service**:
```python
class AuthService(IAuthService):
    def __init__(self, db: Session):
        self.user_repository = UserRepository(db)
    
    def login(self, email: str, password: str):
        user = self.user_repository.get_by_email(email)
        # Validaciones de negocio
        # Generación de tokens
        return access_token, refresh_token
```

**DTOs - Validación Automática**:
```python
class LoginRequest(BaseModel):
    email: EmailStr  # Validación de email
    password: str = Field(..., min_length=6)  # Validación de longitud
```

---

### 3. **Infrastructure Layer** (Persistencia)
**Ubicación**: `app/infrastructure/database.py`, `app/infrastructure/repositories.py`

**Responsabilidad**: Acceso a datos y persistencia

**Componentes**:
- **Database**: Configuración SQLAlchemy
- **Repositories**: CRUD operations
- **Interfaces**: IUserRepository (contrato)

**Principios SOLID**:
- **S**: Cada repositorio maneja una entidad
- **L**: Implementaciones intercambiables de repositorios
- **D**: Servicios reciben repositorios inyectados

**Repository Pattern**:
```python
class IUserRepository(ABC):
    @abstractmethod
    def create(self, user: User) -> User: pass
    @abstractmethod
    def get_by_email(self, email: str) -> Optional[User]: pass
    # ...

class UserRepository(IUserRepository):
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, user: User) -> User:
        self.db.add(user)
        self.db.commit()
        return user
```

---

### 4. **Domain Layer** (Modelos)
**Ubicación**: `app/domain/models.py`

**Responsabilidad**: Definir entidades de negocio

**Componentes**:
- Modelos SQLAlchemy
- Enums para estados

**Principios SOLID**:
- **S**: Cada modelo = una tabla
- **O**: Fácil extender con nuevos campos

**Ejemplo**:
```python
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True)
    role = Column(Enum(RoleEnum), default=RoleEnum.VIEWER)
    created_at = Column(DateTime, server_default=func.now())
```

---

### 5. **Core Layer** (Servicios Transversales)
**Ubicación**: `app/core/config.py`, `app/core/security.py`

**Responsabilidad**: Configuración global y servicios reutilizables

**Componentes**:
- Settings/Configuración
- JWT y hashing
- Autenticación

**SecurityService**:
```python
class SecurityService:
    @staticmethod
    def hash_password(password: str) -> str:
        return pwd_context.hash(password)
    
    @staticmethod
    def create_token(data: dict, token_type: str = "access") -> str:
        # JWT generation
        return jwt.encode(...)
    
    @staticmethod
    def verify_token(token: str) -> dict:
        return jwt.decode(...)
```

---

## 🔄 Flujo de Datos

### Ejemplo: Login

```
1. Cliente envía POST /api/v1/auth/login
   ↓
2. Interface Layer (controllers.py)
   - Recibe LoginRequest (email, password)
   - Valida con Pydantic automáticamente
   ↓
3. Application Layer (services.py - AuthService)
   - Obtiene usuario via repositorio
   - Verifica contraseña
   - Genera JWT tokens
   ↓
4. Infrastructure Layer (repositories.py - UserRepository)
   - Busca usuario en BD
   - get_by_email()
   ↓
5. Domain Layer (models.py - User)
   - Modelo mapeado a tabla users
   ↓
6. Core Layer (security.py - SecurityService)
   - Hash password verification
   - JWT token creation
   ↓
7. Response
   - TokenResponse (access_token, refresh_token, expires_in)
```

---

## 🔐 Autenticación JWT

### Flujo de Tokens

```
1. Login
   POST /auth/login {email, password}
   ↓
   ✅ Retorna: {access_token, refresh_token, expires_in}

2. Usar Access Token
   GET /users/me
   Headers: Authorization: Bearer <access_token>
   ↓
   ✅ get_current_user() valida y retorna user_id

3. Refrescar Token (cuando expira)
   POST /auth/refresh {refresh_token}
   ↓
   ✅ Retorna: {access_token, refresh_token, expires_in}
```

### JWT Payload

```json
{
  "sub": "1",              // user_id
  "email": "admin@wms.com",
  "role": "admin",
  "type": "access",
  "exp": 1234567890       // expiration timestamp
}
```

---

## 📦 Estructura de Carpetas Completa

```
wms/
├── app/
│   ├── domain/
│   │   ├── __init__.py
│   │   ├── models.py              # SQLAlchemy models
│   │   └── .copilot-instructions
│   │
│   ├── application/
│   │   ├── __init__.py
│   │   ├── dto.py                 # Pydantic models para validación
│   │   ├── services.py            # Lógica de negocio
│   │   └── .copilot-instructions
│   │
│   ├── infrastructure/
│   │   ├── __init__.py
│   │   ├── database.py            # SQLAlchemy setup
│   │   ├── repositories.py        # Repository pattern
│   │   └── .copilot-instructions
│   │
│   ├── interfaces/
│   │   ├── __init__.py
│   │   ├── controllers.py         # FastAPI routers
│   │   └── .copilot-instructions
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py              # Configuración
│   │   ├── security.py            # JWT, hashing
│   │   └── .copilot-instructions
│   │
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_auth.py           # Test examples
│   │
│   └── main.py                    # FastAPI app
│
├── .copilot-instructions          # Instrucciones globales
├── .env.example                   # Variables de entorno
├── requirements.txt               # Dependencias Python
├── setup_db.py                    # Script para inicializar BD
├── README.md                      # Documentación
└── ARCHITECTURE.md               # Este archivo
```

---

## ✅ Principios SOLID en Acción

### 1. **S - Single Responsibility**

```python
# ❌ MAL: Una clase hace todo
class UserController:
    def login(self, email, password):
        # Validación
        # Query a BD
        # Hash password
        # JWT generation
        # Response

# ✅ BIEN: Responsabilidades separadas
# Controller: maneja HTTP
# Service: lógica de negocio
# Repository: acceso a datos
# SecurityService: criptografía
```

### 2. **O - Open/Closed**

```python
# ✅ Abierto para extensión, cerrado para modificación
class IUserRepository(ABC):
    @abstractmethod
    def create(self, user: User) -> User: pass

# Podemos agregar UsuarioRepository, UsuarioAltRepository sin tocar el código existente
```

### 3. **L - Liskov Substitution**

```python
# ✅ Las implementaciones son intercambiables
class AuthService:
    def __init__(self, user_repo: IUserRepository):
        # Puedo pasar UserRepository, MockRepository, etc.
        self.user_repo = user_repo
```

### 4. **I - Interface Segregation**

```python
# ✅ Interfaces pequeñas y específicas
class IAuthService(ABC):
    @abstractmethod
    def login(self, email: str, password: str): pass

class IUserService(ABC):
    @abstractmethod
    def create_user(self, user_create: UserCreate): pass

# No: una interfaz gigante con todo
```

### 5. **D - Dependency Inversion**

```python
# ✅ Depender de abstracciones, no implementaciones
class AuthService:
    def __init__(self, db: Session):
        self.user_repo = UserRepository(db)  # Inyectable

# En FastAPI:
@app.post("/login")
async def login(db: Session = Depends(get_db)):
    auth_service = AuthService(db)  # Inyección de dependencia
```

---

## 🧪 Testing en Capas

### Unit Tests (Servicios)
```python
def test_login_success():
    # Mock repository
    # Mock security service
    # Probar lógica de login
```

### Integration Tests (Endpoints)
```python
def test_login_endpoint():
    # Usar TestClient
    # BD de prueba
    # Probar flujo completo
```

---

## 🚀 Extensión del Sistema

Para agregar una nueva entidad (ej: Product):

### 1. Domain Layer
```python
# app/domain/models.py
class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    # ...
```

### 2. Application Layer
```python
# app/application/dto.py
class ProductCreate(BaseModel): ...
class ProductResponse(BaseModel): ...

# app/application/services.py
class ProductService:
    def create_product(self, product_create: ProductCreate): ...
```

### 3. Infrastructure Layer
```python
# app/infrastructure/repositories.py
class ProductRepository(IProductRepository):
    def create(self, product: Product): ...
```

### 4. Interface Layer
```python
# app/interfaces/controllers.py
product_router = APIRouter(prefix="/products")

@product_router.post("")
async def create_product(
    product_create: ProductCreate,
    db: Session = Depends(get_db)
):
    service = ProductService(db)
    return service.create_product(product_create)
```

### 5. Main
```python
# app/main.py
app.include_router(product_router, prefix=settings.API_PREFIX)
```

---

## 📊 Comparación: Con vs Sin SOLID

| Aspecto | Sin SOLID | Con SOLID |
|--------|-----------|----------|
| Cambiar BD | Tocar todo | Cambiar solo Repository |
| Testing | Difícil (dependencias globales) | Fácil (inyección) |
| Reutilizar lógica | Copiar-pegar | Servicios reutilizables |
| Agregar features | Refactorizar mucho | Agregar nuevas clases |
| Entender código | Difícil (todo mezclado) | Claro (separado por capas) |

---

## 🎯 Checklist para Nuevas Features

- [ ] Crear modelo en Domain Layer
- [ ] Crear DTOs en Application Layer
- [ ] Crear servicio en Application Layer
- [ ] Crear repositorio en Infrastructure Layer
- [ ] Crear endpoints en Interface Layer
- [ ] Agregar router en main.py
- [ ] Escribir tests
- [ ] Documentar en Swagger (automático)
- [ ] Agregar instrucciones `.copilot-instructions` si es necesario

---

## 🔗 Véase También

- `.copilot-instructions` - Instrucciones globales
- `app/domain/.copilot-instructions` - Dominio
- `app/application/.copilot-instructions` - Servicios y DTOs
- `app/infrastructure/.copilot-instructions` - Persistencia
- `app/interfaces/.copilot-instructions` - Endpoints
- `app/core/.copilot-instructions` - Configuración
