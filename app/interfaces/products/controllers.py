from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.infrastructure.database import get_db
from app.application.products import ProductService, ProductCreate, ProductResponse, ProductUpdate, PaginatedProductResponse
from app.application.products.dto import ProductFilters, SortField, SortOrder
from app.core.security import get_current_user

product_router = APIRouter(prefix="/productos", tags=["Products"])


@product_router.post(
    "",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear nuevo producto",
    description="Crea un nuevo producto en el inventario",
)
async def create_product(
    product_create: ProductCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> ProductResponse:
    """
    Crea un nuevo producto

    - **sku**: SKU único del producto (ej: PROD-001)
    - **name**: Nombre del producto
    - **description**: Descripción del producto
    - **category**: Categoría (ej: Electrónica, Ropa)
    - **price**: Precio del producto (mayor a 0)
    - **stock**: Stock inicial (mínimo 0)

    Validaciones:
    - El SKU debe ser único
    - Todos los campos requeridos deben estar presentes
    """
    product_service = ProductService(db)
    return product_service.create_product(product_create)


@product_router.get(
    "",
    response_model=PaginatedProductResponse,
    status_code=status.HTTP_200_OK,
    summary="Listar productos con búsqueda y filtros",
    description="Obtiene lista de productos con búsqueda avanzada, filtros y paginación",
)
async def get_products(
    search: Optional[str] = Query(
        None,
        max_length=100,
        description="Búsqueda por nombre, descripción o SKU (case-insensitive)"
    ),
    category: Optional[str] = Query(
        None,
        max_length=100,
        description="Filtrar por categoría exacta"
    ),
    min_price: Optional[float] = Query(
        None,
        ge=0,
        description="Precio mínimo"
    ),
    max_price: Optional[float] = Query(
        None,
        ge=0,
        description="Precio máximo"
    ),
    in_stock: Optional[bool] = Query(
        None,
        description="Solo productos con stock disponible (true/false)"
    ),
    is_active: bool = Query(
        True,
        description="Filtrar por estado activo"
    ),
    sort_by: SortField = Query(
        SortField.NAME,
        description="Campo para ordenar (name, price, stock, created_at)"
    ),
    sort_order: SortOrder = Query(
        SortOrder.ASC,
        description="Orden (asc, desc)"
    ),
    skip: int = Query(
        0,
        ge=0,
        description="Cantidad de registros a saltar (paginación)"
    ),
    limit: int = Query(
        20,
        ge=1,
        le=100,
        description="Cantidad de registros por página (máximo 100)"
    ),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> PaginatedProductResponse:
    """
    Obtiene lista de productos con búsqueda avanzada, filtros y paginación

    **Parámetros de Búsqueda:**
    - `search`: Busca en nombre, descripción o SKU

    **Parámetros de Filtrado:**
    - `category`: Categoría exacta
    - `min_price`, `max_price`: Rango de precios
    - `in_stock`: Solo productos con stock > 0
    - `is_active`: Solo productos activos (default: true)

    **Parámetros de Ordenamiento:**
    - `sort_by`: Campo (name, price, stock, created_at)
    - `sort_order`: Dirección (asc, desc)

    **Parámetros de Paginación:**
    - `skip`: Registros a saltar (default: 0)
    - `limit`: Registros por página (default: 20, máximo: 100)

    **Ejemplos:**
    - `/api/v1/productos?search=laptop` - Busca "laptop"
    - `/api/v1/productos?category=Electrónica&min_price=100&max_price=2000` - Rango de precio
    - `/api/v1/productos?in_stock=true&sort_by=price&sort_order=asc` - Ordenar por precio
    - `/api/v1/productos?skip=0&limit=20` - Primera página de 20 items
    """
    filters = ProductFilters(
        search=search,
        category=category,
        min_price=min_price,
        max_price=max_price,
        in_stock=in_stock,
        is_active=is_active,
        sort_by=sort_by,
        sort_order=sort_order,
        skip=skip,
        limit=limit,
    )

    product_service = ProductService(db)
    return product_service.get_all_products(filters)


@product_router.get(
    "/{product_id}",
    response_model=ProductResponse,
    status_code=status.HTTP_200_OK,
    summary="Obtener producto por ID",
    description="Retorna los datos de un producto específico",
)
async def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> ProductResponse:
    """
    Obtiene un producto específico por su ID
    """
    product_service = ProductService(db)
    return product_service.get_product(product_id)


@product_router.put(
    "/{product_id}",
    response_model=ProductResponse,
    status_code=status.HTTP_200_OK,
    summary="Actualizar producto",
    description="Actualiza los datos de un producto",
)
async def update_product(
    product_id: int,
    product_update: ProductUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> ProductResponse:
    """
    Actualiza un producto existente

    Solo se actualizan los campos que se proporcionen (actualización parcial).
    El SKU no puede duplicarse.
    """
    product_service = ProductService(db)
    return product_service.update_product(product_id, product_update)


@product_router.delete(
    "/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar producto",
    description="Elimina un producto del inventario",
)
async def delete_product(
    product_id: int,
    soft: bool = Query(True, description="Usar soft delete (marcar como inactivo)"),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un producto

    Query Parameters:
    - **soft**: Si es true, marca como inactivo (soft delete). Si es false, lo borra completamente.

    Validaciones:
    - El producto debe existir
    - No se pueden eliminar productos con inventario vinculado
    """
    product_service = ProductService(db)
    if not product_service.delete_product(product_id, soft=soft):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Producto no encontrado"
        )
