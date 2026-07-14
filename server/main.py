"""ScanPDF 后端服务"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from app.core.config.settings import settings
from app.core.config.database import engine, Base
from app.core.middleware.logging import LoggingMiddleware
from app.api.v1 import documents, auth, ocr, scan

# 创建数据库表（仅在不存在时创建）
Base.metadata.create_all(bind=engine, checkfirst=True)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="ScanPDF 智能扫描办公 - 后端 API\n\n## 功能模块\n\n- **文档管理**: 文档 CRUD、批量操作、回收站、标签管理\n- **用户认证**: 注册、登录、Token 刷新、密码重置\n- **OCR 文字识别**: 多语言识别、图片预处理\n- **扫描处理**: 边缘检测、透视矫正、文档增强",
    docs_url="/api/v1/docs",
    redoc_url="/api/v1/redoc",
    openapi_url="/api/v1/openapi.json",
    contact={
        "name": "ScanPDF Support",
        "email": "admin@zenjan.store",
    },
    license_info={
        "name": "MIT",
    },
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


@app.get("/", tags=["系统"])
async def root():
    """根路径"""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": f"{settings.BASE_URL}/api/v1/docs",
    }


@app.get("/health", tags=["系统"])
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "ScanPDF API",
        "version": settings.APP_VERSION,
    }


@app.get("/api/v1", tags=["系统"])
async def api_root():
    """API 根路径"""
    return {
        "message": "ScanPDF API v1",
        "endpoints": {
            "documents": "/api/v1/documents",
            "auth": "/api/v1/auth",
            "ocr": "/api/v1/ocr",
            "scan": "/api/v1/scan",
            "tags": "/api/v1/tags/list",
            "recycle_bin": "/api/v1/recycle-bin",
        },
        "features": {
            "pagination": "支持分页查询",
            "filtering": "支持多条件过滤",
            "batch_operations": "支持批量操作",
            "recycle_bin": "软删除 + 回收站",
            "token_refresh": "支持 Token 刷新",
        }
    }


# 错误处理
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """全局异常处理"""
    return {
        "error": "服务器内部错误",
        "detail": str(exc) if settings.DEBUG else "请稍后重试",
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
