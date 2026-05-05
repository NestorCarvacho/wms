# API: Búsqueda, Filtros y Paginación de Productos

## Endpoint: GET /api/v1/productos

### Parámetros Disponibles

#### 🔍 Búsqueda
- `search` (string, opcional): Busca en nombre, descripción y SKU
  - Ejemplo: `search=laptop`
  - Busca: nombre ILIKE "%laptop%" OR descripción ILIKE "%laptop%" OR sku ILIKE "%laptop%"

#### 🏷️ Filtros
- `category` (string, opcional): Filtra por categoría exacta
  - Ejemplo: `category=Electrónica`

- `min_price` (number, opcional): Precio mínimo
  - Ejemplo: `min_price=100`

- `max_price` (number, opcional): Precio máximo
  - Ejemplo: `max_price=2000`

- `in_stock` (boolean, opcional): Solo productos con stock > 0
  - Ejemplo: `in_stock=true`

- `is_active` (boolean, default: true): Solo productos activos
  - Ejemplo: `is_active=true`

#### 📊 Ordenamiento
- `sort_by` (enum, default: "name"): Campo para ordenar
  - Valores: `name`, `price`, `stock`, `created_at`
  - Ejemplo: `sort_by=price`

- `sort_order` (enum, default: "asc"): Dirección
  - Valores: `asc`, `desc`
  - Ejemplo: `sort_order=desc`

#### 📄 Paginación
- `skip` (integer, default: 0, min: 0): Registros a saltar
  - Ejemplo: `skip=20`

- `limit` (integer, default: 20, min: 1, max: 100): Registros por página
  - Ejemplo: `limit=50`

---

## Ejemplos de Uso

### 1. Búsqueda Simple
```
GET /api/v1/productos?search=laptop
```
**Busca:** "laptop" en nombre, descripción o SKU

**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "sku": "PROD-001",
      "name": "Laptop Dell XPS",
      "price": 1299.99,
      "stock": 10,
      ...
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

---

### 2. Filtro por Categoría
```
GET /api/v1/productos?category=Electrónica
```
**Filtra:** Solo productos de la categoría "Electrónica"

---

### 3. Rango de Precios
```
GET /api/v1/productos?min_price=500&max_price=2000
```
**Filtra:** Productos entre $500 y $2000

---

### 4. Solo Productos con Stock
```
GET /api/v1/productos?in_stock=true
```
**Filtra:** Solo productos donde stock > 0

---

### 5. Búsqueda + Filtros Combinados
```
GET /api/v1/productos?search=dell&category=Electrónica&min_price=800&in_stock=true
```
**Busca:** "dell" en nombre/descripción/SKU  
**Filtra:** Categoría "Electrónica", precio >= $800, stock > 0

---

### 6. Ordenar por Precio (Menor a Mayor)
```
GET /api/v1/productos?sort_by=price&sort_order=asc
```
**Ordena:** Por precio ascendente

---

### 7. Ordenar por Precio (Mayor a Menor)
```
GET /api/v1/productos?sort_by=price&sort_order=desc
```
**Ordena:** Por precio descendente

---

### 8. Productos Más Nuevos Primero
```
GET /api/v1/productos?sort_by=created_at&sort_order=desc
```
**Ordena:** Por fecha de creación descendente

---

### 9. Productos por Stock (Menor cantidad primero)
```
GET /api/v1/productos?sort_by=stock&sort_order=asc
```
**Ordena:** Por stock ascendente

---

### 10. Paginación: Primera Página
```
GET /api/v1/productos?skip=0&limit=20
```
**Obtiene:** Primeros 20 productos (página 1)

---

### 11. Paginación: Segunda Página
```
GET /api/v1/productos?skip=20&limit=20
```
**Obtiene:** Productos 21-40 (página 2)

---

### 12. Paginación: 50 Resultados por Página
```
GET /api/v1/productos?skip=0&limit=50
```
**Obtiene:** Primeros 50 productos

---

### 13. Búsqueda Avanzada Completa
```
GET /api/v1/productos?search=laptop&category=Electrónica&min_price=1000&max_price=2000&in_stock=true&sort_by=price&sort_order=asc&skip=0&limit=20
```

**Busca:** "laptop" en nombre/descripción/SKU  
**Filtra:**
- Categoría: Electrónica
- Precio: $1000 - $2000
- Stock: > 0
- Activos: sí

**Ordena:** Por precio ascendente  
**Pagina:** Primeros 20 resultados

**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "sku": "PROD-001",
      "name": "Laptop Dell XPS",
      "description": "Laptop de alta performance",
      "category": "Electrónica",
      "price": 1299.99,
      "stock": 10,
      "is_active": true,
      "created_at": "2024-01-15T10:30:00",
      "updated_at": "2024-01-15T10:30:00"
    },
    {
      "id": 2,
      "sku": "PROD-002",
      "name": "Laptop HP Pavilion",
      "description": "Laptop versátil",
      "category": "Electrónica",
      "price": 1499.99,
      "stock": 5,
      "is_active": true,
      "created_at": "2024-01-16T14:20:00",
      "updated_at": "2024-01-16T14:20:00"
    }
  ],
  "total": 2,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

---

## Para una Barra de Búsqueda (Frontend)

### Implementación Simple
```javascript
// Búsqueda en tiempo real
async function searchProducts(query) {
  const response = await fetch(
    `/api/v1/productos?search=${encodeURIComponent(query)}&limit=10`
  );
  const data = await response.json();
  return data.items;
}

// Usuarios escriben: "laptop"
// Se envía: /api/v1/productos?search=laptop&limit=10
// Se obtienen: Los 10 primeros resultados
```

### Búsqueda + Filtros
```javascript
async function searchWithFilters(filters) {
  const params = new URLSearchParams({
    ...(filters.search && { search: filters.search }),
    ...(filters.category && { category: filters.category }),
    ...(filters.minPrice && { min_price: filters.minPrice }),
    ...(filters.maxPrice && { max_price: filters.maxPrice }),
    ...(filters.inStock && { in_stock: filters.inStock }),
    sort_by: filters.sortBy || 'name',
    sort_order: filters.sortOrder || 'asc',
    skip: filters.page * filters.limit || 0,
    limit: filters.limit || 20
  });

  const response = await fetch(`/api/v1/productos?${params}`);
  return await response.json();
}
```

---

## Optimizaciones Implementadas

✅ **Búsqueda de Texto Completo:** Busca en múltiples campos (nombre, descripción, SKU)  
✅ **Filtros Independientes:** Combina cualquier filtro sin limitaciones  
✅ **Paginación Eficiente:** Limit máximo de 100 para evitar carga excesiva  
✅ **Ordenamiento Flexible:** Múltiples campos y direcciones  
✅ **Case-Insensitive:** Búsquedas sin distinción de mayúsculas/minúsculas  
✅ **Validaciones:** Límites en parámetros para seguridad  

---

## Límites y Restricciones

| Parámetro | Min | Max | Default |
|-----------|-----|-----|---------|
| `limit` | 1 | 100 | 20 |
| `skip` | 0 | ∞ | 0 |
| `search` | - | 100 caracteres | - |
| `min_price` | 0 | - | - |
| `max_price` | 0 | - | - |

