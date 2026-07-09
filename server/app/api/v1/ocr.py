from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import Optional, List
import os
import uuid

from app.services.ocr_service import OCRService, PreprocessMode
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
    preprocess_mode: Optional[str] = Form("auto"),
    psm: Optional[int] = Form(-1),
):
    """
    从上传图片中提取文字

    - **language**: OCR语言，支持 chi_sim, eng, jpn, kor 等，可用+组合
    - **preprocess**: 是否启用图片预处理
    - **preprocess_mode**: 预处理模式 (none/auto/grayscale/high_contrast/binarize/de_shadow)
    - **psm**: Tesseract页面分割模式 (-1为自动)
    """
    try:
        # 验证预处理模式
        if preprocess_mode not in PreprocessMode._value2member_map_:
            preprocess_mode = "auto"

        # 保存上传文件
        upload_dir = os.path.join(settings.UPLOAD_DIR, "ocr_temp")
        os.makedirs(upload_dir, exist_ok=True)

        file_id = str(uuid.uuid4())
        file_ext = os.path.splitext(file.filename or ".jpg")[1]
        file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        # OCR（内置预处理）
        result = await ocr_service.extract_text(
            file_path,
            language=language,
            preprocess=preprocess,
            preprocess_mode=preprocess_mode,
            psm=psm,
        )

        # 清理临时文件
        try:
            os.remove(file_path)
        except OSError:
            pass

        # 如果OCR失败，返回错误信息
        if not result.get('success', False):
            raise HTTPException(
                status_code=400,
                detail=result.get('error', 'OCR识别失败')
            )

        return {"data": result}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR服务异常: {str(e)}")


@router.post("/ocr/extract-batch")
async def extract_text_batch(
    files: List[UploadFile] = File(...),
    language: Optional[str] = Form("chi_sim+eng"),
    preprocess: Optional[bool] = Form(True),
    preprocess_mode: Optional[str] = Form("auto"),
):
    """
    批量OCR识别 - 支持多张图片

    返回按顺序的识别结果列表
    """
    try:
        upload_dir = os.path.join(settings.UPLOAD_DIR, "ocr_temp")
        os.makedirs(upload_dir, exist_ok=True)

        # 保存所有上传文件
        file_paths = []
        for file in files:
            file_id = str(uuid.uuid4())
            file_ext = os.path.splitext(file.filename or ".jpg")[1]
            file_path = os.path.join(upload_dir, f"{file_id}{file_ext}")

            content = await file.read()
            with open(file_path, "wb") as f:
                f.write(content)
            file_paths.append(file_path)

        # 批量OCR
        results = await ocr_service.extract_text_batch(
            file_paths,
            language=language,
            preprocess=preprocess,
            preprocess_mode=preprocess_mode,
        )

        # 清理临时文件
        for file_path in file_paths:
            try:
                os.remove(file_path)
            except OSError:
                pass

        # 合并统计信息
        total_chars = sum(r.get('total_characters', 0) for r in results)
        total_words = sum(r.get('total_words', 0) for r in results)
        success_count = sum(1 for r in results if r.get('success', False))

        return {
            "data": {
                "results": results,
                "total_pages": len(results),
                "success_pages": success_count,
                "total_characters": total_chars,
                "total_words": total_words,
            }
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"批量OCR服务异常: {str(e)}")


@router.get("/ocr/languages")
async def get_supported_languages():
    """获取支持的OCR语言列表"""
    return {
        "data": {
            "languages": [
                {"code": code, "name": name}
                for code, name in ocr_service.supported_languages.items()
            ],
            "presets": [
                {"code": code, "name": name, "language_string": lang_str}
                for code, name in [
                    ("chi_eng", "中英文"),
                    ("chi_only", "仅中文"),
                    ("eng_only", "仅英文"),
                    ("ja_eng", "日文+英文"),
                    ("ko_eng", "韩文+英文"),
                    ("all", "所有语言"),
                ]
                for lang_str in [ocr_service.language_presets.get(code, "")]
            ],
        }
    }
