-- ============================================
-- WMS API - Database Schema (MySQL)
-- Diseño normalizado para Sistema de Gestión de Almacén
-- Todos los IDs son AUTO_INCREMENT para autoincremento automático
-- ============================================

-- ============================================
-- 1. USERS - Usuarios del Sistema
-- ============================================
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del usuario',
    email VARCHAR(255) UNIQUE NOT NULL COMMENT 'Email único del usuario',
    full_name VARCHAR(255) NOT NULL COMMENT 'Nombre completo del usuario',
    hashed_password VARCHAR(255) NOT NULL COMMENT 'Contraseña encriptada',
    role ENUM('admin', 'manager', 'operator', 'viewer') DEFAULT 'viewer' NOT NULL COMMENT 'Rol del usuario',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Estado activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 2. WAREHOUSES - Almacenes
-- ============================================
CREATE TABLE warehouses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID único del almacén',
    code VARCHAR(50) UNIQUE NOT NULL COMMENT 'Código único del almacén',
    name VARCHAR(255) NOT NULL COMMENT 'Nombre del almacén',
    description TEXT COMMENT 'Descripción del almacén',
    location VARCHAR(255) COMMENT 'Ubicación del almacén',
    capacity_m3 DECIMAL(10, 2) COMMENT 'Capacidad en metros cúbicos',
    manager_id BIGINT COMMENT 'ID del gerente del almacén',
    is_active BOOLEAN DEFAULT TRUE NOT NULL COMMENT 'Estado activo/inactivo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL COMMENT 'Fecha de creación',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL COMMENT 'Última actualización',
    FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_manager_id (manager_id),
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=1;

-- ============================================
-- 3. SHELVES - Góndolas/Estantes
-- ============================================
CREATE TABLE shelves (
    id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    shelf_type ENUM('rack', 'gondola', 'bin', 'pallet') DEFAULT 'rack' NOT NULL,
    row_number INT,
    column_number INT,
    level_number INT,
    capacity_units INT COMMENT 'Capacidad de unidades',
    capacity_weight_kg DECIMAL(10, 2) COMMENT 'Capacidad en kg',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    UNIQUE KEY uk_warehouse_code (warehouse_id, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 4. PRODUCT_CATEGORIES - Categorías de Productos
-- ============================================
CREATE TABLE product_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 5. PRODUCTS - Productos
-- ============================================
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT NOT NULL,
    unit_of_measure ENUM('unit', 'kg', 'liter', 'meter', 'box') DEFAULT 'unit' NOT NULL,
    weight_kg DECIMAL(10, 2),
    dimensions_length_cm DECIMAL(10, 2),
    dimensions_width_cm DECIMAL(10, 2),
    dimensions_height_cm DECIMAL(10, 2),
    volume_m3 DECIMAL(10, 4),
    cost_price DECIMAL(12, 2),
    selling_price DECIMAL(12, 2),
    minimum_stock INT DEFAULT 0,
    maximum_stock INT,
    is_perishable BOOLEAN DEFAULT FALSE,
    expiry_days INT COMMENT 'Días antes de expiración',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE RESTRICT,
    INDEX idx_sku (sku),
    INDEX idx_category_id (category_id),
    INDEX idx_is_active (is_active),
    INDEX idx_is_perishable (is_perishable)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 6. SHELF_PRODUCTS - Asignación de Productos a Góndolas
-- ============================================
CREATE TABLE shelf_products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    shelf_id INT NOT NULL,
    product_id INT NOT NULL,
    position_in_shelf VARCHAR(50) COMMENT 'Posición específica en la góndola',
    quantity_units INT DEFAULT 0,
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_shelf_id (shelf_id),
    INDEX idx_product_id (product_id),
    UNIQUE KEY uk_shelf_product (shelf_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 7. INVENTORY - Inventario Central
-- ============================================
CREATE TABLE inventory (
    id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT DEFAULT 0 COMMENT 'Cantidad reservada por órdenes',
    available_quantity INT GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    last_counted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_product_id (product_id),
    INDEX idx_quantity (quantity),
    UNIQUE KEY uk_warehouse_product (warehouse_id, product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 8. STOCK_MOVEMENTS - Movimientos de Stock
-- ============================================
CREATE TABLE stock_movements (
    id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    movement_type ENUM('inbound', 'outbound', 'adjustment', 'transfer', 'damage') NOT NULL,
    quantity INT NOT NULL,
    reference_type VARCHAR(50) COMMENT 'purchase_order, sales_order, adjustment, etc',
    reference_id INT COMMENT 'ID de la orden relacionada',
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_product_id (product_id),
    INDEX idx_movement_type (movement_type),
    INDEX idx_created_at (created_at),
    INDEX idx_reference (reference_type, reference_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 9. SUPPLIERS - Proveedores
-- ============================================
CREATE TABLE suppliers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    payment_terms VARCHAR(100) COMMENT 'ej: Net 30, 50%/50%',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 10. PURCHASE_ORDERS - Órdenes de Compra
-- ============================================
CREATE TABLE purchase_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    po_status ENUM('draft', 'sent', 'confirmed', 'received', 'cancelled') DEFAULT 'draft' NOT NULL,
    total_amount DECIMAL(12, 2),
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_po_number (po_number),
    INDEX idx_supplier_id (supplier_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_po_status (po_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 11. PURCHASE_ORDER_DETAILS - Detalles de Orden de Compra
-- ============================================
CREATE TABLE purchase_order_details (
    id INT PRIMARY KEY AUTO_INCREMENT,
    purchase_order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    quantity_received INT DEFAULT 0,
    unit_price DECIMAL(12, 2) NOT NULL,
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_price) STORED,
    notes TEXT,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_purchase_order_id (purchase_order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 12. CUSTOMERS - Clientes
-- ============================================
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    customer_type ENUM('retail', 'wholesale', 'distributor', 'internal') DEFAULT 'retail',
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX idx_code (code),
    INDEX idx_customer_type (customer_type),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 13. SALES_ORDERS - Órdenes de Venta
-- ============================================
CREATE TABLE sales_orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    so_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    order_status ENUM('draft', 'confirmed', 'picking', 'packed', 'shipped', 'delivered', 'cancelled') DEFAULT 'draft' NOT NULL,
    total_amount DECIMAL(12, 2),
    order_date DATE NOT NULL,
    delivery_date DATE,
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_so_number (so_number),
    INDEX idx_customer_id (customer_id),
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_order_status (order_status),
    INDEX idx_order_date (order_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 14. SALES_ORDER_DETAILS - Detalles de Orden de Venta
-- ============================================
CREATE TABLE sales_order_details (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sales_order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    quantity_picked INT DEFAULT 0,
    quantity_shipped INT DEFAULT 0,
    unit_price DECIMAL(12, 2) NOT NULL,
    line_total DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_price) STORED,
    notes TEXT,
    FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_sales_order_id (sales_order_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 15. PICKING_TASKS - Tareas de Picking
-- ============================================
CREATE TABLE picking_tasks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sales_order_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_to_pick INT NOT NULL,
    quantity_picked INT DEFAULT 0,
    shelf_id INT,
    task_status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending' NOT NULL,
    assigned_to INT,
    picked_by INT,
    picked_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 16. STOCK_COUNTS - Conteos de Inventario
-- ============================================
CREATE TABLE stock_counts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_id INT NOT NULL,
    count_type ENUM('full', 'partial', 'spot_check') DEFAULT 'partial' NOT NULL,
    count_status ENUM('draft', 'in_progress', 'completed', 'cancelled') DEFAULT 'draft' NOT NULL,
    counted_by INT NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (counted_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_warehouse_id (warehouse_id),
    INDEX idx_count_status (count_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 17. STOCK_COUNT_DETAILS - Detalles de Conteos
-- ============================================
CREATE TABLE stock_count_details (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stock_count_id INT NOT NULL,
    product_id INT NOT NULL,
    shelf_id INT,
    system_quantity INT,
    counted_quantity INT,
    variance INT GENERATED ALWAYS AS (counted_quantity - system_quantity) STORED,
    notes TEXT,
    FOREIGN KEY (stock_count_id) REFERENCES stock_counts(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE SET NULL,
    INDEX idx_stock_count_id (stock_count_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 18. PRODUCT_BATCHES - Lotes de Productos (para trazabilidad)
-- ============================================
CREATE TABLE product_batches (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    batch_number VARCHAR(100) NOT NULL,
    supplier_id INT,
    manufacture_date DATE,
    expiry_date DATE,
    quantity_received INT NOT NULL,
    quantity_available INT NOT NULL,
    warehouse_id INT NOT NULL,
    purchase_order_id INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL,
    INDEX idx_product_id (product_id),
    INDEX idx_batch_number (batch_number),
    INDEX idx_expiry_date (expiry_date),
    INDEX idx_warehouse_id (warehouse_id),
    UNIQUE KEY uk_product_batch (product_id, batch_number, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 19. WAREHOUSE_TRANSFERS - Transferencias entre Almacenes
-- ============================================
CREATE TABLE warehouse_transfers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transfer_number VARCHAR(50) UNIQUE NOT NULL,
    from_warehouse_id INT NOT NULL,
    to_warehouse_id INT NOT NULL,
    transfer_status ENUM('draft', 'sent', 'received', 'cancelled') DEFAULT 'draft' NOT NULL,
    transfer_date DATE,
    expected_arrival DATE,
    actual_arrival DATE,
    notes TEXT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_transfer_number (transfer_number),
    INDEX idx_transfer_status (transfer_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 20. WAREHOUSE_TRANSFER_DETAILS - Detalles de Transferencias
-- ============================================
CREATE TABLE warehouse_transfer_details (
    id INT PRIMARY KEY AUTO_INCREMENT,
    warehouse_transfer_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_sent INT NOT NULL,
    quantity_received INT DEFAULT 0,
    notes TEXT,
    FOREIGN KEY (warehouse_transfer_id) REFERENCES warehouse_transfers(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_warehouse_transfer_id (warehouse_transfer_id),
    INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 21. AUDIT_LOG - Log de Auditoría
-- ============================================
CREATE TABLE audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_table_name (table_name),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ============================================

-- Índices para búsquedas comunes
CREATE INDEX idx_products_sku_active ON products(sku, is_active);
CREATE INDEX idx_inventory_available ON inventory(available_quantity);
CREATE INDEX idx_shelves_warehouse_active ON shelves(warehouse_id, is_active);

-- Índices para reportes
CREATE INDEX idx_stock_movements_date_warehouse ON stock_movements(created_at, warehouse_id);
CREATE INDEX idx_purchase_orders_status_date ON purchase_orders(po_status, created_at);
CREATE INDEX idx_sales_orders_status_date ON sales_orders(order_status, created_at);

-- ============================================
-- DATOS INICIALES DE EJEMPLO
-- ============================================

-- Insertar usuario administrador de ejemplo
INSERT INTO users (email, full_name, hashed_password, role, is_active)
VALUES ('admin@wms.com', 'Administrador', '$2b$12$...[hashed_password]...', 'admin', TRUE);

-- Insertar categoría de ejemplo
INSERT INTO product_categories (code, name, description, is_active)
VALUES
    ('ELEC', 'Electrónica', 'Productos electrónicos en general', TRUE),
    ('ALIM', 'Alimentos', 'Productos alimenticios', TRUE),
    ('CONS', 'Consumibles', 'Productos consumibles', TRUE);

-- Insertar almacén de ejemplo
INSERT INTO warehouses (code, name, description, location, capacity_m3, is_active)
VALUES ('WH-01', 'Almacén Principal', 'Almacén central', 'Lima, Perú', 500.00, TRUE);

-- Insertar proveedor de ejemplo
INSERT INTO suppliers (code, name, contact_person, email, phone, address, city, country, is_active)
VALUES ('SUPP-001', 'Proveedor Ejemplo', 'Juan Pérez', 'juan@supplier.com', '+51987654321', 'Calle Principal 123', 'Lima', 'Perú', TRUE);

-- Insertar cliente de ejemplo
INSERT INTO customers (code, name, contact_person, email, phone, address, city, country, customer_type, is_active)
VALUES ('CUST-001', 'Cliente Ejemplo', 'María García', 'maria@customer.com', '+51912345678', 'Avenida Central 456', 'Lima', 'Perú', 'retail', TRUE);

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
