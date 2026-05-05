from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.infrastructure.database import get_db
from app.application.services import AuthService, UserService
from app.core.security import get_current_user
from app.application.dto import (
    LoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    UserCreate,
    UserResponse,
    UserUpdate,
    SuccessResponse,
)

# Routers
auth_router = APIRouter(prefix="/auth", tags=["Authentication"])
user_router = APIRouter(prefix="/users", tags=["Users"])

# ============ Auth Endpoints ============

@auth_router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Login de usuario",
    description="Autentica un usuario y devuelve access y refresh tokens",
    responses={
        200: {
            "description": "Login exitoso",
            "content": {
                "application/json": {
                    "example": {
                        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                        "token_type": "bearer",
                        "expires_in": 1800,
                        "company_id": 1
                    }
                }
            }
        },
        401: {"description": "Credenciales inválidas"},
    }
)
async def login(
    credentials: LoginRequest,
    db: Session = Depends(get_db)
) -> TokenResponse:
    """
    Autentica un usuario con email y contraseña

    - **email**: Email del usuario
    - **password**: Contraseña del usuario

    Devuelve tokens JWT para acceder a recursos protegidos
    """
    auth_service = AuthService(db)
    access_token, refresh_token, expires_in, company_id = auth_service.login(
        credentials.email, credentials.password
    )

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        company_id=company_id
    )

@auth_router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Refrescar access token",
    description="Genera un nuevo access token usando un refresh token",
)
async def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db)
) -> TokenResponse:
    """
    Refresca el access token usando un refresh token válido

    - **refresh_token**: Token de refresco previamente obtenido
    """
    from app.core.security import SecurityService

    auth_service = AuthService(db)
    access_token, expires_in = auth_service.refresh_access_token(request.refresh_token)

    payload = SecurityService.verify_token(request.refresh_token)
    company_id = payload.get("company_id")

    return TokenResponse(
        access_token=access_token,
        refresh_token=request.refresh_token,
        expires_in=expires_in,
        company_id=company_id
    )

# ============ User Endpoints ============

@user_router.post(
    "",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Crear nuevo usuario",
    description="Crea un nuevo usuario en el sistema",
)
async def create_user(
    user_create: UserCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> UserResponse:
    """
    Crea un nuevo usuario (solo administradores)

    - **email**: Email único del usuario
    - **full_name**: Nombre completo
    - **password**: Contraseña (mínimo 6 caracteres)
    - **role**: Rol del usuario (admin, manager, operator, viewer)
    """
    user_service = UserService(db)
    company_id = current_user.get("company_id")
    return user_service.create_user(user_create, company_id)

@user_router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Obtener usuario actual",
    description="Retorna los datos del usuario autenticado",
)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Obtiene información del usuario actualmente autenticado
    """
    user_service = UserService(db)
    company_id = current_user.get("company_id")
    return user_service.get_user(int(current_user["user_id"]), company_id)

@user_router.get(
    "/{user_id}",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Obtener usuario por ID",
    description="Retorna los datos de un usuario específico",
)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> UserResponse:
    """
    Obtiene un usuario específico por su ID
    """
    user_service = UserService(db)
    company_id = current_user.get("company_id")
    return user_service.get_user(user_id, company_id)

@user_router.put(
    "/{user_id}",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Actualizar usuario",
    description="Actualiza los datos de un usuario",
)
async def update_user(
    user_id: int,
    user_update: UserUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> UserResponse:
    """
    Actualiza un usuario (solo el propietario o administradores)
    """
    user_service = UserService(db)
    company_id = current_user.get("company_id")
    return user_service.update_user(user_id, company_id, user_update)

@user_router.delete(
    "/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Eliminar usuario",
    description="Elimina un usuario del sistema",
)
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Elimina un usuario (solo administradores)
    """
    user_service = UserService(db)
    company_id = current_user.get("company_id")
    user_repo = user_service.user_repository
    if not user_repo.delete(user_id, company_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
