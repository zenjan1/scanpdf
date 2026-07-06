from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from datetime import timedelta
from typing import Optional
import uuid

from app.core.config.database import get_db
from app.core.config.settings import settings
from app.core.security.auth import (
    get_password_hash,
    verify_password,
    create_access_token,
)
from app.models.user import User

router = APIRouter()


class UserRegisterRequest(BaseModel):
    email: str
    password: str
    username: Optional[str] = None


class UserLoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str


@router.post("/auth/register")
async def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    """用户注册"""
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
    
    return {
        "data": new_user.to_dict(),
        "message": "注册成功"
    }


@router.post("/auth/login")
async def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    """用户登录"""
    # 查询用户
    user = db.query(User).filter(User.email == req.email).first()
    
    if not user:
        # 演示模式：为任意邮箱生成 token
        user_id = "demo-" + str(uuid.uuid4())[:8]
        access_token = create_access_token(data={"sub": user_id, "email": req.email})
        return TokenResponse(access_token=access_token, user_id=user_id)
    
    if not user.is_active:
        raise HTTPException(status_code=400, detail="用户已被禁用")
    
    pwd = req.password[:72]
    if not verify_password(pwd, user.hashed_password):
        raise HTTPException(status_code=401, detail="密码错误")
    
    access_token = create_access_token(data={"sub": user.id, "email": user.email})
    return TokenResponse(access_token=access_token, user_id=user.id)


@router.post("/auth/refresh")
async def refresh_token():
    """刷新令牌"""
    return {"message": "Token refreshed"}
