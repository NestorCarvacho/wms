# WMS - Esquema de Base de Datos Completo

**Versión:** 2.1  
**Motor:** MySQL 8.0+  
**Tabla de Primarias:** BIGINT AUTO_INCREMENT  
**Charset:** utf8mb4 (soporte completo Unicode)  

---

## 📋 Tabla de Contenidos

1. [Tablas Núcleo](#tablas-núcleo)
2. [Tablas de Gestión](#tablas-de-gestión)
3. [Tablas de Operaciones](#tablas-de-operaciones)
4. [Tablas de Auditoría](#tablas-de-auditoría)
5. [Vistas Útiles](#vistas-útiles)
6. [Flujos de Datos](#flujos-de-datos)
7. [Datos Iniciales](#datos-iniciales)

---

## Tablas Núcleo

### 1. **USERS** - Usuarios del Sistema
Gestión de usuarios y autenticación.
- Roles: `admin`, `manager`, `operator`, `viewer`
- Contraseñas encriptadas con bcrypt
- Auditoría de creación/actualización

**Campos principales:**
- `email` (UNIQUE)
- `role` (ENUM)
- `is_active` (BOOLEAN)

---

### 2. **PRODUCT_CATEGORIES** - Categorías de Productos
Clasificación de productos.

**Campos principales:**
- `code` (UNIQUE)
- `name`
- 5 categorías predefinidas: Electrónica, Alimentos, Consumibles, Ropa, Muebles

---

### 3. **PRODUCTS** - Productos
Maestro de productos del inventario.

**Campos principales:**
- `sku` (UNIQUE)
- `name`, `description`
- `category_id` (FK)
- Precios: `cost_price`, `selling_price`
- Dimensiones: `weight_kg`, `dimensions_*_cm`, `volume_m3`
- Stock: `minimum_stock`, `maximum_stock`
- `is_perishable`, `expiry_days` para productos perecederos
- 10 productos de ejemplo incluidos

**Índices importantes:**
- `idx_sku` - Búsqueda rápida por código
- `idx_category_id` - Filtrado por categoría
- `idx_products_name_active` - Búsqueda por nombre

---

### 4. **WAREHOUSES** - Almacenes
Ubicaciones de almacenamiento.

**Campos principales:**
- `code` (UNIQUE)
- `name`, `location`
- `capacity_m3` - Capacidad total
- `manager_id` (FK -> users)
- 3 almacenes de ejemplo: Central, Norte, Sur

---

### 5. **WAREHOUSE_ZONES** - Zonas del Almacén
Subdivisiones de almacenes por tipo de operación.

**Tipos de zona:**
- `receiving` - Recepción
- `storage` - Almacenamiento
- `picking` - Preparación de pedidos
- `packing` - Empaque
- `shipping` - Envío
- `returns` - Devoluciones

**6 zonas de ejemplo** para el almacén central.

---

### 6. **SHELVES** - Estantes/Góndolas
Ubicaciones físicas en el almacén.

**Campos principales:**
- `warehouse_id` (FK)
- `code` (UNIQUE por almacén)
- `shelf_type` (rack, gondola, bin, pallet)
- Ubicación: `row_number`, `column_number`, `level_number`
- Capacidad: `capacity_units`, `capacity_weight_kg`

---

## Tablas de Gestión

### 7. **SUPPLIERS** - Proveedores
Maestro de proveedores.

**Campos principales:**
- `code` (UNIQUE)
- Contacto: `email`, `phone`, `address`
- `payment_terms` (ej: Net 30)
- 3 proveedores de ejemplo

---

### 8. **PRODUCT_SUPPLIERS** - Relación Producto-Proveedor
Vinculación flexible entre productos y sus proveedores.

**Campos principales:**
- `product_id`, `supplier_id` (FK)
- `supplier_sku` - SKU del proveedor
- `lead_time_days` - Tiempo de entrega
- `min_order_quantity` - Cantidad mínima
- `unit_price` - Precio unitario
- `is_preferred` - Proveedor preferido

**Nota:** Permite múltiples proveedores por producto.

---

### 9. **CUSTOMERS** - Clientes
Maestro de clientes.

**Campos principales:**
- `code` (UNIQUE)
- `name`, `contact_person`, `email`, `phone`
- `customer_type` (retail, wholesale, distributor, internal)
- 3 clientes de ejemplo

---

### 10. **INVENTORY** - Inventario Central
Stock agregado por almacén y producto.

**Campos principales:**
- `warehouse_id`, `product_id` (FK, UNIQUE kombinado)
- `quantity` - Stock físico
- `reserved_quantity` - Reservado por órdenes
- `available_quantity` - **GENERADA**: quantity - reserved_quantity
- `last_counted_at` - Auditoría

**Nota:** Vista materializada del stock disponible.

---

### 11. **PRODUCT_BATCHES** - Lotes de Productos
Rastreo de lotes/series para trazabilidad.

**Campos principales:**
- `product_id`, `warehouse_id`, `supplier_id` (FK)
- `batch_number` (UNIQUE por producto+almacén)
- `manufacture_date`, `expiry_date`
- `quantity_received`, `quantity_available`
- `purchase_order_id` (FK)

**Uso:** FIFO/FEFO, trazabilidad, productos perecederos.

---

## Tablas de Operaciones

### 12. **PURCHASE_ORDERS** - Órdenes de Compra
Órdenes a proveedores.

**Estados:**
- `draft` → `sent` → `confirmed` → `received` → `cancelled`

**Campos principales:**
- `po_number` (UNIQUE)
- `supplier_id`, `warehouse_id` (FK)
- Fechas: `expected_delivery_date`, `actual_delivery_date`
- `total_amount`
- `created_by` (FK -> users)

---

### 13. **PURCHASE_ORDER_DETAILS** - Detalles de Compra
Líneas de artículos en órdenes de compra.

**Campos principales:**
- `purchase_order_id`, `product_id` (FK)
- `quantity_ordered`, `quantity_received`
- `unit_price`
- `line_total` - **GENERADA**: quantity_ordered * unit_price

---

### 14. **SALES_ORDERS** - Órdenes de Venta
Órdenes de clientes.

**Estados:**
- `draft` → `confirmed` → `picking` → `packed` → `shipped` → `delivered` → `cancelled`

**Campos principales:**
- `so_number` (UNIQUE)
- `customer_id`, `warehouse_id` (FK)
- `order_date`, `delivery_date`
- `total_amount`
- `created_by` (FK -> users)

---

### 15. **SALES_ORDER_DETAILS** - Detalles de Venta
Líneas de artículos en órdenes de venta.

**Campos principales:**
- `sales_order_id`, `product_id` (FK)
- `quantity_ordered`, `quantity_picked`, `quantity_shipped`
- `unit_price`
- `line_total` - **GENERADA**: quantity_ordered * unit_price

---

### 16. **PICKING_TASKS** - Tareas de Picking
Asignación de tareas para preparación de pedidos.

**Estados:**
- `pending` → `in_progress` → `completed` → `cancelled`

**Campos principales:**
- `sales_order_id`, `warehouse_id`, `product_id`, `shelf_id` (FK)
- `quantity_to_pick`, `quantity_picked`
- `assigned_to`, `picked_by` (FK -> users)
- `picked_at` - Timestamp del picking

---

### 17. **PACKING_TASKS** - Tareas de Empaque
Asignación de tareas para empaque de pedidos.

**Estados:**
- `pending` → `in_progress` → `completed` → `cancelled`

**Campos principales:**
- `sales_order_id`, `warehouse_id` (FK)
- Dimensiones: `weight_kg`, `dimensions_*_cm`
- `assigned_to`, `packed_by` (FK -> users)
- `packed_at` - Timestamp del empaque

---

### 18. **SHIPPING_LABELS** - Etiquetas de Envío
Información de envío y seguimiento.

**Campos principales:**
- `sales_order_id` (FK)
- `tracking_number` (UNIQUE)
- `carrier` - Transportista
- `shipping_method` - Método de envío
- Fechas: `shipped_at`, `estimated_delivery`, `actual_delivery`
- `cost` - Costo de envío

---

### 19. **RETURNS_ORDERS** - Órdenes de Devolución
Gestión de devoluciones de clientes.

**Estados:**
- `draft` → `confirmed` → `received` → `processed` → `credited` → `cancelled`

**Razones:**
- `defective`, `wrong_item`, `damaged`, `not_needed`, `other`

**Campos principales:**
- `return_number` (UNIQUE)
- `sales_order_id`, `customer_id`, `warehouse_id` (FK)
- `return_date`, `received_date`
- `total_amount` - A acreditar

---

### 20. **RETURN_ORDER_DETAILS** - Detalles de Devolución
Líneas de productos devueltos.

**Campos principales:**
- `return_order_id`, `product_id` (FK)
- `quantity`, `unit_price`
- `condition` (new, used, damaged, defective)
- `line_total` - **GENERADA**: quantity * unit_price

---

### 21. **STOCK_MOVEMENTS** - Movimientos de Stock
Historial de todos los movimientos de inventario.

**Tipos de movimiento:**
- `inbound` - Entrada
- `outbound` - Salida
- `adjustment` - Ajuste
- `transfer` - Transferencia
- `damage` - Daño/Merma

**Campos principales:**
- `warehouse_id`, `product_id` (FK)
- `quantity` - Cantidad movida
- `reference_type`, `reference_id` - Origen del movimiento
- `created_by` (FK -> users)
- `created_at` - Fecha del movimiento

**Nota:** Audit trail completo del inventario.

---

### 22. **STOCK_COUNTS** - Conteos de Inventario
Registros de conteos físicos.

**Tipos:**
- `full` - Conteo completo
- `partial` - Conteo parcial
- `spot_check` - Revisión puntual

**Estados:**
- `draft` → `in_progress` → `completed` → `cancelled`

**Campos principales:**
- `warehouse_id` (FK)
- `counted_by` (FK -> users)
- `started_at`, `completed_at`

---

### 23. **STOCK_COUNT_DETAILS** - Detalles de Conteos
Líneas individuales de conteos.

**Campos principales:**
- `stock_count_id`, `product_id`, `shelf_id` (FK)
- `system_quantity` - Lo que dice el sistema
- `counted_quantity` - Lo que se contó
- `variance` - **GENERADA**: counted_quantity - system_quantity

---

### 24. **WAREHOUSE_TRANSFERS** - Transferencias entre Almacenes
Movimientos de stock entre almacenes.

**Estados:**
- `draft` → `sent` → `received` → `cancelled`

**Campos principales:**
- `transfer_number` (UNIQUE)
- `from_warehouse_id`, `to_warehouse_id` (FK)
- Fechas: `transfer_date`, `expected_arrival`, `actual_arrival`
- `created_by` (FK -> users)

---

### 25. **WAREHOUSE_TRANSFER_DETAILS** - Detalles de Transferencias
Líneas de productos transferidos.

**Campos principales:**
- `warehouse_transfer_id`, `product_id` (FK)
- `quantity_sent`, `quantity_received`

---

## Tablas de Auditoría

### 26. **SHELF_PRODUCTS** - Asignación Producto-Estante
Ubicación física de productos en el almacén.

**Campos principales:**
- `shelf_id`, `product_id` (FK, UNIQUE kombinado)
- `position_in_shelf` - Ubicación específica
- `quantity_units` - Cantidad en la ubicación
- `last_updated_at` - Auditoría

---

### 27. **AUDIT_LOG** - Log de Auditoría
Registro completo de cambios en el sistema.

**Campos principales:**
- `user_id` (FK)
- `action` - Acción realizada
- `table_name` - Tabla afectada
- `record_id` - ID del registro
- `old_values`, `new_values` - JSON con valores
- `ip_address` - IP de la acción
- `created_at` - Fecha/hora

---

## Vistas Útiles

### 1. **v_inventory_summary**
Resumen de inventario por producto en todos los almacenes.

```sql
SELECT * FROM v_inventory_summary
WHERE total_available < 10;  -- Stock bajo
```

**Columnas:**
- `id`, `sku`, `name`, `category`
- `total_quantity`, `total_reserved`, `total_available`
- `warehouse_count`

---

### 2. **v_low_stock**
Productos con stock por debajo del mínimo.

```sql
SELECT * FROM v_low_stock
ORDER BY shortage DESC;
```

**Columnas:**
- `sku`, `name`, `category`
- `minimum_stock`, `current_stock`, `shortage`

---

### 3. **v_pending_sales_orders**
Órdenes de venta en proceso.

```sql
SELECT * FROM v_pending_sales_orders
WHERE pending_picks > 0;
```

**Columnas:**
- `so_number`, `customer`, `warehouse`
- `order_status`, `total_amount`
- `picking_tasks`, `pending_picks`

---

### 4. **v_stock_by_location**
Stock por ubicación física (góndola).

```sql
SELECT * FROM v_stock_by_location
WHERE warehouse = 'WH-01';
```

**Columnas:**
- `warehouse`, `zone`, `shelf`, `product`
- `position_in_shelf`, `quantity_units`
- `minimum_stock`, `capacity_units`

---

### 5. **v_product_suppliers**
Proveedores por producto con condiciones.

```sql
SELECT * FROM v_product_suppliers
WHERE is_preferred = TRUE;
```

**Columnas:**
- `sku`, `product`
- `supplier_code`, `supplier`, `supplier_sku`
- `lead_time_days`, `min_order_quantity`, `unit_price`

---

## Flujos de Datos

### 📥 Flujo de Entrada (Compra)

```
1. PURCHASE_ORDER creada
   ↓
2. PURCHASE_ORDER_DETAILS con líneas
   ↓
3. PO enviada a proveedor (po_status = sent)
   ↓
4. Proveedor confirma (po_status = confirmed)
   ↓
5. Mercancía llega al almacén
   ↓
6. Recepción registra en PURCHASE_ORDER_DETAILS (quantity_received)
   ↓
7. PRODUCT_BATCHES creado (si aplica)
   ↓
8. STOCK_MOVEMENTS registra el inbound
   ↓
9. INVENTORY actualizado (quantity +)
   ↓
10. SHELF_PRODUCTS asigna ubicación
    ↓
11. PO marca como received
```

---

### 📦 Flujo de Salida (Venta)

```
1. SALES_ORDER creada
   ↓
2. SALES_ORDER_DETAILS con líneas
   ↓
3. Sistema crea PICKING_TASKS
   ↓
4. Operario asignado recoge (quantity_picked)
   ↓
5. STOCK_MOVEMENTS registra outbound
   ↓
6. INVENTORY actualizado (reserved_quantity +)
   ↓
7. Picking completo → SO status = packed
   ↓
8. Sistema crea PACKING_TASKS
   ↓
9. Operario empaca
   ↓
10. SHIPPING_LABEL creada
    ↓
11. Transportista recoge (shipped_at)
    ↓
12. STOCK_MOVEMENTS finaliza outbound
    ↓
13. INVENTORY actualizado (quantity -)
    ↓
14. Cliente recibe (SO status = delivered)
```

---

### 🔄 Flujo de Transferencia entre Almacenes

```
1. WAREHOUSE_TRANSFER creada
   ↓
2. WAREHOUSE_TRANSFER_DETAILS con líneas
   ↓
3. Almacén origen prepara (status = sent)
   ↓
4. STOCK_MOVEMENTS registra salida (outbound, transfer)
   ↓
5. INVENTORY origen actualizado (quantity -)
   ↓
6. En tránsito
   ↓
7. Almacén destino recibe
   ↓
8. STOCK_MOVEMENTS registra entrada (inbound, transfer)
   ↓
9. INVENTORY destino actualizado (quantity +)
   ↓
10. WAREHOUSE_TRANSFER status = received
```

---

### ↩️ Flujo de Devolución

```
1. RETURNS_ORDER creada
   ↓
2. RETURN_ORDER_DETAILS con líneas
   ↓
3. Cliente envía mercancía
   ↓
4. Almacén recibe (status = received)
   ↓
5. Inspección de condición
   ↓
6. Se registra en PRODUCT_BATCHES (si aplica)
   ↓
7. STOCK_MOVEMENTS registra entrada
   ↓
8. INVENTORY actualizado (quantity +)
   ↓
9. Se calcula acreditación
   ↓
10. Status = credited (dinero devuelto)
```

---

## Datos Iniciales

### ✅ Incluidos

**Usuarios (3):**
- admin@wms.com (admin)
- manager@wms.com (manager)
- operator@wms.com (operator)

**Categorías (5):**
- Electrónica
- Alimentos
- Consumibles
- Ropa
- Muebles

**Almacenes (3):**
- WH-01: Almacén Central
- WH-02: Almacén Norte
- WH-03: Almacén Sur

**Zonas (6):**
- Recepción, Almacenamiento A, Almacenamiento B, Picking A, Empaque, Envío

**Productos (10):**
- Electrónica: Laptop, Monitor, Teclado
- Alimentos: Arroz, Aceite
- Consumibles: Papel, Bolígrafos
- Ropa: Polera, Jeans
- Muebles: Silla

**Proveedores (3):**
- Proveedor Electrónico SA
- Distribuidora de Alimentos
- Importadora Global

**Clientes (3):**
- Tienda Centro (retail)
- Distribuidor Regional (distributor)
- Mayorista Sur (wholesale)

**Inventario:**
- Stock distribuido en 3 almacenes
- Reservas creadas para ejemplos

**Relaciones Producto-Proveedor:**
- 10 vinculaciones (un proveedor por producto)
- Precios, tiempos de entrega, cantidades mínimas

---

## Índices de Optimización

**Búsqueda:**
- SKU, nombre, categoría, proveedor

**Reportes:**
- Fechas de movimientos, estados

**Joins frecuentes:**
- producto-almacén, orden-detalle

**Total: 50+ índices** para máximo rendimiento

---

## Características de Seguridad

✅ **FOREIGN KEY CONSTRAINTS** - Integridad referencial  
✅ **UNIQUE CONSTRAINTS** - Prevención de duplicados  
✅ **SOFT DELETE** - Campo `is_active` en registros  
✅ **AUDIT LOG** - Rastreo completo de cambios  
✅ **STOCK_MOVEMENTS** - Historial de inventario  
✅ **ROLE-BASED** - Tablas preparadas para RBAC  
✅ **TIMESTAMPS** - `created_at`, `updated_at` en todas las tablas  

---

## Uso en Desarrollo

### Iniciar Base de Datos

```bash
mysql -u root -p < database/init_mysql_v2.sql
```

### Verificar Tablas

```sql
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'wms' 
ORDER BY TABLE_NAME;
-- Debe retornar 27 tablas
```

### Consultas Útiles

```sql
-- Stock disponible
SELECT sku, name, available_quantity 
FROM v_inventory_summary 
WHERE total_available > 0;

-- Órdenes pendientes
SELECT so_number, customer, order_status 
FROM v_pending_sales_orders;

-- Stock bajo
SELECT * FROM v_low_stock;

-- Movimientos de hoy
SELECT * FROM stock_movements 
WHERE DATE(created_at) = CURDATE();
```

---

## Próximos Pasos

Ahora puedes enfocarte en implementar los endpoints de la API sin preocuparte por la estructura de datos. La base de datos está **100% lista** para:

- ✅ Gestión de Productos
- ✅ Gestión de Órdenes
- ✅ Gestión de Inventario
- ✅ Gestión de Almacenes
- ✅ Gestión de Proveedores
- ✅ Gestión de Clientes
- ✅ Picking y Packing
- ✅ Devoluciones
- ✅ Reportes y Auditoría

**Total tablas:** 27  
**Total índices:** 50+  
**Datos de ejemplo:** 10 productos + 3 almacenes + 3 usuarios + 3 proveedores + 3 clientes  
**Estado:** ✅ Producción-ready
