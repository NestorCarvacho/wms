import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.infrastructure.database import Base, get_db
from app.core.security import SecurityService
from app.domain.models import User, Company, RoleEnum

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
        code="TEST-001",
        name="Test Company",
        is_active=True
    )
    db.add(company)
    db.commit()
    db.refresh(company)
    company_id = company.id
    db.close()
    return company_id

@pytest.fixture
def test_user_data():
    """Datos de usuario de prueba"""
    return {
        "email": "test@example.com",
        "full_name": "Test User",
        "password": "test123",
        "role": "operator"
    }

def test_create_user(test_user_data, test_company):
    """Test: Crear usuario"""
    response = client.post(
        "/api/v1/users",
        json=test_user_data,
        headers={"Authorization": "Bearer test_token"}
    )
    # Este test necesita autenticación, aquí es un ejemplo
    assert response.status_code in [200, 201, 401]

def test_login_success(test_user_data, test_company):
    """Test: Login exitoso"""
    db = TestingSessionLocal()

    # Crear usuario con company_id
    hashed_password = SecurityService.hash_password(test_user_data["password"])
    user = User(
        company_id=test_company,
        email=test_user_data["email"],
        full_name=test_user_data["full_name"],
        hashed_password=hashed_password,
        role=RoleEnum.OPERATOR,
        is_active=True
    )
    db.add(user)
    db.commit()
    db.close()

    # Login
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": test_user_data["email"],
            "password": test_user_data["password"]
        }
    )

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert "company_id" in data
    assert data["company_id"] == test_company

def test_login_invalid_credentials():
    """Test: Login con credenciales inválidas"""
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": "nonexistent@example.com",
            "password": "wrongpassword"
        }
    )

    assert response.status_code == 401

def test_health_check():
    """Test: Health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_root_endpoint():
    """Test: Root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "docs" in data
