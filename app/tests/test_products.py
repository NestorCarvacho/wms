import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.infrastructure.database import Base, get_db
from app.core.security import SecurityService
from app.domain.models import User, Company, RoleEnum
from app.domain.products.models import Product

# Test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_and_teardown():
    """Setup y cleanup para cada test"""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def test_company():
    """Crea una empresa de prueba"""
    db = TestingSessionLocal()
    company = Company(
        code="TEST-PROD",
        name="Test Company Products",
        is_active=True
    )
    db.add(company)
    db.commit()
    db.refresh(company)
    company_id = company.id
    db.close()
    return company_id

@pytest.fixture
def auth_headers(test_company):
    """Crea un usuario de prueba y retorna headers con token"""
    db = TestingSessionLocal()

    user_data = {
        "email": "admin@test.com",
        "full_name": "Admin User",
        "password": "admin123",
        "role": RoleEnum.ADMIN,
    }

    hashed_password = SecurityService.hash_password(user_data["password"])
    user = User(
        company_id=test_company,
        email=user_data["email"],
        full_name=user_data["full_name"],
        hashed_password=hashed_password,
        role=user_data["role"],
        is_active=True
    )
    db.add(user)
    db.commit()
    db.close()

    # Login
    response = client.post(
        "/api/v1/auth/login",
        json={"email": user_data["email"], "password": user_data["password"]}
    )

    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def product_data():
    """Datos de producto de prueba"""
    return {
        "sku": "PROD-001",
        "name": "Laptop Dell XPS",
        "description": "Laptop de alta performance",
        "category": "Electrónica",
        "price": 1299.99,
        "stock": 10
    }

# ============ Tests de Crear Producto ============

def test_create_product_success(auth_headers, product_data):
    """Test: Crear producto exitosamente"""
    response = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )

    assert response.status_code == 201
    data = response.json()
    assert data["sku"] == product_data["sku"]
    assert data["name"] == product_data["name"]
    assert data["price"] == product_data["price"]
    assert data["stock"] == product_data["stock"]
    assert "id" in data
    assert "created_at" in data
    assert "updated_at" in data

def test_create_product_duplicate_sku(auth_headers, product_data):
    """Test: Crear producto con SKU duplicado"""
    # Crear primer producto
    response1 = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )
    assert response1.status_code == 201

    # Intentar crear segundo producto con mismo SKU
    response2 = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )
    assert response2.status_code == 400
    assert "ya existe" in response2.json()["detail"]

def test_create_product_missing_fields(auth_headers):
    """Test: Crear producto sin campos requeridos"""
    incomplete_data = {
        "sku": "PROD-002",
        "name": "Producto Sin Precio"
    }

    response = client.post(
        "/api/v1/productos",
        json=incomplete_data,
        headers=auth_headers
    )

    assert response.status_code == 422  # Validation error

def test_create_product_invalid_price(auth_headers, product_data):
    """Test: Crear producto con precio inválido"""
    product_data["price"] = -100

    response = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )

    assert response.status_code == 422

# ============ Tests de Listar Productos ============

def test_get_products_empty(auth_headers):
    """Test: Listar productos cuando está vacío"""
    response = client.get(
        "/api/v1/productos",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["items"] == []
    assert data["page"] == 1
    assert data["total_pages"] == 0

def test_get_products_with_data(auth_headers, product_data):
    """Test: Listar productos con datos"""
    # Crear producto
    client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )

    # Listar
    response = client.get(
        "/api/v1/productos",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert len(data["items"]) == 1
    assert data["items"][0]["sku"] == product_data["sku"]

def test_get_products_with_pagination(auth_headers, product_data):
    """Test: Listar productos con paginación"""
    # Crear 5 productos
    for i in range(5):
        data = product_data.copy()
        data["sku"] = f"PROD-{i:03d}"
        data["name"] = f"Producto {i}"
        client.post(
            "/api/v1/productos",
            json=data,
            headers=auth_headers
        )

    # Listar con limit
    response = client.get(
        "/api/v1/productos?skip=0&limit=2",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 5
    assert len(data["items"]) == 2
    assert data["page"] == 1
    assert data["total_pages"] == 3

def test_get_products_filter_by_name(auth_headers, product_data):
    """Test: Filtrar productos por nombre"""
    # Crear dos productos
    product_data["name"] = "Laptop"
    client.post("/api/v1/productos", json=product_data, headers=auth_headers)

    product_data["sku"] = "PROD-002"
    product_data["name"] = "Mouse Logitech"
    product_data["description"] = "Mouse inalámbrico"
    client.post("/api/v1/productos", json=product_data, headers=auth_headers)

    # Buscar por nombre
    response = client.get(
        "/api/v1/productos?search=Laptop",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["name"] == "Laptop"

def test_get_products_filter_by_category(auth_headers, product_data):
    """Test: Filtrar productos por categoría"""
    # Crear dos productos con categorías diferentes
    product_data["category"] = "Electrónica"
    client.post("/api/v1/productos", json=product_data, headers=auth_headers)

    product_data["sku"] = "PROD-002"
    product_data["category"] = "Ropa"
    client.post("/api/v1/productos", json=product_data, headers=auth_headers)

    # Filtrar por categoría
    response = client.get(
        "/api/v1/productos?category=Ropa",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert data["items"][0]["category"] == "Ropa"

# ============ Tests de Obtener Producto ============

def test_get_product_by_id(auth_headers, product_data):
    """Test: Obtener producto por ID"""
    # Crear producto
    create_response = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )
    product_id = create_response.json()["id"]

    # Obtener
    response = client.get(
        f"/api/v1/productos/{product_id}",
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == product_id
    assert data["sku"] == product_data["sku"]

def test_get_product_not_found(auth_headers):
    """Test: Obtener producto que no existe"""
    response = client.get(
        "/api/v1/productos/999",
        headers=auth_headers
    )

    assert response.status_code == 404

# ============ Tests de Actualizar Producto ============

def test_update_product_success(auth_headers, product_data):
    """Test: Actualizar producto exitosamente"""
    # Crear producto
    create_response = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )
    product_id = create_response.json()["id"]

    # Actualizar
    update_data = {
        "name": "Laptop Dell XPS 15",
        "price": 1599.99,
        "stock": 5
    }

    response = client.put(
        f"/api/v1/productos/{product_id}",
        json=update_data,
        headers=auth_headers
    )

    assert response.status_code == 200
    data = response.json()
    assert data["name"] == update_data["name"]
    assert data["price"] == update_data["price"]
    assert data["stock"] == update_data["stock"]
    assert data["sku"] == product_data["sku"]  # No cambió

def test_update_product_not_found(auth_headers):
    """Test: Actualizar producto que no existe"""
    response = client.put(
        "/api/v1/productos/999",
        json={"name": "Nuevo Nombre"},
        headers=auth_headers
    )

    assert response.status_code == 404

# ============ Tests de Eliminar Producto ============

def test_delete_product_soft(auth_headers, product_data):
    """Test: Eliminar producto (soft delete)"""
    # Crear producto
    create_response = client.post(
        "/api/v1/productos",
        json=product_data,
        headers=auth_headers
    )
    product_id = create_response.json()["id"]

    # Eliminar (soft)
    response = client.delete(
        f"/api/v1/productos/{product_id}?soft=true",
        headers=auth_headers
    )

    assert response.status_code == 204

    # Verificar que no aparece en listado
    list_response = client.get(
        "/api/v1/productos",
        headers=auth_headers
    )
    assert list_response.json()["total"] == 0

def test_delete_product_not_found(auth_headers):
    """Test: Eliminar producto que no existe"""
    response = client.delete(
        "/api/v1/productos/999",
        headers=auth_headers
    )

    assert response.status_code == 404
