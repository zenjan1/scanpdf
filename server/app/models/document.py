from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from app.core.config.database import Base


class Document(Base):
    """Document model for database"""

    __tablename__ = "documents"

    id = Column(String, primary_key=True, index=True)
    title = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    page_count = Column(Integer, nullable=False, default=1)
    tags = Column(JSON, default=list)
    file_path = Column(String, nullable=False)
    thumbnail_path = Column(String)
    is_favorite = Column(Boolean, default=False)
    is_deleted = Column(Boolean, default=False)
    user_id = Column(String, nullable=True, index=True)
    file_size = Column(Integer, nullable=True)  # in bytes
    mime_type = Column(String, nullable=True)

    def to_dict(self):
        """Convert to dictionary"""
        return {
            "id": self.id,
            "title": self.title,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "page_count": self.page_count,
            "tags": self.tags or [],
            "file_path": self.file_path,
            "thumbnail_path": self.thumbnail_path,
            "is_favorite": self.is_favorite,
            "is_deleted": self.is_deleted,
            "user_id": self.user_id,
            "file_size": self.file_size,
            "mime_type": self.mime_type,
        }
