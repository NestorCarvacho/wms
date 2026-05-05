# 🚀 Quick Start - WMS API Desarrollo

**Estado:** ✅ Base de datos 100% lista - Enfócate solo en el código

---

## 5 Minutos para Empezar

### 1. Ejecutar Script de Base de Datos (2 min)

```bash
cd wms
mysql -u root -p < database/init_mysql_v2.sql
```

**Resultado esperado:**
```
Query OK. 27 tables created.
3 users inserted.
10 products inserted.
...
```

### 2. Crear archivo `.env` (1 min)

En la raíz del proyecto:
```
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/wms
SECRET_KEY=tu-clave-secreta-jwt
API_PORT=8000
```

### 3. Instalar dependencias (1 min)

```bash
pip install -r requirements.txt
```

### 4. Verificar conexión (1 min)

```bash
python test_db_connection.py
# ✅ Conexión exitosa! Base de datos contiene 3 usuarios
```

### 5. Iniciar API (sin esperar)

```bash
python -m uvicorn app.main:app --reload --port 8000
# Uvicorn running on http://127.0.0.1:8000
```

---

## Base de Datos: Estado Actual

### ✅ Incluido

| Componente | Estado | Detalles |
|-----------|--------|----------|
| **27 Tablas** | ✅ | Todas las funcionalidades del WMS |
| **Índices** | ✅ | 50+ índices de optimización |
| **Vistas** | ✅ | 5 vistas útiles para reportes |
| **Datos Ejemplo** | ✅ | 10 productos + 3 almacenes + usuarios |
| **Relaciones** | ✅ | Foreign keys + constraints |
| **Auditoría** | ✅ | Tablas para rastreo |

### ⚠️ NO Incluido (Tu responsabilidad)

```
❌ Endpoints API
❌ DTOs específicos por módulo
❌ Servicios de negocio
❌ Validaciones de entrada
❌ Autenticación JWT
❌ Tests
```

---

## Estructura de Tablas (27 Total)

### 🏗️ Núcleo (Maestros)
1. `users` - Usuarios
2. `product_categories` - Categorías
3. `products` - Productos
4. `warehouses` - Almacenes
5. `suppliers` - Proveedores
6. `customers` - Clientes

### 📍 Ubicaciones
7. `warehouse_zones` - Zonas
8. `shelves` - Estantes/Góndolas
9. `shelf_products` - Asignación producto-estante

### 📦 Órdenes de Compra
10. `purchase_orders` - Cabecera
11. `purchase_order_details` - Detalles

### 🛒 Órdenes de Venta
12. `sales_orders` - Cabecera
13. `sales_order_details` - Detalles

### 📮 Devoluciones
14. `returns_orders` - Cabecera
15. `return_order_details` - Detalles

### 📊 Inventario
16. `inventory` - Stock por almacén
17. `product_batches` - Lotes
18. `product_suppliers` - Relación producto-proveedor
19. `stock_movements` - Historial de movimientos
20. `stock_counts` - Conteos
21. `stock_count_details` - Detalles de conteos

### 🏃 Operaciones
22. `picking_tasks` - Tareas de picking
23. `packing_tasks` - Tareas de empaque
24. `shipping_labels` - Etiquetas de envío

### 🚚 Transferencias
25. `warehouse_transfers` - Cabecera
26. `warehouse_transfer_details` - Detalles

### 📋 Auditoría
27. `audit_log` - Log de cambios

---

## Datos de Ejemplo Precargados

### 👤 Usuarios (3)
```
admin@wms.com        | admin    | ID: 1
manager@wms.com      | manager  | ID: 2
operator@wms.com     | operator | ID: 3
```

### 📦 Productos (10)
- **Electrónica:** Laptop Dell XPS, Monitor LG 27", Teclado Mecánico
- **Alimentos:** Arroz Premium, Aceite Vegetal
- **Consumibles:** Papel de Impresora, Bolígrafos
- **Ropa:** Polera Algodón, Jeans Azul
- **Muebles:** Silla Oficina

**Stock actual:** 600+ unidades distribuidas en 3 almacenes

### 🏢 Almacenes (3)
```
WH-01  | Almacén Central  | 5000 m³ | Santiago
WH-02  | Almacén Norte    | 2000 m³ | Valparaíso
WH-03  | Almacén Sur      | 2000 m³ | Concepción
```

### 🤝 Proveedores (3)
```
SUP-001 | Proveedor Electrónico SA
SUP-002 | Distribuidora de Alimentos
SUP-003 | Importadora Global
```

### 👥 Clientes (3)
```
CUST-001 | Tienda Centro      | retail
CUST-002 | Distribuidor Reg.  | distributor
CUST-003 | Mayorista Sur      | wholesale
```

---

## Vistas Útiles Disponibles

### 📊 Reportes Listos

```sql
-- Stock por producto (resumen)
SELECT * FROM v_inventory_summary;

-- Stock bajo
SELECT * FROM v_low_stock;

-- Órdenes pendientes
SELECT * FROM v_pending_sales_orders;

-- Stock por ubicación física
SELECT * FROM v_stock_by_location;

-- Proveedores por producto
SELECT * FROM v_product_suppliers;
```

---

## Próximo Desarrollo

### Ejemplo: Crear endpoint de Inventario

Ya tienes todo preparado. Solo crea:

**Archivo:** `app/application/inventory/services.py`
```python
class InventoryService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_inventory(self, warehouse_id: int):
        # La tabla 'inventory' ya existe con todos los datos
        return self.db.query(Inventory).filter(...).all()
```

**Archivo:** `app/interfaces/inventory/controllers.py`
```python
@router.get("/warehouses/{warehouse_id}/inventory")
async def get_inventory(warehouse_id: int, db: Session = Depends(get_db)):
    service = InventoryService(db)
    return service.get_inventory(warehouse_id)
```

**Eso es todo.** La base de datos, las relaciones y los datos ya están listos.

---

## Estructura Esperada del Proyecto

```
wms/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── core/
│   │   ├── security.py
│   │   └── config.py
│   ├── infrastructure/
│   │   ├── database.py
│   │   └── products/
│   │       └── repositories.py
│   ├── application/
│   │   ├── products/
│   │   │   ├── services.py
│   │   │   └── dto.py
│   │   ├── inventory/
│   │   │   ├── services.py
│   │   │   └── dto.py
│   │   └── ... (otros módulos)
│   ├── domain/
│   │   ├── products/
│   │   │   └── models.py
│   │   ├── inventory/
│   │   │   └── models.py
│   │   └── ... (otros módulos)
│   └── interfaces/
│       ├── products/
│       │   └── controllers.py
│       ├── inventory/
│       │   └── controllers.py
│       └── ... (otros módulos)
├── database/
│   └── init_mysql_v2.sql     ← Script que ejecutaste
├── tests/
│   └── test_*.py
├── .env                       ← Tu configuración
├── requirements.txt
├── DATABASE_SCHEMA.md         ← Documentación de tablas
├── DATABASE_SETUP.md          ← Guía de setup
└── QUICK_START.md             ← Este archivo
```

---

## Documentación de Referencia

Tienes 3 documentos disponibles:

### 📄 DATABASE_SCHEMA.md
Descripción **completa** de:
- Todas las 27 tablas
- Campos y tipos
- Flujos de datos
- Vistas disponibles
- Ejemplos de queries

**Usa cuando:** Necesites entender la estructura

### 📄 DATABASE_SETUP.md
Instrucciones de:
- Instalación paso a paso
- Troubleshooting
- Backup/Restore
- Scripts útiles

**Usa cuando:** Tengas problemas de conexión

### 📄 QUICK_START.md
Este archivo - resumen ejecutivo

**Usa cuando:** Necesites recordar qué viene después

---

## Test de Datos

### Verificar que todo se instaló

```sql
-- Conectarte a MySQL
mysql -u root -p wms

-- Contar registros
SELECT COUNT(*) as total_tables FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='wms';
-- Resultado: 27

SELECT COUNT(*) FROM products;
-- Resultado: 10

SELECT COUNT(*) FROM inventory;
-- Resultado: 14

SELECT SUM(quantity) as total_stock FROM inventory;
-- Resultado: 615 unidades
```

### Query útil para desarrollo

```sql
-- Ver un producto con su inventario en todos los almacenes
SELECT 
    p.sku,
    p.name,
    w.code as warehouse,
    i.quantity,
    i.reserved_quantity,
    i.available_quantity
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
LEFT JOIN warehouses w ON i.warehouse_id = w.id
WHERE p.sku = 'PROD-001'
ORDER BY w.code;
```

---

## Checklist Antes de Empezar

- [ ] MySQL instalado y corriendo
- [ ] Script `init_mysql_v2.sql` ejecutado
- [ ] 27 tablas creadas
- [ ] Archivo `.env` creado con DATABASE_URL
- [ ] Conexión desde Python verificada
- [ ] FastAPI y SQLAlchemy instalados
- [ ] API inicia sin errores

---

## ¿Problemas?

### "Cannot connect to MySQL"
```bash
# Verificar que MySQL está corriendo
mysql -u root -p -e "SELECT 1"
```

### "Table doesn't exist"
```bash
# Verificar que el script se ejecutó completamente
mysql -u root -p wms -e "SHOW TABLES;"
# Debe listar 27 tablas
```

### "Foreign key constraint fails"
Asegurar que todas las tablas se crearon en el orden correcto. El script maneja esto automáticamente.

---

## 🎯 Enfoque

**Ya completado:**
- ✅ Estructura de base de datos
- ✅ Datos de ejemplo
- ✅ Índices de optimización
- ✅ Vistas de reportes
- ✅ Relaciones y constraints
- ✅ Auditoría y trazabilidad

**Tu trabajo (ya listo para empezar):**
- 🎯 Endpoints API por módulo
- 🎯 Validaciones de negocio
- 🎯 Autenticación y autorización
- 🎯 Tests unitarios
- 🎯 Documentación de API

**La base de datos NO necesita cambios.** Está lista para producción.

---

## Pasos Siguientes

1. Ejecuta el script SQL ← **HAZLO AHORA**
2. Crea el `.env`
3. Verifica conexión
4. Abre `DATABASE_SCHEMA.md` para entender tablas
5. Comienza con módulo de Inventario (más simple)
6. Luego Órdenes de Compra
7. Luego Órdenes de Venta
8. Luego Picking/Packing
9. Luego Devoluciones
10. Reportes y Auditoría

---

**¡La base está lista! 🚀**

Enfócate en el código, no en la base de datos.

