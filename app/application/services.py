from abc import ABC, abstractmethod
from datetime import timedelta
from typing import Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.domain.models import User, RoleEnum
from app.infrastructure.repositories import UserRepository
from app.core.security import SecurityService
from app.core.config import settings
from app.application.dto import UserCreate, UserUpdate, UserResponse

class IAuthService(ABC):
    """Interface para servicio de autenticación"""

    @abstractmethod
    def login(self, email: str, password: str) -> Tuple[str, str, int]:
        pass

    @abstractmethod
    def refresh_access_token(self, refresh_token: str) -> str:
        pass

class AuthService(IAuthService):
    """Servicio de autenticación con JWT"""

    def __init__(self, db: Session):
        self.user_repository = UserRepository(db)

    def login(self, email: str, password: str) -> Tuple[str, str, int, int]:
        """
        Autentica un usuario y devuelve tokens JWT

        Returns:
            Tuple de (access_token, refresh_token, expires_in, company_id)
        """
        user = self.user_repository.get_by_email(email, company_id=None)

        if not user or not SecurityService.verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Email o contraseña incorrectos",
            )

        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Usuario inactivo",
            )

        access_token = SecurityService.create_token(
            data={
                "sub": str(user.id),
                "email": user.email,
                "role": user.role,
                "company_id": user.company_id
            },
            token_type="access"
        )

        refresh_token = SecurityService.create_token(
            data={
                "sub": str(user.id),
                "email": user.email,
                "company_id": user.company_id
            },
            token_type="refresh"
        )

        return access_token, refresh_token, settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60, user.company_id

    def refresh_access_token(self, refresh_token: str) -> Tuple[str, int]:
        """
        Genera un nuevo access token usando un refresh token

        Returns:
            Tuple de (access_token, expires_in)
        """
        payload = SecurityService.verify_token(refresh_token)

        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token de refresco inválido",
            )

        user_id = int(payload.get("sub"))
        company_id = payload.get("company_id")
        user = self.user_repository.get_by_id(user_id, company_id)

        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario no válido",
            )

        access_token = SecurityService.create_token(
            data={
                "sub": str(user.id),
                "email": user.email,
                "role": user.role,
                "company_id": user.company_id
            },
            token_type="access"
        )

        return access_token, settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60

class IUserService(ABC):
    """Interface para servicio de usuarios"""

    @abstractmethod
    def create_user(self, user_create: UserCreate, company_id: int) -> UserResponse:
        pass

    @abstractmethod
    def get_user(self, user_id: int, company_id: int) -> UserResponse:
        pass

    @abstractmethod
    def update_user(self, user_id: int, company_id: int, user_update: UserUpdate) -> UserResponse:
        pass

class UserService(IUserService):
    """Servicio de gestión de usuarios"""

    def __init__(self, db: Session):
        self.user_repository = UserRepository(db)

    def create_user(self, user_create: UserCreate, company_id: int) -> UserResponse:
        """Crea un nuevo usuario en una empresa"""
        existing_user = self.user_repository.get_by_email(user_create.email, company_id)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El email ya está registrado en esta empresa",
            )

        hashed_password = SecurityService.hash_password(user_create.password)

        user = User(
            company_id=company_id,
            email=user_create.email,
            full_name=user_create.full_name,
            hashed_password=hashed_password,
            role=RoleEnum(user_create.role),
        )

        created_user = self.user_repository.create(user)
        return UserResponse.from_orm(created_user)

    def get_user(self, user_id: int, company_id: int) -> UserResponse:
        """Obtiene un usuario de una empresa"""
        user = self.user_repository.get_by_id(user_id, company_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )
        return UserResponse.from_orm(user)

    def update_user(self, user_id: int, company_id: int, user_update: UserUpdate) -> UserResponse:
        """Actualiza un usuario de una empresa"""
        user = self.user_repository.get_by_id(user_id, company_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado",
            )

        update_data = user_update.dict(exclude_unset=True)
        updated_user = self.user_repository.update(user_id, company_id, **update_data)

        return UserResponse.from_orm(updated_user)
