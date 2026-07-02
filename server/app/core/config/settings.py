import os
from typing import List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings"""

    # App
    APP_NAME: str = "ScanPDF API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = int(os.getenv("PORT", "8000"))

    # Database
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://scanpdf:scanpdf_password@localhost:5432/scanpdf"
    )

    # Storage
    UPLOAD_DIR: str = os.getenv("UPLOAD_DIR", "/data/scanpdf/uploads")
    MAX_UPLOAD_SIZE: int = int(os.getenv("MAX_UPLOAD_SIZE", str(50 * 1024 * 1024)))  # 50MB

    # Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))  # 24 hours

    # CORS
    CORS_ORIGINS: List[str] = ["*"]  # Configure properly in production

    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # Base URL
    BASE_URL: str = os.getenv("BASE_URL", "https://jp.zenjan.store")

    # OCR
    OCR_LANGUAGES: List[str] = ["chi_sim", "eng", "jpn", "kor"]

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
