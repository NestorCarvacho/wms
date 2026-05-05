from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class SortField(str, Enum):
    """Campos disponibles para ordenamiento"""
    NAME = "name"
    PRICE = "price"
    STOCK = "stock"
    CREATED_AT = "created_at"


class SortOrder(str, Enum):
    """Orden de clasificación"""
    ASC = "asc"
    DESC = "desc"


class ProductFilters(BaseModel):
    """Filtros para búsqueda de productos"""
    search: Optional[str] = Field(
        None,
        max_length=100,
        description="Búsqueda por nombre o descripción (case-insensitive)"
    )
    category: Optional[str] = Field(
        None,
        max_length=100,
        description="Filtro por categoría exacta (case-insensitive)"
    )
    min_price: Optional[float] = Field(
        None,
        ge=0,
        description="Precio mínimo"
    )
    max_price: Optional[float] = Field(
        None,
        ge=0,
        description="Precio máximo"
    )
    in_stock: Optional[bool] = Field(
        None,
        description="Solo productos con stock disponible"
    )
    is_active: Optional[bool] = Field(
        default=True,
        description="Filtrar por estado activo"
    )
    sort_by: SortField = Field(
        default=SortField.NAME,
        description="Campo para ordenar"
    )
    sort_order: SortOrder = Field(
        default=SortOrder.ASC,
        description="Orden (asc/desc)"
    )
    skip: int = Field(
        default=0,
        ge=0,
        description="Cantidad de registros a saltar (paginación)"
    )
    limit: int = Field(
        default=20,
        ge=1,
        le=100,
        description="Cantidad de registros por página (máximo 100)"
    )


class ProductCreate(BaseModel):
    """DTO para crear producto"""
    sku: str = Field(..., min_length=1, max_length=50, description="SKU único del producto")
    name: str = Field(..., min_length=1, max_length=200, description="Nombre del producto")
    description: Optional[str] = Field(None, max_length=500, description="Descripción del producto")
    category: str = Field(..., min_length=1, max_length=100, description="Categoría del producto")
    price: float = Field(..., gt=0, description="Precio del producto")
    stock: int = Field(default=0, ge=0, description="Stock inicial")

    class Config:
        json_schema_extra = {
            "example": {
                "sku": "PROD-001",
                "name": "Laptop Dell XPS",
                "description": "Laptop de alta performance",
                "category": "Electrónica",
                "price": 1299.99,
                "stock": 10
            }
        }


class ProductUpdate(BaseModel):
    """DTO para actualizar producto"""
    name: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    price: Optional[float] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductResponse(BaseModel):
    """DTO de respuesta para producto"""
    id: int = Field(..., description="ID del producto")
    sku: str = Field(..., description="SKU del producto")
    name: str = Field(..., description="Nombre del producto")
    description: Optional[str] = Field(None, description="Descripción")
    category: str = Field(..., description="Categoría")
    price: float = Field(..., description="Precio")
    stock: int = Field(..., description="Stock disponible")
    is_active: bool = Field(..., description="Estado activo")
    created_at: datetime = Field(..., description="Fecha de creación")
    updated_at: datetime = Field(..., description="Fecha de actualización")

    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": 1,
                "sku": "PROD-001",
                "name": "Laptop Dell XPS",
                "description": "Laptop de alta performance",
                "category": "Electrónica",
                "price": 1299.99,
                "stock": 10,
                "is_active": True,
                "created_at": "2024-01-15T10:30:00",
                "updated_at": "2024-01-15T10:30:00"
            }
        }


class PaginatedProductResponse(BaseModel):
    """DTO para respuesta paginada de productos"""
    items: list[ProductResponse] = Field(..., description="Lista de productos")
    total: int = Field(..., description="Total de productos")
    page: int = Field(..., description="Página actual")
    page_size: int = Field(..., description="Tamaño de página")
    total_pages: int = Field(..., description="Total de páginas")
