"""用户认证 API - 支持注册、登录、Token 刷新、密码重置"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import Optional
import uuid
import secrets

from app.core.config.database import get_db
from app.core.config.settings import settings
from app.core.security.auth import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.models.user import User
from app.api.v1.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    PasswordResetRequest,
    PasswordResetConfirm,
    PasswordChangeRequest,
)

router = APIRouter()

# 简单的密码重置令牌存储（生产环境应使用 Redis 或数据库）
_password_reset_tokens: dict = {}


@router.post("/auth/register")
async def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    """
    用户注册
    
    - 邮箱必须唯一
    - 密码至少 6 位
    - 用户名可选
    """
    # 检查邮箱是否已注册
    existing_user = db.query(User).filter(User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="该邮箱已注册")
    
    user_id = str(uuid.uuid4())
    
    # bcrypt 密码最长 72 字节
    pwd = req.password[:72]
    hashed = get_password_hash(pwd)
    
    new_user = User(
        id=user_id,
        email=req.email,
        username=req.username or "",
        hashed_password=hashed
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # 生成 token
    access_token = create_access_token(
        data={"sub": user_id, "email": req.email}
    )
    refresh_token = create_refresh_token(
        data={"sub": user_id, "type": "refresh"}
    )
    
    return {
        "data": {
            "user": new_user.to_dict(),
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        },
        "message": "注册成功"
    }


@router.post("/auth/login")
async def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    """
    用户登录
    
    - 支持邮箱+密码登录
    - 返回 access_token 和 refresh_token
    - 演示模式：未注册邮箱自动创建
    """
    # 查询用户
    user = db.query(User).filter(User.email == req.email).first()
    
    if not user:
        # 演示模式：为任意邮箱生成 token
        user_id = "demo-" + str(uuid.uuid4())[:8]
        access_token = create_access_token(data={"sub": user_id, "email": req.email})
        refresh_token = create_refresh_token(data={"sub": user_id, "type": "refresh"})
        return {
            "data": {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer",
                "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
                "user_id": user_id,
                "is_demo": True,
            }
        }
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="用户已被禁用")
    
    pwd = req.password[:72]
    if not verify_password(pwd, user.hashed_password):
        raise HTTPException(status_code=401, detail="密码错误")
    
    access_token = create_access_token(data={"sub": user.id, "email": user.email})
    refresh_token = create_refresh_token(data={"sub": user.id, "type": "refresh"})
    
    return {
        "data": {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            "user_id": user.id,
            "user": user.to_dict(),
        }
    }


@router.post("/auth/refresh")
async def refresh_token(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    刷新访问令牌
    
    - 使用 refresh_token 获取新的 access_token
    - refresh_token 有效期更长
    """
    try:
        payload = decode_token(req.refresh_token)
        
        # 验证 token 类型
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=400, detail="无效的刷新令牌")
        
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=400, detail="无效的刷新令牌")
        
        # 查询用户
        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(status_code=401, detail="用户不存在或已被禁用")
        
        # 生成新的 access_token
        new_access_token = create_access_token(
            data={"sub": user.id, "email": user.email}
        )
        
        return {
            "data": {
                "access_token": new_access_token,
                "token_type": "bearer",
                "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"令牌无效: {str(e)}")


@router.post("/auth/password-reset/request")
async def request_password_reset(req: PasswordResetRequest, db: Session = Depends(get_db)):
    """
    请求密码重置
    
    - 发送重置链接到邮箱（演示模式：直接返回 token）
    - Token 有效期 1 小时
    """
    user = db.query(User).filter(User.email == req.email).first()
    
    # 即使用户不存在也返回成功（防止邮箱枚举）
    if not user:
        return {"message": "如果邮箱已注册，您将收到密码重置邮件"}
    
    # 生成重置 token
    reset_token = secrets.token_urlsafe(32)
    _password_reset_tokens[reset_token] = {
        "user_id": user.id,
        "email": user.email,
        "expires_at": None,  # 简化版，生产环境应设置过期时间
    }
    
    # 生产环境应发送邮件
    return {
        "message": "密码重置链接已发送到您的邮箱",
        "data": {
            "reset_token": reset_token,  # 演示模式：直接返回 token
            "expires_in": 3600,
        }
    }


@router.post("/auth/password-reset/confirm")
async def confirm_password_reset(req: PasswordResetConfirm, db: Session = Depends(get_db)):
    """
    确认密码重置
    
    - 使用重置 token 设置新密码
    """
    token_data = _password_reset_tokens.get(req.token)
    
    if not token_data:
        raise HTTPException(status_code=400, detail="无效的重置令牌")
    
    user_id = token_data["user_id"]
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    
    # 更新密码
    pwd = req.new_password[:72]
    user.hashed_password = get_password_hash(pwd)
    
    db.commit()
    
    # 删除使用的 token
    del _password_reset_tokens[req.token]
    
    return {"message": "密码重置成功"}


@router.post("/auth/password/change")
async def change_password(
    req: PasswordChangeRequest,
    db: Session = Depends(get_db),
    # current_user: User = Depends(get_current_user),  # TODO: 添加认证依赖
):
    """
    修改密码（需要登录）
    
    - 需要验证旧密码
    """
    # TODO: 从认证中获取当前用户
    # user = current_user
    
    # 演示模式：暂时禁用此端点
    raise HTTPException(
        status_code=501, 
        detail="此功能需要完整的认证系统，请使用密码重置功能"
    )


@router.get("/auth/me")
async def get_current_user_info(
    db: Session = Depends(get_db),
    # current_user: User = Depends(get_current_user),  # TODO: 添加认证依赖
):
    """
    获取当前用户信息
    
    - 需要 Bearer Token 认证
    """
    # TODO: 实现完整的认证
    return {
        "message": "此端点需要完整的认证系统",
        "data": None
    }


@router.post("/auth/logout")
async def logout():
    """
    用户登出
    
    - 客户端应清除本地存储的 token
    - 服务端可选：将 token 加入黑名单
    """
    return {"message": "登出成功"}
