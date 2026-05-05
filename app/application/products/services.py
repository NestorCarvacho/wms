from abc import ABC, abstractmethod
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.domain.products import Product
from app.infrastructure.products import ProductRepository
from app.application.products.dto import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    PaginatedProductResponse,
    ProductFilters,
)


class IProductService(ABC):
    """Interface para servicio de productos"""

    @abstractmethod
    def create_product(self, product_create: ProductCreate, company_id: int) -> ProductResponse:
        pass

    @abstractmethod
    def get_product(self, product_id: int, company_id: int) -> ProductResponse:
        pass

    @abstractmethod
    def get_all_products(self, company_id: int, filters: ProductFilters) -> PaginatedProductResponse:
        pass

    @abstractmethod
    def update_product(self, product_id: int, company_id: int, product_update: ProductUpdate) -> ProductResponse:
        pass

    @abstractmethod
    def delete_product(self, product_id: int, company_id: int, soft: bool = True) -> bool:
        pass


class ProductService(IProductService):
    """Servicio de gestión de productos"""

    def __init__(self, db: Session):
        self.product_repository = ProductRepository(db)

    def create_product(self, product_create: ProductCreate, company_id: int) -> ProductResponse:
        """Crea un nuevo producto en una empresa"""
        existing_product = self.product_repository.get_by_sku(product_create.sku, company_id)
        if existing_product:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El SKU '{product_create.sku}' ya existe en esta empresa",
            )

        product = Product(
            company_id=company_id,
            sku=product_create.sku,
            name=product_create.name,
            description=product_create.description,
            category=product_create.category,
            price=product_create.price,
            stock=product_create.stock,
        )

        created_product = self.product_repository.create(product)
        return ProductResponse.model_validate(created_product)

    def get_product(self, product_id: int, company_id: int) -> ProductResponse:
        """Obtiene un producto de una empresa"""
        product = self.product_repository.get_by_id(product_id, company_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Producto no encontrado",
            )
        return ProductResponse.model_validate(product)

    def get_all_products(self, company_id: int, filters: ProductFilters) -> PaginatedProductResponse:
        """Obtiene productos de una empresa con filtros avanzados y paginación"""
        products, total = self.product_repository.get_all(
            company_id=company_id,
            skip=filters.skip,
            limit=filters.limit,
            search=filters.search,
            category=filters.category,
            min_price=filters.min_price,
            max_price=filters.max_price,
            in_stock=filters.in_stock,
            is_active=filters.is_active,
            sort_by=filters.sort_by.value,
            sort_order=filters.sort_order.value,
        )

        total_pages = (total + filters.limit - 1) // filters.limit
        page = (filters.skip // filters.limit) + 1

        return PaginatedProductResponse(
            items=[ProductResponse.model_validate(p) for p in products],
            total=total,
            page=page,
            page_size=filters.limit,
            total_pages=total_pages,
        )

    def update_product(self, product_id: int, company_id: int, product_update: ProductUpdate) -> ProductResponse:
        """Actualiza un producto de una empresa"""
        product = self.product_repository.get_by_id(product_id, company_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Producto no encontrado",
            )

        update_data = product_update.model_dump(exclude_unset=True)
        updated_product = self.product_repository.update(product_id, company_id, **update_data)

        return ProductResponse.model_validate(updated_product)

    def delete_product(self, product_id: int, company_id: int, soft: bool = True) -> bool:
        """Elimina un producto de una empresa (soft delete por defecto)"""
        if soft:
            return self.product_repository.soft_delete(product_id, company_id)
        else:
            return self.product_repository.delete(product_id, company_id)
