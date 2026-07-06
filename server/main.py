from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config.settings import settings
from app.core.config.database import engine, Base
from app.core.middleware.logging import LoggingMiddleware
from app.api.v1 import documents, auth, ocr, scan

# 创建数据库表（仅在不存在时创建）
Base.metadata.create_all(bind=engine, checkfirst=True)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="ScanPDF 智能扫描办公 - 后端 API",
    docs_url="/api/v1/docs",
    redoc_url="/api/v1/redoc",
    openapi_url="/api/v1/openapi.json"
)

# CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 日志中间件
app.add_middleware(LoggingMiddleware)

# API 路由
app.include_router(documents.router, prefix="/api/v1", tags=["文档管理"])
app.include_router(auth.router, prefix="/api/v1", tags=["用户认证"])
app.include_router(ocr.router, prefix="/api/v1", tags=["OCR 文字识别"])
app.include_router(scan.router, prefix="/api/v1", tags=["扫描处理"])


@app.get("/")
async def root():
    """根路径"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": f"{settings.BASE_URL}/api/v1/docs"
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy", "service": "ScanPDF API"}


@app.get("/api/v1")
async def api_root():
    """API 根路径"""
    return {
        "message": "ScanPDF API v1",
        "endpoints": {
            "documents": "/api/v1/documents",
            "auth": "/api/v1/auth",
            "ocr": "/api/v1/ocr",
            "scan": "/api/v1/scan"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        workers=4 if not settings.DEBUG else 1
    )
