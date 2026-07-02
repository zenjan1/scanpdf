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
    # TODO: check existing user, insert new user
    user_id = str(uuid.uuid4())
    hashed = get_password_hash(req.password)
    # user = User(id=user_id, email=req.email, ...)
    # db.add(user)
    # db.commit()

    return {
        "data": {"user_id": user_id, "email": req.email},
        "message": "注册成功"
    }


@router.post("/auth/login")
async def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    """用户登录"""
    # TODO: find user, verify password
    # user = db.query(User).filter(User.email == req.email).first()
    # if not user or not verify_password(req.password, user.hashed_password):
    #     raise HTTPException(status_code=401, detail="邮箱或密码错误")

    user_id = "demo-user-id"
    access_token = create_access_token(
        data={"sub": user_id, "email": req.email}
    )
    return TokenResponse(access_token=access_token, user_id=user_id)


@router.post("/auth/refresh")
async def refresh_token():
    """刷新令牌"""
    return {"message": "Token refreshed"}
