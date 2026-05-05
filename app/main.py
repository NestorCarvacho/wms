from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi

from app.core.config import settings
from app.infrastructure.database import init_db
from app.interfaces.controllers import auth_router, user_router
from app.interfaces.products import product_router

app = FastAPI(
    title=settings.APP_NAME,
    description="API REST para Sistema de Gestión de Almacén (WMS)",
    version=settings.APP_VERSION,
    openapi_url=f"{settings.API_PREFIX}/openapi.json",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inicializar base de datos
@app.on_event("startup")
async def startup():
    """Inicializa la base de datos al arrancar"""
    init_db()

# Routers
app.include_router(auth_router, prefix=settings.API_PREFIX)
app.include_router(user_router, prefix=settings.API_PREFIX)
app.include_router(product_router, prefix=settings.API_PREFIX)

# Health Check
@app.get(
    "/health",
    tags=["Health"],
    summary="Health Check",
    description="Verifica el estado de la API"
)
async def health_check():
    """
    Endpoint para verificar que la API está funcionando correctamente
    """
    return {"status": "ok", "version": settings.APP_VERSION}

# Root
@app.get(
    "/",
    tags=["Root"],
    summary="Información de la API",
    description="Devuelve información general de la API"
)
async def root():
    """
    Endpoint raíz que devuelve información sobre la API
    """
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": f"{settings.API_PREFIX}/docs",
        "redoc": f"{settings.API_PREFIX}/redoc",
    }

# Custom OpenAPI Schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="API REST para Sistema de Gestión de Almacén (WMS) con autenticación JWT",
        routes=app.routes,
    )

    openapi_schema["info"]["x-logo"] = {
        "url": "https://fastapi.tiangolo.com/img/logo-margin/logo-teal.png"
    }

    openapi_schema["servers"] = [
        {
            "url": "http://localhost:8000",
            "description": "Development server"
        },
        {
            "url": "https://api.wms.example.com",
            "description": "Production server"
        }
    ]

    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
