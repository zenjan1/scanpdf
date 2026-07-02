from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
from datetime import datetime

from app.core.config.database import get_db
from app.models.document import Document
from app.core.config.settings import settings

router = APIRouter()


@router.get("/documents")
async def get_documents(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all documents"""
    documents = db.query(Document).filter(
        Document.is_deleted == False
    ).order_by(Document.updated_at.desc()).offset(skip).limit(limit).all()
    return {"data": [doc.to_dict() for doc in documents]}


@router.get("/documents/{document_id}")
async def get_document(document_id: str, db: Session = Depends(get_db)):
    """Get a specific document"""
    document = db.query(Document).filter(
        Document.id == document_id,
        Document.is_deleted == False
    ).first()

    if not document:
        raise HTTPException(status_code=404, detail="Document not found")

    return {"data": document.to_dict()}


@router.post("/documents")
async def create_document(
    title: str = Form(...),
    tags: Optional[str] = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Create a new document"""
    # Generate unique ID
    doc_id = str(uuid.uuid4())

    # Create upload directory if not exists
    upload_dir = os.path.join(settings.UPLOAD_DIR, "documents")
    os.makedirs(upload_dir, exist_ok=True)

    # Save file
    file_ext = os.path.splitext(file.filename)[1]
    file_path = os.path.join(upload_dir, f"{doc_id}{file_ext}")

    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    # Parse tags
    tags_list = tags.split(",") if tags else []

    # Create document record
    document = Document(
        id=doc_id,
        title=title,
        tags=tags_list,
        file_path=file_path,
        file_size=len(content),
        mime_type=file.content_type,
        page_count=1,  # Will be updated if PDF
    )

    db.add(document)
    db.commit()
    db.refresh(document)

    return {"data": document.to_dict(), "message": "Document created successfully"}


@router.put("/documents/{document_id}")
async def update_document(
    document_id: str,
    title: Optional[str] = Form(None),
    tags: Optional[str] = Form(None),
    is_favorite: Optional[bool] = Form(None),
    db: Session = Depends(get_db)
):
    """Update a document"""
    document = db.query(Document).filter(Document.id == document_id).first()

    if not document:
        raise HTTPException(status_code=404, detail="Document not found")

    if title is not None:
        document.title = title
    if tags is not None:
        document.tags = tags.split(",")
    if is_favorite is not None:
        document.is_favorite = is_favorite

    document.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(document)

    return {"data": document.to_dict(), "message": "Document updated successfully"}


@router.delete("/documents/{document_id}")
async def delete_document(document_id: str, db: Session = Depends(get_db)):
    """Soft delete a document"""
    document = db.query(Document).filter(Document.id == document_id).first()

    if not document:
        raise HTTPException(status_code=404, detail="Document not found")

    document.is_deleted = True
    document.updated_at = datetime.utcnow()

    db.commit()

    return {"message": "Document deleted successfully"}


@router.get("/documents/search/{query}")
async def search_documents(query: str, db: Session = Depends(get_db)):
    """Search documents by title"""
    documents = db.query(Document).filter(
        Document.title.ilike(f"%{query}%"),
        Document.is_deleted == False
    ).order_by(Document.updated_at.desc()).all()

    return {"data": [doc.to_dict() for doc in documents]}
