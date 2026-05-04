"""Script para inicializar la base de datos con datos de ejemplo"""

from app.infrastructure.database import SessionLocal, init_db
from app.domain.models import User, RoleEnum
from app.core.security import SecurityService


def setup_database():
    """Inicializa la BD y crea usuarios de ejemplo"""
    print("🔄 Inicializando base de datos...")
    init_db()
    print("✅ Base de datos creada")

    db = SessionLocal()

    # Verificar si ya existen usuarios
    existing_admin = db.query(User).filter(User.email == "admin@wms.com").first()
    if existing_admin:
        print("⚠️  Usuario admin ya existe")
        db.close()
        return

    # Crear usuarios de ejemplo
    users_data = [
        {
            "email": "admin@wms.com",
            "full_name": "Administrador",
            "password": "Admin@123",
            "role": RoleEnum.ADMIN,
        },
        {
            "email": "manager@wms.com",
            "full_name": "Gerente de Almacén",
            "password": "Manager@123",
            "role": RoleEnum.MANAGER,
        },
        {
            "email": "operator@wms.com",
            "full_name": "Operador",
            "password": "Operator@123",
            "role": RoleEnum.OPERATOR,
        },
        {
            "email": "viewer@wms.com",
            "full_name": "Visualizador",
            "password": "Viewer@123",
            "role": RoleEnum.VIEWER,
        },
    ]

    for user_data in users_data:
        user = User(
            email=user_data["email"],
            full_name=user_data["full_name"],
            hashed_password=SecurityService.hash_password(user_data["password"]),
            role=user_data["role"],
            is_active=True,
        )
        db.add(user)
        print(f"✅ Usuario creado: {user_data['email']} (Rol: {user_data['role'].value})")

    db.commit()
    db.close()
    print("\n✨ Base de datos lista para usar")
    print("\n📝 Usuarios de ejemplo:")
    for user_data in users_data:
        print(f"   Email: {user_data['email']}")
        print(f"   Password: {user_data['password']}")
        print()


if __name__ == "__main__":
    setup_database()
