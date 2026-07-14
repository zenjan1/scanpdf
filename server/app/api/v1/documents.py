"""文档管理 API"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import os
import uuid

from app.core.config.database import get_db
from app.models.document import Document
from app.core.config.settings import settings
from app.api.v1.schemas import (
    PaginationParams,
    SortParams,
    DocumentFilterParams,
    PaginatedResponse,
    DocumentUpdateRequest,
    DocumentBatchRequest,
    TagResponse,
)

router = APIRouter()


@router.get("/documents")
async def get_documents(
    page: int = Query(1, ge=1, description="页码"),
    page_size: int = Query(20, ge=1, le=100, description="每页数量"),
    sort_by: str = Query("updated_at", description="排序字段"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$", description="排序方向"),
    title: Optional[str] = Query(None, description="标题搜索"),
    tags: Optional[str] = Query(None, description="标签过滤，逗号分隔"),
    is_favorite: Optional[bool] = Query(None, description="收藏过滤"),
    db: Session = Depends(get_db),
    current_user_id: Optional[str] = Depends(lambda: None),  # TODO: 添加认证
):
    """
    获取文档列表（支持分页、排序、过滤）
    
    - **page**: 页码，默认 1
    - **page_size**: 每页数量，默认 20，最大 100
    - **sort_by**: 排序字段 (updated_at, created_at, title, file_size)
    - **sort_order**: 排序方向 (asc, desc)
    - **title**: 标题搜索关键词
    - **tags**: 标签过滤，逗号分隔
    - **is_favorite**: 收藏状态过滤
    """
    # 构建查询
    query = db.query(Document).filter(Document.is_deleted == False)
    
    # 标题搜索
    if title:
        query = query.filter(Document.title.ilike(f"%{title}%"))
    
    # 标签过滤
    if tags:
        tag_list = [t.strip() for t in tags.split(",") if t.strip()]
        if tag_list:
            # JSON 数组包含查询
            for tag in tag_list:
                query = query.filter(Document.tags.contains([tag]))
    
    # 收藏过滤
    if is_favorite is not None:
        query = query.filter(Document.is_favorite == is_favorite)
    
    # 获取总数
    total = query.count()
    
    # 排序
    sort_column = getattr(Document, sort_by, Document.updated_at)
    if sort_order == "asc":
        query = query.order_by(sort_column.asc())
    else:
        query = query.order_by(sort_column.desc())
    
    # 分页
    offset = (page - 1) * page_size
    documents = query.offset(offset).limit(page_size).all()
    
    # 计算分页信息
    total_pages = (total + page_size - 1) // page_size
    
    return {
        "data": [doc.to_dict() for doc in documents],
        "pagination": {
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": total_pages,
            "has_next": page < total_pages,
            "has_prev": page > 1,
        }
    }


@router.get("/documents/{document_id}")
async def get_document(document_id: str, db: Session = Depends(get_db)):
    """获取文档详情"""
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.is_deleted == False
    ).first()

    if not document:
        raise HTTPException(status_code=404, detail="文档不存在")

    return {"data": document.to_dict()}


@router.post("/documents")
async def create_document(
    title: str = Form(...),
    tags: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """创建新文档"""
    # 验证文件类型
    allowed_types = ["application/pdf", "image/jpeg", "image/png", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400, 
            detail=f"不支持的文件类型: {file.content_type}"
        )
    
    # 验证文件大小
    content = await file.read()
    if len(content) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"文件过大，最大允许 {settings.MAX_UPLOAD_SIZE // (1024*1024)}MB"
        )
    
    # 生成唯一 ID
    doc_id = str(uuid.uuid4())

    # 创建上传目录
    upload_dir = os.path.join(settings.UPLOAD_DIR, "documents")
    os.makedirs(upload_dir, exist_ok=True)

    # 保存文件
    file_ext = os.path.splitext(file.filename or ".pdf")[1]
    file_path = os.path.join(upload_dir, f"{doc_id}{file_ext}")

    with open(file_path, "wb") as f:
        f.write(content)

    # 解析标签
    tags_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []

    # 创建文档记录
    document = Document(
        id=doc_id,
        title=title,
        tags=tags_list,
        file_path=file_path,
        file_size=len(content),
        mime_type=file.content_type,
        page_count=1,
    )

    db.add(document)
    db.commit()
    db.refresh(document)

    return {"data": document.to_dict(), "message": "文档创建成功"}


@router.put("/documents/{document_id}")
async def update_document(
    document_id: str,
    request: DocumentUpdateRequest,
    db: Session = Depends(get_db)
):
    """更新文档"""
    document = db.query(Document).filter(Document.id == document_id).first()

    if not document:
        raise HTTPException(status_code=404, detail="文档不存在")

    if request.title is not None:
        document.title = request.title
    if request.tags is not None:
        document.tags = request.tags
    if request.is_favorite is not None:
        document.is_favorite = request.is_favorite

    document.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(document)

    return {"data": document.to_dict(), "message": "文档更新成功"}


@router.delete("/documents/{document_id}")
async def delete_document(document_id: str, db: Session = Depends(get_db)):
    """软删除文档（移入回收站）"""
    document = db.query(Document).filter(Document.id == document_id).first()

    if not document:
        raise HTTPException(status_code=404, detail="文档不存在")

    document.is_deleted = True
    document.updated_at = datetime.utcnow()

    db.commit()

    return {"message": "文档已移入回收站"}


@router.post("/documents/batch/delete")
async def batch_delete_documents(
    request: DocumentBatchRequest,
    db: Session = Depends(get_db)
):
    """批量删除文档"""
    documents = db.query(Document).filter(
        Document.id.in_(request.document_ids)
    ).all()
    
    if not documents:
        raise HTTPException(status_code=404, detail="未找到文档")
    
    for doc in documents:
        doc.is_deleted = True
        doc.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "message": f"已删除 {len(documents)} 个文档",
        "deleted_count": len(documents)
    }


@router.post("/documents/batch/favorite")
async def batch_toggle_favorite(
    request: DocumentBatchRequest,
    is_favorite: bool = Form(True),
    db: Session = Depends(get_db)
):
    """批量切换收藏状态"""
    documents = db.query(Document).filter(
        Document.id.in_(request.document_ids)
    ).all()
    
    if not documents:
        raise HTTPException(status_code=404, detail="未找到文档")
    
    for doc in documents:
        doc.is_favorite = is_favorite
        doc.updated_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "message": f"已更新 {len(documents)} 个文档的收藏状态",
        "updated_count": len(documents)
    }


@router.post("/documents/{document_id}/restore")
async def restore_document(document_id: str, db: Session = Depends(get_db)):
    """从回收站恢复文档"""
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.is_deleted == True
    ).first()

    if not document:
        raise HTTPException(status_code=404, detail="文档不存在或未被删除")

    document.is_deleted = False
    document.updated_at = datetime.utcnow()

    db.commit()

    return {"message": "文档已恢复"}


@router.get("/documents/search/{query}")
async def search_documents(
    query: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """搜索文档"""
    base_query = db.query(Document).filter(
        Document.title.ilike(f"%{query}%"),
        Document.is_deleted == False
    )
    
    total = base_query.count()
    documents = base_query.order_by(Document.updated_at.desc())\
        .offset((page - 1) * page_size)\
        .limit(page_size)\
        .all()
    
    return {
        "data": [doc.to_dict() for doc in documents],
        "pagination": {
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size,
            "has_next": page < (total + page_size - 1) // page_size,
            "has_prev": page > 1,
        }
    }


@router.get("/tags/list")
async def get_tags(db: Session = Depends(get_db)):
    """获取所有标签及其使用次数"""
    documents = db.query(Document).filter(
        Document.is_deleted == False,
        Document.tags.isnot(None)
    ).all()
    
    tag_counts = {}
    for doc in documents:
        if doc.tags:
            for tag in doc.tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1
    
    tags = [
        TagResponse(name=name, count=count)
        for name, count in sorted(tag_counts.items(), key=lambda x: -x[1])
    ]
    
    return {"data": [t.dict() for t in tags]}


@router.get("/recycle-bin")
async def get_recycle_bin(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """获取回收站文档"""
    base_query = db.query(Document).filter(Document.is_deleted == True)
    
    total = base_query.count()
    documents = base_query.order_by(Document.updated_at.desc())\
        .offset((page - 1) * page_size)\
        .limit(page_size)\
        .all()
    
    return {
        "data": [doc.to_dict() for doc in documents],
        "pagination": {
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size,
            "has_next": page < (total + page_size - 1) // page_size,
            "has_prev": page > 1,
        }
    }


@router.delete("/recycle-bin/empty")
async def empty_recycle_bin(db: Session = Depends(get_db)):
    """清空回收站（永久删除）"""
    documents = db.query(Document).filter(Document.is_deleted == True).all()
    
    for doc in documents:
        # 删除实际文件
        try:
            if doc.file_path and os.path.exists(doc.file_path):
                os.remove(doc.file_path)
            if doc.thumbnail_path and os.path.exists(doc.thumbnail_path):
                os.remove(doc.thumbnail_path)
        except OSError:
            pass
        
        db.delete(doc)
    
    db.commit()
    
    return {"message": f"已永久删除 {len(documents)} 个文档"}
