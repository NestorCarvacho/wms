# Guía de Desarrollo - WMS API

## 🚀 Primeros Pasos

### 1. Configuración Inicial

```bash
# Crear entorno virtual
python -m venv venv

# Activar entorno virtual
# En Windows:
venv\Scripts\activate
# En macOS/Linux:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt
```

### 2. Configurar Base de Datos

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Inicializar BD con usuarios de prueba
python setup_db.py
```

**Usuarios creados:**
```
admin@wms.com        / Admin@123
manager@wms.com      / Manager@123
operator@wms.com     / Operator@123
viewer@wms.com       / Viewer@123
```

### 3. Ejecutar Servidor

```bash
# Modo desarrollo (con auto-reload)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# O ejecutar desde main.py
python app/main.py
```

Servidor disponible en: **http://localhost:8000**

## 📚 Documentación Interactiva

Una vez el servidor esté corriendo:

- **Swagger UI**: http://localhost:8000/api/v1/docs
- **ReDoc**: http://localhost:8000/api/v1/redoc
- **OpenAPI JSON**: http://localhost:8000/api/v1/openapi.json

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
pytest app/tests -v

# Tests específicos
pytest app/tests/test_auth.py -v

# Con cobertura
pytest app/tests --cov=app --cov-report=html
# Abre: htmlcov/index.html
```

### Estructura de Tests

```
app/tests/
├── test_auth.py       # Tests de autenticación
├── test_users.py      # Tests de usuarios (próximamente)
└── conftest.py        # Fixtures compartidas (próximamente)
```

## 🔍 Endpoints Principales

### Health Check
```bash
curl http://localhost:8000/health
```

### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@wms.com", "password": "Admin@123"}'
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

### Obtener Usuario Actual
```bash
curl http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer <access_token>"
```

### Crear Usuario
```bash
curl -X POST http://localhost:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{
    "email": "newuser@wms.com",
    "full_name": "Nuevo Usuario",
    "password": "Password123",
    "role": "operator"
  }'
```

## 📂 Estructura del Proyecto

```
app/
├── domain/              # Entidades de negocio
│   ├── models.py       # Modelos SQLAlchemy
│   └── __init__.py
├── application/         # Lógica de negocio
│   ├── dto.py          # DTOs para validación
│   ├── services.py     # Servicios
│   └── __init__.py
├── infrastructure/      # Persistencia
│   ├── database.py     # Configuración BD
│   ├── repositories.py # Repository pattern
│   └── __init__.py
├── interfaces/          # HTTP
│   ├── controllers.py  # Endpoints
│   └── __init__.py
├── core/               # Configuración
│   ├── config.py       # Settings
│   ├── security.py     # JWT, hashing
│   └── __init__.py
├── tests/              # Tests
│   ├── test_auth.py
│   └── __init__.py
└── main.py             # App principal
```

## 🛠️ Workflow de Desarrollo

### Agregar Nueva Entidad

#### 1. Crear Modelo (Domain)
```python
# app/domain/models.py
class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    sku = Column(String, unique=True, nullable=False)
    created_at = Column(DateTime, server_default=func.now())
```

#### 2. Crear DTOs (Application)
```python
# app/application/dto.py
class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1)
    sku: str = Field(..., regex="^[A-Z0-9-]+$")

class ProductResponse(BaseModel):
    id: int
    name: str
    sku: str
    created_at: datetime

    class Config:
        from_attributes = True
```

#### 3. Crear Repositorio (Infrastructure)
```python
# app/infrastructure/repositories.py
class IProductRepository(ABC):
    @abstractmethod
    def create(self, product: Product) -> Product: pass
    @abstractmethod
    def get_by_sku(self, sku: str) -> Optional[Product]: pass

class ProductRepository(IProductRepository):
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, product: Product) -> Product:
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return product
```

#### 4. Crear Servicio (Application)
```python
# app/application/services.py
class ProductService:
    def __init__(self, db: Session):
        self.product_repo = ProductRepository(db)
    
    def create_product(self, product_create: ProductCreate) -> ProductResponse:
        # Validaciones de negocio
        existing = self.product_repo.get_by_sku(product_create.sku)
        if existing:
            raise HTTPException(status_code=400, detail="SKU duplicado")
        
        product = Product(
            name=product_create.name,
            sku=product_create.sku
        )
        created = self.product_repo.create(product)
        return ProductResponse.from_orm(created)
```

#### 5. Crear Endpoints (Interface)
```python
# app/interfaces/controllers.py
product_router = APIRouter(prefix="/products", tags=["Products"])

@product_router.post(
    "",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear producto"
)
async def create_product(
    product_create: ProductCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> ProductResponse:
    service = ProductService(db)
    return service.create_product(product_create)
```

#### 6. Registrar Router
```python
# app/main.py
app.include_router(product_router, prefix=settings.API_PREFIX)
```

## 🔐 Variables de Entorno

Editar `.env`:

```bash
# Application
APP_NAME="WMS API"
APP_VERSION="1.0.0"
API_PREFIX="/api/v1"

# Database
DATABASE_URL="sqlite:///./wms.db"

# JWT Security
SECRET_KEY="super-secret-key-change-in-production"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
ALLOWED_ORIGINS=["http://localhost:3000", "http://localhost:8000"]
```

## 🐛 Debugging

### Logs

```python
import logging

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

logger.debug("Debug message")
logger.info("Info message")
logger.warning("Warning message")
logger.error("Error message")
```

### Inspeccionar BD

```bash
# SQLite shell
sqlite3 wms.db

# Listar tablas
.tables

# Ver esquema
.schema users

# Consultas
SELECT * FROM users;
.quit
```

### Inspeccionar Requests

Swagger UI proporciona interfaz interactiva para probar endpoints.

## 📝 Convenciones de Código

### Naming
- Variables: `snake_case`
- Clases: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`

### Type Hints
```python
# ✅ Requerido
def create_user(user_create: UserCreate) -> UserResponse:
    pass

# ❌ Evitar
def create_user(user_create):
    pass
```

### Docstrings
```python
def login(self, email: str, password: str) -> Tuple[str, str]:
    """
    Autentica un usuario

    Args:
        email: Email del usuario
        password: Contraseña

    Returns:
        Tuple de (access_token, refresh_token)

    Raises:
        HTTPException: Si credenciales son inválidas
    """
    pass
```

## 🚀 Performance

### Database Indexes
```python
# app/domain/models.py
email = Column(String, index=True)  # Para búsquedas frecuentes
```

### Async Operations
Todos los endpoints usan `async/await`:
```python
@app.get("/users/{id}")
async def get_user(id: int, db: Session = Depends(get_db)):
    # I/O no bloqueante
    pass
```

## 📦 Dependencias

| Paquete | Versión | Uso |
|---------|---------|-----|
| fastapi | 0.104.1 | Framework web |
| uvicorn | 0.24.0 | Servidor ASGI |
| sqlalchemy | 2.0.23 | ORM |
| pydantic | 2.5.0 | Validación |
| python-jose | 3.3.0 | JWT tokens |
| passlib | 1.7.4 | Password hashing |
| pytest | 7.4.3 | Testing |

## 🔄 CI/CD (Próximo)

- [ ] Configurar GitHub Actions
- [ ] Tests automáticos
- [ ] Linting (pylint, black)
- [ ] Type checking (mypy)
- [ ] Documentación automática

## 📞 Troubleshooting

### Error: "No module named 'app'"
```bash
# Asegúrate de estar en el directorio correcto
cd /path/to/wms
python -m pip install -e .
```

### Error: "ModuleNotFoundError: No module named 'fastapi'"
```bash
pip install -r requirements.txt
```

### Error: "database is locked"
```bash
# Eliminar archivo DB y recrear
rm wms.db
python setup_db.py
```

### Error: "Invalid authentication credentials"
```bash
# Verificar token JWT
# 1. Obtener nuevo token en /api/v1/auth/login
# 2. Usar en Authorization header
```

## 📚 Recursos

- FastAPI Docs: https://fastapi.tiangolo.com/
- SQLAlchemy: https://docs.sqlalchemy.org/
- Pydantic: https://docs.pydantic.dev/
- JWT: https://jwt.io/
- SOLID: https://en.wikipedia.org/wiki/SOLID

## 🎯 Próximos Pasos

1. ✅ Arquitectura base implementada
2. ⏳ Agregar productos y almacenes
3. ⏳ Implementar inventario en tiempo real
4. ⏳ Agregar reportes
5. ⏳ Integración ERP/CRM
