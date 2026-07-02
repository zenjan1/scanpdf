from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional, List
import os
import uuid

from app.services.image_processor import ImageProcessor
from app.services.pdf_service import PDFService
from app.core.config.settings import settings

router = APIRouter()
image_processor = ImageProcessor()
pdf_service = PDFService()


@router.post("/scan/detect-edges")
async def detect_edges(file: UploadFile = File(...)):
    """检测文档边缘"""
    try:
        upload_dir = os.path.join(settings.UPLOAD_DIR, "scan_temp")
        os.makedirs(upload_dir, exist_ok=True)

        file_id = str(uuid.uuid4())
        file_ext = os.path.splitext(file.filename or ".jpg")[1]
        file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        corners = image_processor.detect_edges(file_path)

        os.remove(file_path)

        return {"data": {"corners": corners, "file_id": file_id}}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scan/correct-perspective")
async def correct_perspective(
    file: UploadFile = File(...),
    corners: str = Form(...),
):
    """透视矫正"""
    try:
        import json
        corner_points = json.loads(corners)

        upload_dir = os.path.join(settings.UPLOAD_DIR, "scan_temp")
        os.makedirs(upload_dir, exist_ok=True)

        file_id = str(uuid.uuid4())
        file_ext = os.path.splitext(file.filename or ".jpg")[1]
        file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")
        output_path = os.path.join(upload_dir, f"{file_id}_corrected{file_ext}")

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        image_processor.perspective_transform(file_path, corner_points, output_path)

        # 返回矫正后的文件
        from fastapi.responses import FileResponse
        return FileResponse(output_path, filename=f"corrected{file_ext}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scan/enhance")
async def enhance_image(file: UploadFile = File(...)):
    """文档增强"""
    try:
        upload_dir = os.path.join(settings.UPLOAD_DIR, "scan_temp")
        os.makedirs(upload_dir, exist_ok=True)

        file_id = str(uuid.uuid4())
        file_ext = os.path.splitext(file.filename or ".jpg")[1]
        file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")
        output_path = os.path.join(upload_dir, f"{file_id}_enhanced{file_ext}")

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        image_processor.enhance_document(file_path, output_path)

        from fastapi.responses import FileResponse
        return FileResponse(output_path, filename=f"enhanced{file_ext}")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
