from abc import ABC, abstractmethod
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session

from app.domain.products import Product


class IProductRepository(ABC):
    """Interface para repositorio de productos"""

    @abstractmethod
    def create(self, product: Product) -> Product:
        pass

    @abstractmethod
    def get_by_id(self, product_id: int, company_id: int) -> Optional[Product]:
        pass

    @abstractmethod
    def get_by_sku(self, sku: str, company_id: int) -> Optional[Product]:
        pass

    @abstractmethod
    def get_all(self, company_id: int, skip: int = 0, limit: int = 100, category: Optional[str] = None, name: Optional[str] = None) -> Tuple[List[Product], int]:
        pass

    @abstractmethod
    def update(self, product_id: int, company_id: int, **kwargs) -> Optional[Product]:
        pass

    @abstractmethod
    def delete(self, product_id: int, company_id: int) -> bool:
        pass

    @abstractmethod
    def soft_delete(self, product_id: int, company_id: int) -> bool:
        pass


class ProductRepository(IProductRepository):
    """Implementación de repositorio de productos"""

    def __init__(self, db: Session):
        self.db = db

    def create(self, product: Product) -> Product:
        """Crea un nuevo producto"""
        self.db.add(product)
        self.db.commit()
        self.db.refresh(product)
        return product

    def get_by_id(self, product_id: int, company_id: int) -> Optional[Product]:
        """Obtiene producto por ID y empresa"""
        return self.db.query(Product).filter(
            Product.id == product_id,
            Product.company_id == company_id,
            Product.is_active == True
        ).first()

    def get_by_sku(self, sku: str, company_id: int) -> Optional[Product]:
        """Obtiene producto por SKU y empresa"""
        return self.db.query(Product).filter(
            Product.sku == sku,
            Product.company_id == company_id
        ).first()

    def get_all(
        self,
        company_id: int,
        skip: int = 0,
        limit: int = 100,
        search: Optional[str] = None,
        category: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        in_stock: Optional[bool] = None,
        is_active: bool = True,
        sort_by: str = "name",
        sort_order: str = "asc"
    ) -> Tuple[List[Product], int]:
        """Obtiene productos de una empresa con filtros avanzados y paginación"""
        query = self.db.query(Product).filter(Product.company_id == company_id)

        # Filtro de estado
        if is_active is not None:
            query = query.filter(Product.is_active == is_active)

        # Búsqueda por nombre o descripción
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                (Product.name.ilike(search_term)) |
                (Product.description.ilike(search_term)) |
                (Product.sku.ilike(search_term))
            )

        # Filtro por categoría
        if category:
            query = query.filter(Product.category.ilike(f"%{category}%"))

        # Filtro por rango de precio
        if min_price is not None:
            query = query.filter(Product.price >= min_price)

        if max_price is not None:
            query = query.filter(Product.price <= max_price)

        # Filtro por stock disponible
        if in_stock:
            query = query.filter(Product.stock > 0)

        # Contar total antes de aplicar ordenamiento y paginación
        total = query.count()

        # Ordenamiento
        if sort_by == "name":
            order_column = Product.name
        elif sort_by == "price":
            order_column = Product.price
        elif sort_by == "stock":
            order_column = Product.stock
        elif sort_by == "created_at":
            order_column = Product.created_at
        else:
            order_column = Product.name

        if sort_order.lower() == "desc":
            query = query.order_by(order_column.desc())
        else:
            query = query.order_by(order_column.asc())

        # Paginación
        products = query.offset(skip).limit(limit).all()

        return products, total

    def update(self, product_id: int, company_id: int, **kwargs) -> Optional[Product]:
        """Actualiza un producto de una empresa"""
        product = self.get_by_id(product_id, company_id)
        if not product:
            return None

        for key, value in kwargs.items():
            if value is not None and hasattr(product, key):
                setattr(product, key, value)

        self.db.commit()
        self.db.refresh(product)
        return product

    def delete(self, product_id: int, company_id: int) -> bool:
        """Elimina un producto de una empresa (hard delete)"""
        product = self.get_by_id(product_id, company_id)
        if not product:
            return False

        self.db.delete(product)
        self.db.commit()
        return True

    def soft_delete(self, product_id: int, company_id: int) -> bool:
        """Elimina un producto de una empresa (soft delete - marca como inactivo)"""
        product = self.get_by_id(product_id, company_id)
        if not product:
            return False

        product.is_active = False
        self.db.commit()
        return True
