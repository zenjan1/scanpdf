from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional
import os
import uuid

from app.services.ocr_service import OCRService
from app.services.image_processor import ImageProcessor
from app.core.config.settings import settings

router = APIRouter()
ocr_service = OCRService()
image_processor = ImageProcessor()


@router.post("/ocr/extract")
async def extract_text(
    file: UploadFile = File(...),
    language: Optional[str] = Form("chi_sim+eng"),
    preprocess: Optional[bool] = Form(True),
):
    """从上传图片中提取文字"""
    try:
        # 保存上传文件
        upload_dir = os.path.join(settings.UPLOAD_DIR, "ocr_temp")
        os.makedirs(upload_dir, exist_ok=True)

        file_id = str(uuid.uuid4())
        file_ext = os.path.splitext(file.filename or ".jpg")[1]
        file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        # 预处理
        if preprocess:
            file_path = await image_processor.enhance_document(
                file_path, file_path.replace(file_ext, f"_enhanced{file_ext}")
            )

        # OCR
        result = await ocr_service.extract_text(file_path, language)

        # 清理临时文件
        try:
            os.remove(file_path)
        except OSError:
            pass

        return {"data": result}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
