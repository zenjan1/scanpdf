"""API 请求/响应模型"""
from pydantic import BaseModel, Field
from typing import Optional, List, Generic, TypeVar
from datetime import datetime

T = TypeVar('T')


class PaginationParams(BaseModel):
    """分页参数"""
    page: int = Field(1, ge=1, description="页码")
    page_size: int = Field(20, ge=1, le=100, description="每页数量")
    
    @property
    def offset(self) -> int:
        return (self.page - 1) * self.page_size


class SortParams(BaseModel):
    """排序参数"""
    sort_by: str = Field("updated_at", description="排序字段")
    sort_order: str = Field("desc", pattern="^(asc|desc)$", description="排序方向")


class DocumentFilterParams(BaseModel):
    """文档过滤参数"""
    title: Optional[str] = None
    tags: Optional[List[str]] = None
    is_favorite: Optional[bool] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    mime_type: Optional[str] = None


class PaginatedResponse(BaseModel, Generic[T]):
    """分页响应"""
    data: List[T]
    total: int
    page: int
    page_size: int
    total_pages: int
    has_next: bool
    has_prev: bool


class DocumentCreateRequest(BaseModel):
    """创建文档请求"""
    title: str = Field(..., min_length=1, max_length=255)
    tags: Optional[List[str]] = Field(default_factory=list)
    page_count: int = Field(1, ge=1)


class DocumentUpdateRequest(BaseModel):
    """更新文档请求"""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    tags: Optional[List[str]] = None
    is_favorite: Optional[bool] = None


class DocumentBatchRequest(BaseModel):
    """批量操作请求"""
    document_ids: List[str] = Field(..., min_length=1, max_length=100)


class TagResponse(BaseModel):
    """标签响应"""
    name: str
    count: int


class UserRegisterRequest(BaseModel):
    """用户注册请求"""
    email: str = Field(..., min_length=5, max_length=255)
    password: str = Field(..., min_length=6, max_length=128)
    username: Optional[str] = Field(None, min_length=2, max_length=50)


class UserLoginRequest(BaseModel):
    """用户登录请求"""
    email: str
    password: str


class TokenResponse(BaseModel):
    """Token 响应"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    expires_in: int = Field(description="过期时间（秒）")
    user_id: str


class RefreshTokenRequest(BaseModel):
    """刷新 Token 请求"""
    refresh_token: str


class PasswordResetRequest(BaseModel):
    """密码重置请求"""
    email: str


class PasswordResetConfirm(BaseModel):
    """密码重置确认"""
    token: str
    new_password: str = Field(..., min_length=6, max_length=128)


class PasswordChangeRequest(BaseModel):
    """修改密码请求"""
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=128)
