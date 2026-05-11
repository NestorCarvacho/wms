-- ============================================
-- WMS MULTI-TENANT - SCRIPT UNIFICADO v4.0
-- Estructura + Datos Iniciales
-- ============================================

SET FOREIGN_KEY_CHECKS=0;

-- 1. LIMPIEZA DE TABLAS
DROP TABLE IF EXISTS log_auditoria;
DROP TABLE IF EXISTS movimientos_stock;
DROP TABLE IF EXISTS inventario;
DROP TABLE IF EXISTS ordenes_venta;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS perfiles_usuario;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS permisos_cargo;
DROP TABLE IF EXISTS cargos;
DROP TABLE IF EXISTS estados_orden;
DROP TABLE IF EXISTS estados_inventario;
DROP TABLE IF EXISTS unidades_medida;
DROP TABLE IF EXISTS tipos_zona;
DROP TABLE IF EXISTS zonas_bodega;
DROP TABLE IF EXISTS bodegas;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS empresas;

SET FOREIGN_KEY_CHECKS=1;

-- ============================================
-- 2. CREACIÓN DE TABLAS (ESTRUCTURA)
-- ============================================

CREATE TABLE empresas (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    rut VARCHAR(50),
    esta_activa BOOLEAN DEFAULT TRUE,
    creado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE cargos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_cargo_empresa (nombre, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE permisos_cargo (
    cargo_id BIGINT NOT NULL,
    rol_id BIGINT NOT NULL,
    PRIMARY KEY (cargo_id, rol_id),
    FOREIGN KEY (cargo_id) REFERENCES cargos(id) ON DELETE CASCADE,
    FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE estados_inventario (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255),
    permite_venta BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_estado_inv_empresa (nombre, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE estados_orden (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    orden_flujo INT DEFAULT 0,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_estado_ord_empresa (nombre, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE unidades_medida (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_unidad_empresa (codigo, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tipos_zona (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY uk_tipozona_empresa (nombre, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE usuarios (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    cargo_id BIGINT,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    esta_activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    FOREIGN KEY (cargo_id) REFERENCES cargos(id) ON DELETE SET NULL,
    UNIQUE KEY uk_email_empresa (email, empresa_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE perfiles_usuario (
    usuario_id BIGINT PRIMARY KEY,
    rut VARCHAR(20) UNIQUE,
    nombre_completo VARCHAR(255),
    genero VARCHAR(20),
    direccion TEXT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bodegas (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE zonas_bodega (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    bodega_id BIGINT NOT NULL,
    tipo_zona_id BIGINT NOT NULL,
    nombre VARCHAR(100),
    FOREIGN KEY (bodega_id) REFERENCES bodegas(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_zona_id) REFERENCES tipos_zona(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE productos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    sku VARCHAR(100) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    unidad_medida_id BIGINT NOT NULL,
    precio_costo DECIMAL(12,2),
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    FOREIGN KEY (unidad_medida_id) REFERENCES unidades_medida(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inventario (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    bodega_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    estado_id BIGINT NOT NULL,
    cantidad INT NOT NULL DEFAULT 0,
    cantidad_reservada INT DEFAULT 0,
    ultimo_movimiento_por BIGINT,
    actualizado_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (bodega_id) REFERENCES bodegas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (estado_id) REFERENCES estados_inventario(id),
    FOREIGN KEY (ultimo_movimiento_por) REFERENCES usuarios(id) ON DELETE SET NULL,
    UNIQUE KEY uk_inventario_fina (bodega_id, producto_id, estado_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE movimientos_stock (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    empresa_id BIGINT NOT NULL,
    usuario_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    cantidad INT NOT NULL,
    bodega_origen_id BIGINT,
    bodega_destino_id BIGINT,
    estado_inv_anterior_id BIGINT,
    estado_inv_nuevo_id BIGINT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (producto_id) REFERENCES productos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- 3. POBLACIÓN DE DATOS (DML)
-- ============================================

-- Roles Globales
INSERT INTO roles (nombre) VALUES ('admin'), ('operario'), ('ventas'), ('visor');

-- EMPRESA MAESTRA (Tu Administración)
INSERT INTO empresas (codigo, nombre, rut) VALUES ('SaaS-CORE', 'Admin Central WMS', '99.999.999-0');
SET @corp_id = LAST_INSERT_ID();

INSERT INTO cargos (empresa_id, nombre) VALUES (@corp_id, 'Soporte Global');
SET @cargo_corp = LAST_INSERT_ID();

INSERT INTO permisos_cargo (cargo_id, rol_id) SELECT @cargo_corp, id FROM roles;

INSERT INTO usuarios (empresa_id, cargo_id, email, password_hash) 
VALUES (@corp_id, @cargo_corp, 'tu_usuario@wms.com', 'hash_seguro');
SET @u_corp = LAST_INSERT_ID();

INSERT INTO perfiles_usuario (usuario_id, rut, nombre_completo) VALUES (@u_corp, '1-1', 'Super Administrador');

-- EMPRESA CLIENTE (Ejemplo de Gran Magnitud)
INSERT INTO empresas (codigo, nombre, rut) VALUES ('CLIENTE-01', 'Logística Avanzada S.A.', '77.777.777-7');
SET @client_id = LAST_INSERT_ID();

-- Parametrización del Cliente
INSERT INTO estados_inventario (empresa_id, nombre, permite_venta) VALUES 
(@client_id, 'Disponible', TRUE), (@client_id, 'Merma', FALSE), (@client_id, 'Chatarra', FALSE);
SET @est_disponible = (SELECT id FROM estados_inventario WHERE empresa_id = @client_id AND nombre = 'Disponible');

INSERT INTO unidades_medida (empresa_id, codigo, nombre) VALUES (@client_id, 'UN', 'Unidad');
SET @u_medida = LAST_INSERT_ID();

INSERT INTO tipos_zona (empresa_id, nombre) VALUES (@client_id, 'Almacenamiento');
SET @t_zona = LAST_INSERT_ID();

-- Personal del Cliente
INSERT INTO cargos (empresa_id, nombre) VALUES (@client_id, 'Jefe de Bodega');
SET @cargo_client = LAST_INSERT_ID();
INSERT INTO permisos_cargo (cargo_id, rol_id) VALUES (@cargo_client, 2), (@cargo_client, 4); -- Operario y Visor

INSERT INTO usuarios (empresa_id, cargo_id, email, password_hash) 
VALUES (@client_id, @cargo_client, 'jefe.bodega@logistica.cl', 'hash_cliente');
SET @u_client = LAST_INSERT_ID();

-- Inventario de Prueba
INSERT INTO bodegas (empresa_id, codigo, nombre) VALUES (@client_id, 'B-01', 'Bodega Norte');
SET @bod_id = LAST_INSERT_ID();

INSERT INTO productos (empresa_id, sku, nombre, unidad_medida_id) VALUES (@client_id, 'ITEM-001', 'Producto de Prueba', @u_medida);
SET @prod_id = LAST_INSERT_ID();

INSERT INTO inventario (bodega_id, producto_id, estado_id, cantidad, ultimo_movimiento_por) 
VALUES (@bod_id, @prod_id, @est_disponible, 500, @u_client);