from abc import ABC, abstractmethod
from typing import Optional, List
from sqlalchemy.orm import Session

from app.domain.models import User

class IUserRepository(ABC):
    """Interface para repositorio de usuarios"""

    @abstractmethod
    def create(self, user: User) -> User:
        pass

    @abstractmethod
    def get_by_id(self, user_id: int) -> Optional[User]:
        pass

    @abstractmethod
    def get_by_email(self, email: str) -> Optional[User]:
        pass

    @abstractmethod
    def get_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        pass

    @abstractmethod
    def update(self, user_id: int, **kwargs) -> Optional[User]:
        pass

    @abstractmethod
    def delete(self, user_id: int) -> bool:
        pass

class UserRepository(IUserRepository):
    """Implementación de repositorio de usuarios"""

    def __init__(self, db: Session):
        self.db = db

    def create(self, user: User) -> User:
        """Crea un nuevo usuario"""
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_id(self, user_id: int) -> Optional[User]:
        """Obtiene usuario por ID"""
        return self.db.query(User).filter(User.id == user_id).first()

    def get_by_email(self, email: str) -> Optional[User]:
        """Obtiene usuario por email"""
        return self.db.query(User).filter(User.email == email).first()

    def get_all(self, skip: int = 0, limit: int = 100) -> List[User]:
        """Obtiene todos los usuarios con paginación"""
        return self.db.query(User).offset(skip).limit(limit).all()

    def update(self, user_id: int, **kwargs) -> Optional[User]:
        """Actualiza un usuario"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        for key, value in kwargs.items():
            if value is not None and hasattr(user, key):
                setattr(user, key, value)

        self.db.commit()
        self.db.refresh(user)
        return user

    def delete(self, user_id: int) -> bool:
        """Elimina un usuario"""
        user = self.get_by_id(user_id)
        if not user:
            return False

        self.db.delete(user)
        self.db.commit()
        return True
