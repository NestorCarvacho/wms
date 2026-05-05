# 🗄️ Guía de Setup - Base de Datos WMS

## Paso 1: Requisitos

- MySQL 8.0 o superior
- Usuario con permisos de crear bases de datos (ej: `root`)

Verificar versión:
```bash
mysql --version
# Resultado esperado: mysql Ver 8.0.x
```

---

## Paso 2: Crear Base de Datos Limpia (Opcional)

Si la base de datos ya existe y quieres empezar de cero:

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS wms; CREATE DATABASE wms;"
```

O conectado a MySQL:
```sql
DROP DATABASE IF EXISTS wms;
CREATE DATABASE wms;
USE wms;
```

---

## Paso 3: Ejecutar Script de Inicialización

**Opción A: Desde línea de comandos**

```bash
# Con contraseña en el comando
mysql -u root -p'tu_contraseña' < database/init_mysql_v2.sql

# Sin especificar contraseña (te pedirá)
mysql -u root -p < database/init_mysql_v2.sql
```

**Opción B: Desde cliente MySQL**

```bash
mysql -u root -p
```

Dentro de MySQL:
```sql
USE wms;
SOURCE /ruta/completa/database/init_mysql_v2.sql;
```

**Opción C: Desde DBeaver, MySQL Workbench, etc.**
1. Crear conexión a MySQL
2. Crear base de datos `wms`
3. Click derecho → Run SQL Script → Seleccionar `init_mysql_v2.sql`

---

## Paso 4: Verificar Instalación

```bash
mysql -u root -p -e "USE wms; SHOW TABLES;"
```

**Resultado esperado:** 27 tablas (in order)

```
audit_log
customers
inventory
output ↓
```

**Contar tablas:**
```sql
SELECT COUNT(*) as total_tables
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'wms';
-- Debe retornar: 27
```

---

## Paso 5: Verificar Datos de Ejemplo

```sql
-- Usuarios
SELECT COUNT(*) FROM users;  -- 3

-- Categorías
SELECT COUNT(*) FROM product_categories;  -- 5

-- Almacenes
SELECT COUNT(*) FROM warehouses;  -- 3

-- Productos
SELECT COUNT(*) FROM products;  -- 10

-- Inventario
SELECT COUNT(*) FROM inventory;  -- 14 registros
```

---

## Paso 6: Configurar Conexión en Python/FastAPI

### Archivo: `.env` (en la raíz del proyecto)

```env
# Base de Datos
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/wms

# O con MySQL driver nativo
# DATABASE_URL=mysql+mysqlconnector://root:password@localhost:3306/wms
```

### Archivo: `app/infrastructure/database.py`

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://root:password@localhost:3306/wms")

engine = create_engine(
    DATABASE_URL,
    echo=False,  # Cambiar a True para ver queries SQL
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
    pool_pre_ping=True  # Verificar conexión antes de usar
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## Paso 7: Instalar Dependencias Python

```bash
pip install fastapi sqlalchemy pymysql python-dotenv
```

O con versiones específicas:
```bash
pip install fastapi==0.104.1 sqlalchemy==2.0.23 pymysql==1.1.0 python-dotenv==1.0.0
```

---

## Conexión de Prueba

### Script: `test_db_connection.py`

```python
from sqlalchemy import create_engine, text

DATABASE_URL = "mysql+pymysql://root:password@localhost:3306/wms"

try:
    engine = create_engine(DATABASE_URL)
    with engine.connect() as connection:
        result = connection.execute(text("SELECT COUNT(*) FROM users"))
        count = result.fetchone()[0]
        print(f"✅ Conexión exitosa! Base de datos contiene {count} usuarios")
except Exception as e:
    print(f"❌ Error de conexión: {e}")
```

Ejecutar:
```bash
python test_db_connection.py
```

---

## Solución de Problemas

### Error: "Access denied for user 'root'@'localhost'"

Verificar contraseña:
```bash
mysql -u root -p'tu_contraseña' -e "SELECT VERSION();"
```

### Error: "Unknown database 'wms'"

Crear base de datos:
```bash
mysql -u root -p -e "CREATE DATABASE wms;"
```

### Error: "Foreign key constraint fails"

Asegurar que se ejecutó el script completo. El script desactiva y reactiva las FKs al inicio y final.

### Verificar que se ejecutó completo

```sql
USE wms;

-- Debe retornar 3
SELECT COUNT(*) FROM product_categories WHERE code IN ('ELEC', 'ALIM', 'CONS');

-- Debe retornar 3
SELECT COUNT(*) FROM users WHERE email IN ('admin@wms.com', 'manager@wms.com', 'operator@wms.com');

-- Debe retornar 10
SELECT COUNT(*) FROM products;
```

---

## Limpiar Datos (Mantener Estructura)

Si necesitas limpiar la base de datos pero mantener las tablas:

```sql
-- Deshabilitar restricciones de llave foránea temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- Truncar todas las tablas (eliminar datos, resetear AUTO_INCREMENT)
TRUNCATE TABLE audit_log;
TRUNCATE TABLE return_order_details;
TRUNCATE TABLE returns_orders;
TRUNCATE TABLE warehouse_transfer_details;
TRUNCATE TABLE warehouse_transfers;
TRUNCATE TABLE product_batches;
TRUNCATE TABLE stock_count_details;
TRUNCATE TABLE stock_counts;
TRUNCATE TABLE shipping_labels;
TRUNCATE TABLE packing_tasks;
TRUNCATE TABLE picking_tasks;
TRUNCATE TABLE stock_movements;
TRUNCATE TABLE sales_order_details;
TRUNCATE TABLE sales_orders;
TRUNCATE TABLE purchase_order_details;
TRUNCATE TABLE purchase_orders;
TRUNCATE TABLE product_suppliers;
TRUNCATE TABLE shelf_products;
TRUNCATE TABLE inventory;
TRUNCATE TABLE suppliers;
TRUNCATE TABLE customers;
TRUNCATE TABLE product_batches;
TRUNCATE TABLE shelves;
TRUNCATE TABLE warehouse_zones;
TRUNCATE TABLE warehouses;
TRUNCATE TABLE products;
TRUNCATE TABLE product_categories;
TRUNCATE TABLE users;

-- Reabilitar restricciones
SET FOREIGN_KEY_CHECKS = 1;
```

---

## Respaldar Base de Datos

### Crear backup

```bash
mysqldump -u root -p wms > backup_wms_$(date +%Y%m%d_%H%M%S).sql
```

### Restaurar desde backup

```bash
mysql -u root -p wms < backup_wms_20240101_120000.sql
```

---

## Estructura de Directorios Esperada

```
wms/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── infrastructure/
│   │   ├── __init__.py
│   │   └── database.py
│   └── ...
├── database/
│   └── init_mysql_v2.sql  ← Script que acabas de ejecutar
├── .env                     ← Configuración local
└── test_db_connection.py    ← Script de prueba
```

---

## Siguiente Paso

Una vez la base de datos esté lista, puedes:

1. ✅ **Ya completado:** Base de datos configurada con 27 tablas
2. ✅ **Ya completado:** Datos de ejemplo listos
3. 🎯 **Ahora:** Codear endpoints en FastAPI sin preocuparte por la estructura

Todos los DTOs, Modelos y Servicios están listos para usarse con esta estructura de BD.

---

## Información de Contacto para Queries

### Para ver toda la estructura en una vistazo

```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'wms'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

### Ver índices

```sql
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'wms'
ORDER BY TABLE_NAME, INDEX_NAME;
```

### Ver relaciones (Foreign Keys)

```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'wms' 
AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

## ✅ Checklist de Verificación

- [ ] MySQL 8.0+ instalado
- [ ] Base de datos creada: `wms`
- [ ] Script ejecutado sin errores
- [ ] 27 tablas creadas
- [ ] Datos de ejemplo insertados
- [ ] Conexión desde Python verificada
- [ ] `.env` configurado
- [ ] Dependencias Python instaladas
- [ ] Listo para empezar a codear 🚀

---

## 📚 Documentación Relacionada

- `DATABASE_SCHEMA.md` - Descripción completa de todas las tablas
- `init_mysql_v2.sql` - Script SQL completo
- `API_SEARCH_FILTERS.md` - Documentación de endpoints de búsqueda

