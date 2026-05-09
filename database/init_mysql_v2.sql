-- ============================================
-- WMS API - Database Schema (MySQL) v2.0
-- Diseño normalizado para Sistema de Gestión de Almacén
-- AUTOINCREMENT: Todos los IDs se autoincrementan automáticamente
-- ============================================

-- ============================================
-- DROP TABLES / VIEWS IF EXISTS
-- WMS API - Cleanup Script
-- ============================================

SET FOREIGN_KEY_CHECKS=0;

-- ============================================
-- DROP VIEWS
-- ============================================

DROP VIEW IF EXISTS v_product_suppliers;
DROP VIEW IF EXISTS v_stock_by_location;
DROP VIEW IF EXISTS v_pending_sales_orders;
DROP VIEW IF EXISTS v_low_stock;
DROP VIEW IF EXISTS v_inventory_summary;

-- ============================================
-- DROP TABLES (orden inverso por FK)
-- ============================================

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS return_order_details;
DROP TABLE IF EXISTS returns_orders;
DROP TABLE IF EXISTS shipping_labels;
DROP TABLE IF EXISTS packing_tasks;
DROP TABLE IF EXISTS warehouse_zones;
DROP TABLE IF EXISTS product_suppliers;
DROP TABLE IF EXISTS warehouse_transfer_details;
DROP TABLE IF EXISTS warehouse_transfers;
DROP TABLE IF EXISTS product_batches;
DROP TABLE IF EXISTS stock_count_details;
DROP TABLE IF EXISTS stock_counts;
DROP TABLE IF EXISTS picking_tasks;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS sales_order_details;
DROP TABLE IF EXISTS sales_orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS purchase_order_details;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS shelf_products;
DROP TABLE IF EXISTS shelves;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS companies;

SET FOREIGN_KEY_CHECKS=1;

-- Configuración de sesión
SET FOREIGN_KEY_CHECKS=0;

-- ============================================
-- 0. COMPANIES - Empresas
-- ============================================
CREATE TABLE companies (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la empresa',
    code VARCHAR(50) UNIQUE NOT NULL COMMENT 'Código único de la empresa (ej: EMP-01)',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre de la empresa',
    tax_id VARCHAR(50) COMMENT 'RUT/NIF/Tax ID',
    address TEXT COMMENT 'Dirección',
    phone VARCHAR(50) COMMENT 'Teléfono',
    email VARCHAR(255) COMMENT 'Email',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Empresa activa/inactiva',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    INDEX idx_code (code),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 1. USERS - Usuarios del Sistema
-- ============================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del usuario',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    email VARCHAR(255) NOT NULL COMMENT 'Email del usuario',
    full_name VARCHAR(255) NOT NULL COMMENT 'Nombre completo del usuario',
    hashed_password VARCHAR(255) NOT NULL COMMENT 'Contraseña encriptada con bcrypt',
    role ENUM('admin', 'manager', 'operator', 'viewer') DEFAULT 'viewer' NOT NULL COMMENT 'Rol del usuario',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Usuario activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    INDEX idx_company_id (company_id),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_email_company (email, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 2. WAREHOUSES - Almacenes
-- ============================================
CREATE TABLE warehouses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del almacén',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    code VARCHAR(50) NOT NULL COMMENT 'Código del almacén (ej: WH-01)',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre del almacén',
    description TEXT COMMENT 'Descripción del almacén',
    location VARCHAR(255) COMMENT 'Ubicación geográfica del almacén',
    capacity_m3 DECIMAL(10, 2) COMMENT 'Capacidad total en metros cúbicos',
    manager_id BIGINT COMMENT 'ID del gerente del almacén',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Almacén activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_company_id (company_id),
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_manager_id (manager_id),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_code_company (code, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 3. PRODUCT_CATEGORIES - Categorías de Productos
-- ============================================
CREATE TABLE product_categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la categoría',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    code VARCHAR(50) NOT NULL COMMENT 'Código de la categoría (ej: ELEC)',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre de la categoría',
    description TEXT COMMENT 'Descripción de la categoría',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Categoría activa/inactiva',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    INDEX idx_company_id (company_id),
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_code_company (code, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 4. PRODUCTS - Productos
-- ============================================
CREATE TABLE products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del producto',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    sku VARCHAR(100) NOT NULL COMMENT 'SKU del producto',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre del producto',
    description TEXT COMMENT 'Descripción del producto',
    category_id BIGINT NOT NULL COMMENT 'ID de la categoría del producto',
    unit_of_measure ENUM('unit', 'kg', 'liter', 'meter', 'box') DEFAULT 'unit' NOT NULL COMMENT 'Unidad de medida',
    weight_kg DECIMAL(10, 2) COMMENT 'Peso en kilogramos',
    dimensions_length_cm DECIMAL(10, 2) COMMENT 'Largo en centímetros',
    dimensions_width_cm DECIMAL(10, 2) COMMENT 'Ancho en centímetros',
    dimensions_height_cm DECIMAL(10, 2) COMMENT 'Alto en centímetros',
    volume_m3 DECIMAL(10, 4) COMMENT 'Volumen en metros cúbicos',
    cost_price DECIMAL(12, 2) COMMENT 'Precio de costo',
    selling_price DECIMAL(12, 2) COMMENT 'Precio de venta',
    minimum_stock INT DEFAULT 0 COMMENT 'Stock mínimo recomendado',
    maximum_stock INT COMMENT 'Stock máximo permitido',
    is_perishable BOOLEAN DEFAULT FALSE COMMENT 'Producto perecedero',
    expiry_days INT COMMENT 'Días antes de expiración',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Producto activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE RESTRICT,
    INDEX idx_company_id (company_id),
    INDEX idx_sku (sku),
    INDEX idx_category_id (category_id),
    INDEX idx_is_active (is_active),
    INDEX idx_is_perishable (is_perishable),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_sku_company (sku, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 5. SHELVES - Góndolas/Estantes
-- ============================================
CREATE TABLE shelves (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la góndola',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    code VARCHAR(50) NOT NULL COMMENT 'Código de la góndola',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre de la góndola',
    shelf_type ENUM('rack', 'gondola', 'bin', 'pallet') DEFAULT 'rack' NOT NULL COMMENT 'Tipo de almacenamiento',
    `row_number` INT COMMENT 'Número de fila',
    column_number INT COMMENT 'Número de columna',
    level_number INT COMMENT 'Número de nivel',
    capacity_units INT COMMENT 'Capacidad en unidades',
    capacity_weight_kg DECIMAL(10, 2) COMMENT 'Capacidad en kilogramos',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Góndola activa/inactiva',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_warehouse_code (warehouse_id, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 6. SHELF_PRODUCTS - Asignación de Productos a Góndolas
-- ============================================
CREATE TABLE shelf_products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único',
    shelf_id BIGINT NOT NULL COMMENT 'ID de la góndola',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    position_in_shelf VARCHAR(50) COMMENT 'Posición específica en la góndola',
    quantity_units INT DEFAULT 0 COMMENT 'Cantidad de unidades',
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización',
    FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_shelf_id (shelf_id),
    INDEX idx_product_id (product_id),
    UNIQUE KEY uk_shelf_product (shelf_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 7. INVENTORY - Inventario Central
-- ============================================
CREATE TABLE inventory (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del registro de inventario',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity INT NOT NULL DEFAULT 0 COMMENT 'Cantidad total',
    reserved_quantity INT DEFAULT 0 COMMENT 'Cantidad reservada por órdenes',
    available_quantity INT GENERATED ALWAYS AS (quantity - reserved_quantity) STORED COMMENT 'Cantidad disponible',
    last_counted_at TIMESTAMP COMMENT 'Última vez que se contó',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_product_id (product_id),
    INDEX idx_quantity (quantity),
    INDEX idx_available_quantity (available_quantity),
    UNIQUE KEY uk_warehouse_product (warehouse_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 8. SUPPLIERS - Proveedores
-- ============================================
CREATE TABLE suppliers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del proveedor',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    `code` VARCHAR(50) NOT NULL COMMENT 'Código del proveedor',
    `name` VARCHAR(255) NOT NULL COMMENT 'Nombre del proveedor',
    contact_person VARCHAR(255) COMMENT 'Persona de contacto',
    email VARCHAR(255) COMMENT 'Email de contacto',
    phone VARCHAR(20) COMMENT 'Teléfono de contacto',
    address VARCHAR(255) COMMENT 'Dirección',
    city VARCHAR(100) COMMENT 'Ciudad',
    country VARCHAR(100) COMMENT 'País',
    payment_terms VARCHAR(100) COMMENT 'Términos de pago (ej: Net 30)',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Proveedor activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    INDEX idx_company_id (company_id),
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_code_company (code, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 9. PURCHASE_ORDERS - Órdenes de Compra
-- ============================================
CREATE TABLE purchase_orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la orden',
    po_number VARCHAR(50) UNIQUE NOT NULL COMMENT 'Número único de la orden de compra',
    supplier_id BIGINT NOT NULL COMMENT 'ID del proveedor',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén destino',
    po_status ENUM('draft', 'sent', 'confirmed', 'received', 'cancelled') DEFAULT 'draft' NOT NULL COMMENT 'Estado de la orden',
    total_amount DECIMAL(12, 2) COMMENT 'Monto total de la orden',
    expected_delivery_date DATE COMMENT 'Fecha esperada de entrega',
    actual_delivery_date DATE COMMENT 'Fecha real de entrega',
    notes TEXT COMMENT 'Notas adicionales',
    created_by BIGINT COMMENT 'ID del usuario que creó la orden',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_po_number (po_number),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_po_status (po_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 10. PURCHASE_ORDER_DETAILS - Detalles de Orden de Compra
-- ============================================
CREATE TABLE purchase_order_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del detalle',
    purchase_order_id BIGINT NOT NULL COMMENT 'ID de la orden de compra',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity_ordered INT NOT NULL COMMENT 'Cantidad ordenada',
    quantity_received INT DEFAULT 0 COMMENT 'Cantidad recibida',
    unit_price DECIMAL(12, 2) NOT NULL COMMENT 'Precio unitario',
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_price) STORED COMMENT 'Total de la línea',
    notes TEXT COMMENT 'Notas del detalle',
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_purchase_order_id (purchase_order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 11. CUSTOMERS - Clientes
-- ============================================
CREATE TABLE customers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del cliente',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    `code` VARCHAR(50) NOT NULL COMMENT 'Código del cliente',
    `name` VARCHAR(255) NOT NULL COMMENT 'Nombre del cliente',
    contact_person VARCHAR(255) COMMENT 'Persona de contacto',
    email VARCHAR(255) COMMENT 'Email de contacto',
    phone VARCHAR(20) COMMENT 'Teléfono de contacto',
    address VARCHAR(255) COMMENT 'Dirección',
    city VARCHAR(100) COMMENT 'Ciudad',
    country VARCHAR(100) COMMENT 'País',
    customer_type ENUM('retail', 'wholesale', 'distributor', 'internal') DEFAULT 'retail' COMMENT 'Tipo de cliente',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Cliente activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    INDEX idx_company_id (company_id),
    INDEX idx_code (code),
    INDEX idx_customer_type (customer_type),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at),
    UNIQUE KEY uk_code_company (code, company_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 12. SALES_ORDERS - Órdenes de Venta
-- ============================================
CREATE TABLE sales_orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la orden',
    so_number VARCHAR(50) UNIQUE NOT NULL COMMENT 'Número único de la orden de venta',
    customer_id BIGINT NOT NULL COMMENT 'ID del cliente',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén origen',
    order_status ENUM('draft', 'confirmed', 'picking', 'packed', 'shipped', 'delivered', 'cancelled') DEFAULT 'draft' NOT NULL COMMENT 'Estado de la orden',
    total_amount DECIMAL(12, 2) COMMENT 'Monto total de la orden',
    order_date DATE NOT NULL COMMENT 'Fecha de la orden',
    delivery_date DATE COMMENT 'Fecha de entrega',
    notes TEXT COMMENT 'Notas adicionales',
    created_by BIGINT COMMENT 'ID del usuario que creó la orden',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_so_number (so_number),
    INDEX idx_customer_id (customer_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_order_status (order_status),
    INDEX idx_order_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 13. SALES_ORDER_DETAILS - Detalles de Orden de Venta
-- ============================================
CREATE TABLE sales_order_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del detalle',
    sales_order_id BIGINT NOT NULL COMMENT 'ID de la orden de venta',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity_ordered INT NOT NULL COMMENT 'Cantidad ordenada',
    quantity_picked INT DEFAULT 0 COMMENT 'Cantidad recogida',
    quantity_shipped INT DEFAULT 0 COMMENT 'Cantidad enviada',
    unit_price DECIMAL(12, 2) NOT NULL COMMENT 'Precio unitario',
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_price) STORED COMMENT 'Total de la línea',
    notes TEXT COMMENT 'Notas del detalle',
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_sales_order_id (sales_order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 14. STOCK_MOVEMENTS - Movimientos de Stock
-- ============================================
CREATE TABLE stock_movements (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del movimiento',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    movement_type ENUM('inbound', 'outbound', 'adjustment', 'transfer', 'damage') NOT NULL COMMENT 'Tipo de movimiento',
    quantity INT NOT NULL COMMENT 'Cantidad movida',
    reference_type VARCHAR(50) COMMENT 'Tipo de referencia (purchase_order, sales_order, etc)',
    reference_id BIGINT COMMENT 'ID de la referencia',
    notes TEXT COMMENT 'Notas del movimiento',
    created_by BIGINT COMMENT 'ID del usuario que registró el movimiento',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha del movimiento',
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_product_id (product_id),
    INDEX idx_movement_type (movement_type),
    INDEX idx_created_at (created_at),
    INDEX idx_reference (reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 15. PICKING_TASKS - Tareas de Picking
-- ============================================
CREATE TABLE picking_tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la tarea',
    sales_order_id BIGINT NOT NULL COMMENT 'ID de la orden de venta',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity_to_pick INT NOT NULL COMMENT 'Cantidad a recoger',
    quantity_picked INT DEFAULT 0 COMMENT 'Cantidad recogida',
    shelf_id BIGINT COMMENT 'ID de la góndola',
    task_status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending' NOT NULL COMMENT 'Estado de la tarea',
    assigned_to BIGINT COMMENT 'ID del usuario asignado',
    picked_by BIGINT COMMENT 'ID del usuario que recogió',
    picked_at TIMESTAMP NULL COMMENT 'Fecha/hora del picking',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (picked_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_sales_order_id (sales_order_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_task_status (task_status),
    INDEX idx_assigned_to (assigned_to)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 16. STOCK_COUNTS - Conteos de Inventario
-- ============================================
CREATE TABLE stock_counts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del conteo',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    count_type ENUM('full', 'partial', 'spot_check') DEFAULT 'partial' NOT NULL COMMENT 'Tipo de conteo',
    count_status ENUM('draft', 'in_progress', 'completed', 'cancelled') DEFAULT 'draft' NOT NULL COMMENT 'Estado del conteo',
    counted_by BIGINT COMMENT 'ID del usuario que contó',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de inicio',
    completed_at TIMESTAMP NULL COMMENT 'Fecha de finalización',
    notes TEXT COMMENT 'Notas del conteo',
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (counted_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_count_status (count_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 17. STOCK_COUNT_DETAILS - Detalles de Conteos
-- ============================================
CREATE TABLE stock_count_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del detalle',
    stock_count_id BIGINT NOT NULL COMMENT 'ID del conteo',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    shelf_id BIGINT COMMENT 'ID de la góndola',
    system_quantity INT COMMENT 'Cantidad en el sistema',
    counted_quantity INT COMMENT 'Cantidad contada',
    variance INT GENERATED ALWAYS AS (counted_quantity - system_quantity) STORED COMMENT 'Varianza',
    notes TEXT COMMENT 'Notas del detalle',
    FOREIGN KEY (stock_count_id) REFERENCES stock_counts(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE SET NULL,
    INDEX idx_stock_count_id (stock_count_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 18. PRODUCT_BATCHES - Lotes de Productos
-- ============================================
CREATE TABLE product_batches (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del lote',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    batch_number VARCHAR(100) NOT NULL COMMENT 'Número de lote',
    supplier_id BIGINT COMMENT 'ID del proveedor',
    manufacture_date DATE COMMENT 'Fecha de manufactura',
    expiry_date DATE COMMENT 'Fecha de expiración',
    quantity_received INT NOT NULL COMMENT 'Cantidad recibida',
    quantity_available INT NOT NULL COMMENT 'Cantidad disponible',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    purchase_order_id BIGINT COMMENT 'ID de la orden de compra',
    notes TEXT COMMENT 'Notas del lote',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_batch_number (batch_number),
    INDEX idx_expiry_date (expiry_date),
    INDEX idx_warehouse_id (warehouse_id),
    UNIQUE KEY uk_product_batch (product_id, batch_number, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 19. WAREHOUSE_TRANSFERS - Transferencias entre Almacenes
-- ============================================
CREATE TABLE warehouse_transfers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la transferencia',
    transfer_number VARCHAR(50) UNIQUE NOT NULL COMMENT 'Número único de transferencia',
    from_warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén origen',
    to_warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén destino',
    transfer_status ENUM('draft', 'sent', 'received', 'cancelled') DEFAULT 'draft' NOT NULL COMMENT 'Estado de la transferencia',
    transfer_date DATE COMMENT 'Fecha de transferencia',
    expected_arrival DATE COMMENT 'Fecha esperada de llegada',
    actual_arrival DATE COMMENT 'Fecha real de llegada',
    notes TEXT COMMENT 'Notas de la transferencia',
    created_by BIGINT COMMENT 'ID del usuario que creó la transferencia',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_transfer_number (transfer_number),
    INDEX idx_transfer_status (transfer_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 20. WAREHOUSE_TRANSFER_DETAILS - Detalles de Transferencias
-- ============================================
CREATE TABLE warehouse_transfer_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del detalle',
    warehouse_transfer_id BIGINT NOT NULL COMMENT 'ID de la transferencia',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity_sent INT NOT NULL COMMENT 'Cantidad enviada',
    quantity_received INT DEFAULT 0 COMMENT 'Cantidad recibida',
    notes TEXT COMMENT 'Notas del detalle',
    FOREIGN KEY (warehouse_transfer_id) REFERENCES warehouse_transfers(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_warehouse_transfer_id (warehouse_transfer_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 21. PRODUCT_SUPPLIERS - Relación Productos-Proveedores
-- ============================================
CREATE TABLE product_suppliers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    supplier_id BIGINT NOT NULL COMMENT 'ID del proveedor',
    supplier_sku VARCHAR(100) COMMENT 'SKU del proveedor',
    lead_time_days INT COMMENT 'Tiempo de entrega en días',
    min_order_quantity INT COMMENT 'Cantidad mínima de orden',
    unit_price DECIMAL(12, 2) COMMENT 'Precio unitario',
    is_preferred BOOLEAN DEFAULT FALSE COMMENT 'Proveedor preferido',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Relación activa/inactiva',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE CASCADE,
    INDEX idx_product_id (product_id),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_is_preferred (is_preferred),
    UNIQUE KEY uk_product_supplier (product_id, supplier_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 22. WAREHOUSE_ZONES - Zonas del Almacén
-- ============================================
CREATE TABLE warehouse_zones (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la zona',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    `code` VARCHAR(50) NOT NULL COMMENT 'Código de la zona',
    `name` VARCHAR(255) NOT NULL COMMENT 'Nombre de la zona',
    zone_type ENUM('receiving', 'storage', 'picking', 'packing', 'shipping', 'returns') NOT NULL COMMENT 'Tipo de zona',
    `description` TEXT COMMENT 'Descripción de la zona',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Zona activa/inactiva',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_zone_type (zone_type),
    UNIQUE KEY uk_warehouse_zone (warehouse_id, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 23. PACKING_TASKS - Tareas de Empaque
-- ============================================
CREATE TABLE packing_tasks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la tarea',
    sales_order_id BIGINT NOT NULL COMMENT 'ID de la orden de venta',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    task_status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending' NOT NULL COMMENT 'Estado de la tarea',
    assigned_to BIGINT COMMENT 'ID del usuario asignado',
    packed_by BIGINT COMMENT 'ID del usuario que empacó',
    packed_at TIMESTAMP NULL COMMENT 'Fecha/hora del empaque',
    weight_kg DECIMAL(10, 2) COMMENT 'Peso total del paquete',
    dimensions_length_cm DECIMAL(10, 2) COMMENT 'Largo del paquete',
    dimensions_width_cm DECIMAL(10, 2) COMMENT 'Ancho del paquete',
    dimensions_height_cm DECIMAL(10, 2) COMMENT 'Alto del paquete',
    notes TEXT COMMENT 'Notas del empaque',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (packed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_sales_order_id (sales_order_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_task_status (task_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 24. SHIPPING_LABELS - Etiquetas de Envío
-- ============================================
CREATE TABLE shipping_labels (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la etiqueta',
    sales_order_id BIGINT NOT NULL COMMENT 'ID de la orden de venta',
    tracking_number VARCHAR(100) UNIQUE NOT NULL COMMENT 'Número de seguimiento',
    carrier VARCHAR(100) COMMENT 'Transportista',
    shipping_method VARCHAR(100) COMMENT 'Método de envío',
    weight_kg DECIMAL(10, 2) COMMENT 'Peso del envío',
    cost DECIMAL(12, 2) COMMENT 'Costo del envío',
    shipped_at TIMESTAMP NULL COMMENT 'Fecha/hora del envío',
    estimated_delivery DATE COMMENT 'Fecha estimada de entrega',
    actual_delivery DATE COMMENT 'Fecha real de entrega',
    notes TEXT COMMENT 'Notas del envío',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    INDEX idx_tracking_number (tracking_number),
    INDEX idx_carrier (carrier),
    INDEX idx_shipped_at (shipped_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 25. RETURNS_ORDERS - Órdenes de Devolución
-- ============================================
CREATE TABLE returns_orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único de la devolución',
    return_number VARCHAR(50) UNIQUE NOT NULL COMMENT 'Número único de devolución',
    sales_order_id BIGINT NOT NULL COMMENT 'ID de la orden de venta original',
    customer_id BIGINT NOT NULL COMMENT 'ID del cliente',
    warehouse_id BIGINT NOT NULL COMMENT 'ID del almacén',
    return_reason ENUM('defective', 'wrong_item', 'damaged', 'not_needed', 'other') NOT NULL COMMENT 'Razón de devolución',
    return_status ENUM('draft', 'confirmed', 'received', 'processed', 'credited', 'cancelled') DEFAULT 'draft' NOT NULL COMMENT 'Estado de la devolución',
    total_amount DECIMAL(12, 2) COMMENT 'Monto a acreditar',
    return_date DATE NOT NULL COMMENT 'Fecha de solicitud de devolución',
    received_date DATE COMMENT 'Fecha de recepción',
    notes TEXT COMMENT 'Notas de la devolución',
    created_by BIGINT COMMENT 'ID del usuario que creó la devolución',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_return_number (return_number),
    INDEX idx_sales_order_id (sales_order_id),
    INDEX idx_customer_id (customer_id),
    INDEX idx_return_status (return_status),
    INDEX idx_return_date (return_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 26. RETURN_ORDER_DETAILS - Detalles de Devolución
-- ============================================
CREATE TABLE return_order_details (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del detalle',
    return_order_id BIGINT NOT NULL COMMENT 'ID de la devolución',
    product_id BIGINT NOT NULL COMMENT 'ID del producto',
    quantity INT NOT NULL COMMENT 'Cantidad devuelta',
    unit_price DECIMAL(12, 2) NOT NULL COMMENT 'Precio unitario',
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED COMMENT 'Total de la línea',
    `condition` ENUM('new', 'used', 'damaged', 'defective') DEFAULT 'used' COMMENT 'Condición del producto',
    notes TEXT COMMENT 'Notas del producto',
    FOREIGN KEY (return_order_id) REFERENCES returns_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_return_order_id (return_order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 27. AUDIT_LOG - Log de Auditoría
-- ============================================
CREATE TABLE audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del log',
    company_id BIGINT NOT NULL COMMENT 'ID de la empresa a la que pertenece',
    user_id BIGINT COMMENT 'ID del usuario',
    `action` VARCHAR(100) NOT NULL COMMENT 'Acción realizada',
    `table_name` VARCHAR(100) COMMENT 'Tabla afectada',
    record_id BIGINT COMMENT 'ID del registro afectado',
    old_values JSON COMMENT 'Valores anteriores (JSON)',
    new_values JSON COMMENT 'Valores nuevos (JSON)',
    ip_address VARCHAR(45) COMMENT 'Dirección IP',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha/hora del evento',
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_company_id (company_id),
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_table_name (table_name),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ============================================

-- Índices para búsquedas comunes
CREATE INDEX idx_products_sku_active ON products(sku, is_active);
CREATE INDEX idx_products_name_active ON products(name, is_active);
CREATE INDEX idx_inventory_available ON inventory(available_quantity);
CREATE INDEX idx_shelves_warehouse_active ON shelves(warehouse_id, is_active);

-- Índices para reportes
CREATE INDEX idx_stock_movements_date_warehouse ON stock_movements(created_at, warehouse_id);
CREATE INDEX idx_purchase_orders_status_date ON purchase_orders(po_status, created_at);
CREATE INDEX idx_sales_orders_status_date ON sales_orders(order_status, created_at);

-- Índices para relaciones frecuentes
CREATE INDEX idx_shelf_products_by_product ON shelf_products(product_id);
CREATE INDEX idx_stock_count_details_product ON stock_count_details(product_id);

-- Índices adicionales para joins frecuentes
CREATE INDEX idx_picking_tasks_status_warehouse ON picking_tasks(task_status, warehouse_id);
CREATE INDEX idx_packing_tasks_status_warehouse ON packing_tasks(task_status, warehouse_id);
CREATE INDEX idx_shipping_labels_tracking ON shipping_labels(tracking_number);
CREATE INDEX idx_returns_orders_status ON returns_orders(return_status);
CREATE INDEX idx_product_batches_expiry ON product_batches(expiry_date);
CREATE INDEX idx_warehouse_transfers_status ON warehouse_transfers(transfer_status);

-- Índices para filtros comunes
CREATE INDEX idx_products_category_active ON products(category_id, is_active);
CREATE INDEX idx_customers_active ON customers(is_active);
CREATE INDEX idx_suppliers_active ON suppliers(is_active);
CREATE INDEX idx_inventory_warehouse_product ON inventory(warehouse_id, product_id);

-- ============================================
-- VISTAS ÚTILES PARA REPORTES
-- ============================================

-- Vista: Inventario total por producto
CREATE OR REPLACE VIEW v_inventory_summary AS
SELECT
    p.id,
    p.sku,
    p.name,
    pc.name as category,
    SUM(i.quantity) as total_quantity,
    SUM(i.reserved_quantity) as total_reserved,
    SUM(i.available_quantity) as total_available,
    COUNT(DISTINCT i.warehouse_id) as warehouse_count
FROM products p
LEFT JOIN product_categories pc ON p.category_id = pc.id
LEFT JOIN inventory i ON p.id = i.product_id
WHERE p.is_active = TRUE
GROUP BY p.id, p.sku, p.name, pc.name;

-- Vista: Stock bajo (por debajo del mínimo)
CREATE OR REPLACE VIEW v_low_stock AS
SELECT
    p.id,
    p.sku,
    p.name,
    pc.name AS category,
    p.minimum_stock,
    COALESCE(SUM(i.available_quantity), 0) AS current_stock,
    (p.minimum_stock - COALESCE(SUM(i.available_quantity), 0)) AS shortage
FROM products p
LEFT JOIN product_categories pc 
    ON p.category_id = pc.id
LEFT JOIN inventory i 
    ON p.id = i.product_id
WHERE p.is_active = TRUE
GROUP BY 
    p.id,
    p.sku,
    p.name,
    pc.name,
    p.minimum_stock
HAVING COALESCE(SUM(i.available_quantity), 0) <= p.minimum_stock;

-- Vista: Órdenes de venta pendientes
CREATE OR REPLACE VIEW v_pending_sales_orders AS
SELECT
    so.id,
    so.so_number,
    c.name as customer,
    w.name as warehouse,
    so.total_amount,
    so.order_date,
    so.order_status,
    COUNT(DISTINCT pt.id) as picking_tasks,
    SUM(CASE WHEN pt.task_status != 'completed' THEN 1 ELSE 0 END) as pending_picks
FROM sales_orders so
LEFT JOIN customers c ON so.customer_id = c.id
LEFT JOIN warehouses w ON so.warehouse_id = w.id
LEFT JOIN picking_tasks pt ON so.id = pt.sales_order_id
WHERE so.order_status IN ('confirmed', 'picking', 'packed')
GROUP BY so.id, so.so_number, c.name, w.name, so.total_amount, so.order_date, so.order_status;

-- Vista: Stock por ubicación (góndola)
CREATE OR REPLACE VIEW v_stock_by_location AS
SELECT
    w.code as warehouse,
    wz.name as zone,
    s.code as shelf,
    p.sku,
    p.name as product,
    sp.position_in_shelf,
    sp.quantity_units,
    p.minimum_stock,
    s.capacity_units
FROM shelf_products sp
INNER JOIN shelves s ON sp.shelf_id = s.id
INNER JOIN warehouse_zones wz ON s.warehouse_id = wz.warehouse_id
INNER JOIN warehouses w ON s.warehouse_id = w.id
INNER JOIN products p ON sp.product_id = p.id
WHERE w.is_active = TRUE AND s.is_active = TRUE AND p.is_active = TRUE;

-- Vista: Proveedores por producto
CREATE OR REPLACE VIEW v_product_suppliers AS
SELECT
    p.sku,
    p.name as product,
    s.code as supplier_code,
    s.name as supplier,
    ps.supplier_sku,
    ps.lead_time_days,
    ps.min_order_quantity,
    ps.unit_price,
    ps.is_preferred
FROM products p
INNER JOIN product_suppliers ps ON p.id = ps.product_id
INNER JOIN suppliers s ON ps.supplier_id = s.id
WHERE p.is_active = TRUE AND ps.is_active = TRUE
ORDER BY p.sku, ps.is_preferred DESC;

-- ============================================
-- RESTAURAR CONFIGURACIÓN
-- ============================================

SET FOREIGN_KEY_CHECKS=1;

-- ============================================
-- DATOS INICIALES DE EJEMPLO
-- ============================================

-- Insertar empresa de ejemplo
INSERT INTO companies (code, name, tax_id, address, phone, email, is_active)
VALUES ('EMP-001', 'Empresa Ejemplo S.A.', '12345678-9', 'Calle Principal 123', '+56 2 1234 5678', 'info@empresa.com', TRUE);

-- Insertar usuarios
INSERT INTO users (company_id, email, full_name, hashed_password, role, is_active)
VALUES
    (1, 'admin@wms.com', 'Administrador', 'pass123', 'admin', TRUE),
    (1, 'manager@wms.com', 'Gerente Almacén', 'pass123', 'manager', TRUE),
    (1, 'operator@wms.com', 'Operario', 'pass123', 'operator', TRUE);

-- Insertar categorías de productos
INSERT INTO product_categories (company_id, code, name, description, is_active)
VALUES
    (1, 'ELEC', 'Electrónica', 'Productos electrónicos en general', TRUE),
    (1, 'ALIM', 'Alimentos', 'Productos alimenticios', TRUE),
    (1, 'CONS', 'Consumibles', 'Productos consumibles', TRUE),
    (1, 'ROPA', 'Ropa', 'Prendas de vestir', TRUE),
    (1, 'MUEBLES', 'Muebles', 'Muebles y accesorios', TRUE);

-- Insertar almacenes
INSERT INTO warehouses (company_id, code, name, description, location, capacity_m3, manager_id, is_active)
VALUES
    (1, 'WH-01', 'Almacén Central', 'Almacén principal', 'Centro', 5000.00, 2, TRUE),
    (1, 'WH-02', 'Almacén Norte', 'Almacén regional norte', 'Norte', 2000.00, 3, TRUE),
    (1, 'WH-03', 'Almacén Sur', 'Almacén regional sur', 'Sur', 2000.00, 2, TRUE);

-- Insertar zonas de almacén
INSERT INTO warehouse_zones (warehouse_id, code, name, zone_type, description, is_active)
VALUES
    (1, 'REC-01', 'Zona Recepción', 'receiving', 'Área de recepción de mercancía', TRUE),
    (1, 'ALM-01', 'Almacenamiento A', 'storage', 'Área de almacenamiento general', TRUE),
    (1, 'ALM-02', 'Almacenamiento B', 'storage', 'Área de almacenamiento especial', TRUE),
    (1, 'PICK-01', 'Picking A', 'picking', 'Zona de picking nivel 1', TRUE),
    (1, 'PACK-01', 'Empaque', 'packing', 'Zona de empaque', TRUE),
    (1, 'SHIP-01', 'Envío', 'shipping', 'Zona de envío', TRUE);

-- Insertar proveedores
INSERT INTO suppliers (company_id, code, name, contact_person, email, phone, address, city, country, payment_terms, is_active)
VALUES
    (1, 'SUP-001', 'Proveedor Electrónico SA', 'Juan Pérez', 'juan@proveedor1.com', '+56 2 1234 5678', 'Calle 1 #100', 'Santiago', 'Chile', 'Net 30', TRUE),
    (1, 'SUP-002', 'Distribuidora de Alimentos', 'María García', 'maria@proveedor2.com', '+56 2 8765 4321', 'Calle 2 #200', 'Santiago', 'Chile', 'Net 15', TRUE),
    (1, 'SUP-003', 'Importadora Global', 'Carlos López', 'carlos@proveedor3.com', '+56 2 5555 6666', 'Calle 3 #300', 'Valparaíso', 'Chile', 'Net 45', TRUE);

-- Insertar clientes
INSERT INTO customers (company_id, code, name, contact_person, email, phone, address, city, country, customer_type, is_active)
VALUES
    (1, 'CUST-001', 'Tienda Centro', 'Ana Martínez', 'ana@tienda1.com', '+56 2 1111 2222', 'Av. Principal #500', 'Santiago', 'Chile', 'retail', TRUE),
    (1, 'CUST-002', 'Distribuidor Regional', 'Roberto Silva', 'roberto@dist.com', '+56 2 3333 4444', 'Av. Secundaria #600', 'Valparaíso', 'Chile', 'distributor', TRUE),
    (1, 'CUST-003', 'Mayorista Sur', 'Laura Díaz', 'laura@mayorista.com', '+56 2 5555 7777', 'Calle Sur #700', 'Concepción', 'Chile', 'wholesale', TRUE);

-- Insertar estantes/góndolas
INSERT INTO shelves (
    warehouse_id,
    code,
    name,
    shelf_type,
    `row_number`,
    column_number,
    level_number,
    capacity_units,
    capacity_weight_kg,
    is_active
)
VALUES
    (1, 'RACK-A-01', 'Rack A Nivel 1', 'rack', 1, 1, 1, 500, 1000.00, TRUE),
    (1, 'RACK-A-02', 'Rack A Nivel 2', 'rack', 1, 1, 2, 500, 1000.00, TRUE),
    (1, 'GONDOLA-B-01', 'Góndola B', 'gondola', 2, 2, 1, 300, 500.00, TRUE),
    (1, 'BIN-C-01', 'Bin C', 'bin', 3, 3, 1, 100, 200.00, TRUE);

-- Insertar productos
INSERT INTO products 
( company_id,
sku, 
`name`, 
`description`, 
category_id, unit_of_measure, weight_kg, dimensionproductss_length_cm, dimensions_width_cm, dimensions_height_cm, cost_price, selling_price, minimum_stock, maximum_stock, is_perishable, expiry_days, is_active)
VALUES
    (1, 'PROD-001', 'Laptop Dell XPS', 'Laptop de alta performance', 1, 'unit', 2.5, 35.0, 24.0, 1.5, 600.00, 1299.99, 5, 50, FALSE, NULL, TRUE),
    (1, 'PROD-002', 'Monitor LG 27"', 'Monitor Full HD', 1, 'unit', 5.0, 61.0, 23.0, 5.0, 150.00, 299.99, 3, 30, FALSE, NULL, TRUE),
    (1, 'PROD-003', 'Teclado Mecánico', 'Teclado RGB', 1, 'unit', 0.8, 45.0, 15.0, 3.0, 50.00, 129.99, 10, 100, FALSE, NULL, TRUE),
    (1, 'PROD-004', 'Arroz Premium 1kg', 'Arroz blanco grano largo', 2, 'kg', 1.0, 25.0, 15.0, 8.0, 2.00, 4.99, 100, 500, TRUE, 365, TRUE),
    (1, 'PROD-005', 'Aceite Vegetal 2L', 'Aceite de girasol refinado', 2, 'liter', 1.8, 20.0, 10.0, 25.0, 3.50, 7.99, 50, 200, TRUE, 730, TRUE),
    (1, 'PROD-006', 'Papel de Impresora A4', 'Resma 500 hojas', 3, 'box', 2.5, 21.0, 30.0, 10.0, 5.00, 9.99, 50, 200, FALSE, NULL, TRUE),
    (1, 'PROD-007', 'Bolígrafos x12', 'Bolígrafos azules', 3, 'box', 0.3, 15.0, 8.0, 5.0, 3.00, 5.99, 100, 500, FALSE, NULL, TRUE),
    (1, 'PROD-008', 'Polera Algodón L', 'Polera blanca talla L', 4, 'unit', 0.3, 70.0, 45.0, 0.5, 8.00, 19.99, 20, 100, FALSE, NULL, TRUE),
    (1, 'PROD-009', 'Jeans Azul 32', 'Jeans azul talla 32', 4, 'unit', 0.6, 110.0, 40.0, 0.5, 25.00, 59.99, 15, 50, FALSE, NULL, TRUE),
    (1, 'PROD-010', 'Silla Oficina Negro', 'Silla ergonómica', 5, 'unit', 8.0, 70.0, 70.0, 110.0, 150.00, 349.99, 3, 20, FALSE, NULL, TRUE);

-- Insertar inventario
INSERT INTO inventory (warehouse_id, product_id, quantity, reserved_quantity)
VALUES
    (1, 1, 25, 5),
    (1, 2, 15, 2),
    (1, 3, 50, 10),
    (1, 4, 250, 50),
    (1, 5, 100, 20),
    (1, 6, 150, 30),
    (1, 7, 300, 50),
    (1, 8, 80, 10),
    (1, 9, 45, 5),
    (1, 10, 8, 2),
    (2, 1, 10, 2),
    (2, 4, 100, 20),
    (3, 1, 5, 1),
    (3, 5, 50, 10);

-- Insertar relaciones producto-proveedor
INSERT INTO product_suppliers (product_id, supplier_id, supplier_sku, lead_time_days, min_order_quantity, unit_price, is_preferred)
VALUES
    (1, 1, 'DELL-XPS-001', 7, 5, 600.00, TRUE),
    (2, 1, 'LG-27-001', 5, 3, 150.00, TRUE),
    (3, 1, 'KEY-MECH-001', 3, 10, 50.00, TRUE),
    (4, 2, 'ARROZ-1KG-001', 3, 100, 2.00, TRUE),
    (5, 2, 'ACEITE-2L-001', 2, 50, 3.50, TRUE),
    (6, 3, 'PAPEL-A4-001', 5, 50, 5.00, TRUE),
    (7, 3, 'BOLI-12-001', 7, 100, 3.00, TRUE),
    (8, 3, 'POLERA-L-001', 10, 20, 8.00, TRUE),
    (9, 3, 'JEANS-32-001', 10, 15, 25.00, TRUE),
    (10, 1, 'SILLA-OFF-001', 14, 3, 150.00, TRUE);

-- Nota: Los IDs se autoincrementan automáticamente
-- No es necesario especificar los IDs en las inserciones

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
