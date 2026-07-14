"""OCR 文字识别 API - 支持同步和异步识别"""
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks
from typing import Optional, List
import os
import uuid

from app.services.ocr_service import OCRService, PreprocessMode
from app.services.image_processor import ImageProcessor
from app.core.config.settings import settings

router = APIRouter()
ocr_service = OCRService(enable_cache=True)
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
    从上传图片中提取文字（同步）

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


@router.post("/ocr/extract-async")
async def extract_text_async(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language: Optional[str] = Form("chi_sim+eng"),
    preprocess: Optional[bool] = Form(True),
    preprocess_mode: Optional[str] = Form("auto"),
):
    """
    异步 OCR 识别 - 适用于大文件或批量处理
    
    返回任务 ID，通过 /ocr/task/{task_id} 查询进度和结果
    """
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

        # 创建异步任务
        task_id = await ocr_service.create_task(
            file_path,
            language=language,
            preprocess=preprocess,
            preprocess_mode=preprocess_mode,
        )

        return {
            "data": {
                "task_id": task_id,
                "status": "pending",
                "status_url": f"/api/v1/ocr/task/{task_id}",
            },
            "message": "OCR 任务已创建"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建 OCR 任务失败: {str(e)}")


@router.get("/ocr/task/{task_id}")
async def get_task_status(task_id: str):
    """
    查询 OCR 任务状态
    
    返回任务进度和结果（如果已完成）
    """
    status = ocr_service.get_task_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return {"data": status}


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


@router.delete("/ocr/cache")
async def clear_ocr_cache():
    """清空 OCR 缓存"""
    if ocr_service.cache:
        ocr_service.cache.clear()
        return {"message": "OCR 缓存已清空"}
    return {"message": "缓存未启用"}
