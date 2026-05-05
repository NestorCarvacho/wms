# ÉPICA 1: Gestión de Productos (CRÍTICA)

## Historia 1: Crear producto

**Como** administrador  
**Quiero** registrar productos  
**Para** gestionarlos en inventario

### Tareas:
- [ ] Crear modelo Producto
- [ ] Endpoint POST /productos
- [ ] Validar campos obligatorios
- [ ] Manejar duplicados (SKU)
- [ ] Tests

---

## Historia 2: Listar productos

### Tareas:
- [ ] Endpoint GET /productos
- [ ] Filtros (nombre, categoría)
- [ ] Paginación
- [ ] Tests

---

## Historia 3: Editar producto

### Tareas:
- [ ] Endpoint PUT /productos/{id}
- [ ] Validar existencia
- [ ] Tests

---

## Historia 4: Eliminar producto

### Tareas:
- [ ] Endpoint DELETE /productos/{id}
- [ ] Validar dependencias (inventario)
- [ ] Soft delete opcional
- [ ] Tests
