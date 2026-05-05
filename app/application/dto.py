from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional
from enum import Enum

class RoleEnum(str, Enum):
    """Roles disponibles"""
    ADMIN = "admin"
    MANAGER = "manager"
    OPERATOR = "operator"
    VIEWER = "viewer"

# ============ Auth DTOs ============

class LoginRequest(BaseModel):
    """Request para login"""
    email: EmailStr = Field(..., description="Email del usuario")
    password: str = Field(..., min_length=6, description="Contraseña")

    class Config:
        json_schema_extra = {
            "example": {
                "email": "admin@wms.com",
                "password": "password123"
            }
        }

class TokenResponse(BaseModel):
    """Response con tokens"""
    access_token: str = Field(..., description="Token de acceso JWT")
    refresh_token: str = Field(..., description="Token para refrescar acceso")
    token_type: str = "bearer"
    expires_in: int = Field(..., description="Segundos hasta expiración")
    company_id: int = Field(..., description="ID de la empresa del usuario")

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 1800,
                "company_id": 1
            }
        }

class RefreshTokenRequest(BaseModel):
    """Request para refrescar token"""
    refresh_token: str = Field(..., description="Token de refresco")

# ============ User DTOs ============

class UserCreate(BaseModel):
    """DTO para crear usuario"""
    email: EmailStr = Field(..., description="Email único del usuario")
    full_name: str = Field(..., min_length=1, max_length=100, description="Nombre completo")
    password: str = Field(..., min_length=6, description="Contraseña")
    role: RoleEnum = Field(default=RoleEnum.VIEWER, description="Rol del usuario")

    class Config:
        json_schema_extra = {
            "example": {
                "email": "usuario@wms.com",
                "full_name": "Juan Pérez",
                "password": "password123",
                "role": "operator"
            }
        }

class UserUpdate(BaseModel):
    """DTO para actualizar usuario"""
    full_name: Optional[str] = Field(None, max_length=100)
    role: Optional[RoleEnum] = None
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    """DTO de respuesta para usuario"""
    id: int = Field(..., description="ID del usuario")
    company_id: int = Field(..., description="ID de la empresa")
    email: str = Field(..., description="Email del usuario")
    full_name: str = Field(..., description="Nombre completo")
    role: str = Field(..., description="Rol del usuario")
    is_active: bool = Field(..., description="Estado activo")
    created_at: datetime = Field(..., description="Fecha de creación")
    updated_at: datetime = Field(..., description="Fecha de actualización")

    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": 1,
                "company_id": 1,
                "email": "admin@wms.com",
                "full_name": "Administrador",
                "role": "admin",
                "is_active": True,
                "created_at": "2024-01-15T10:30:00",
                "updated_at": "2024-01-15T10:30:00"
            }
        }

# ============ Generic DTOs ============

class SuccessResponse(BaseModel):
    """Response estándar de éxito"""
    success: bool = True
    data: Optional[dict] = None
    message: str = "Operación exitosa"
    status_code: int = 200

class ErrorResponse(BaseModel):
    """Response estándar de error"""
    success: bool = False
    data: Optional[dict] = None
    message: str
    status_code: int = 400
