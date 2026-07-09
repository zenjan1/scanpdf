import pytesseract
from PIL import Image, ImageFilter, ImageEnhance
import cv2
import numpy as np
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field
import os
import time
import math
from enum import Enum


class PreprocessMode(str, Enum):
    """图片预处理模式"""
    NONE = "none"
    AUTO = "auto"
    GRAYSCALE = "grayscale"
    HIGH_CONTRAST = "high_contrast"
    BINARIZE = "binarize"
    DE_SHADOW = "de_shadow"


@dataclass
class OcrWordResult:
    """单个词的识别结果"""
    text: str
    confidence: float
    bbox: Dict[str, int]
    font_size: float = 0.0
    is_bold: bool = False
    is_italic: bool = False


@dataclass
class OcrLineResult:
    """单行的识别结果"""
    text: str
    confidence: float
    words: List[OcrWordResult] = field(default_factory=list)
    bbox: Dict[str, int] = field(default_factory=dict)


@dataclass
class OcrBlockResult:
    """文本块的识别结果"""
    text: str
    confidence: float
    lines: List[OcrLineResult] = field(default_factory=list)
    bbox: Dict[str, int] = field(default_factory=dict)


@dataclass
class OcrResponse:
    """完整的 OCR 识别结果"""
    success: bool
    text: str = ""
    confidence: float = 0.0
    blocks: List[OcrBlockResult] = field(default_factory=list)
    paragraphs: List[Dict] = field(default_factory=list)
    language: str = ""
    processing_time: float = 0.0
    total_characters: int = 0
    total_words: int = 0
    total_lines: int = 0
    detected_languages: Dict[str, float] = field(default_factory=dict)
    error: str = ""
    preprocess_mode: str = ""


class OCRService:
    """OCR 服务 - 使用 Tesseract 进行文字识别"""

    def __init__(self):
        self.supported_languages = {
            'chi_sim': '简体中文',
            'chi_tra': '繁體中文',
            'eng': 'English',
            'jpn': '日本語',
            'kor': '한국어',
            'deu': 'Deutsch',
            'fra': 'Français',
            'spa': 'Español',
            'rus': 'Русский',
            'ara': 'العربية',
            'hin': 'हिन्दी',
        }
        # 常用语言组合
        self.language_presets = {
            'chi_eng': 'chi_sim+eng',
            'chi_only': 'chi_sim',
            'eng_only': 'eng',
            'ja_eng': 'jpn+eng',
            'ko_eng': 'kor+eng',
            'all': 'chi_sim+eng+jpn+kor',
        }

    async def extract_text(
        self,
        image_path: str,
        language: str = 'chi_sim+eng',
        preprocess: bool = True,
        preprocess_mode: str = 'auto',
        psm: int = -1,
    ) -> Dict:
        """
        从图片中提取文字

        Args:
            image_path: 图片路径
            language: OCR 语言，默认中英文混合
            preprocess: 是否预处理
            preprocess_mode: 预处理模式
            psm: Tesseract page segmentation mode (-1 为自动)

        Returns:
            包含识别结果和置信度的字典
        """
        start_time = time.time()
        preprocessed_path = image_path

        try:
            # 验证图片文件
            if not os.path.exists(image_path):
                return self._error_result(f"图片文件不存在: {image_path}")

            # 图片预处理
            if preprocess and preprocess_mode != 'none':
                preprocessed_path = await self.preprocess_image(
                    image_path, mode=preprocess_mode
                )

            # 读取图片
            image = Image.open(preprocessed_path)

            # 配置 Tesseract 参数
            config = ''
            if psm >= 0:
                config = f'--psm {psm}'

            # 执行 OCR - 获取纯文本
            text = pytesseract.image_to_string(image, lang=language, config=config)

            # 执行 OCR - 获取详细数据
            data = pytesseract.image_to_data(
                image, lang=language, output_type=pytesseract.Output.DICT, config=config
            )

            # 解析结构化结果
            blocks = self._parse_blocks(data)

            # 分组为段落
            paragraphs = self._group_paragraphs(blocks)

            # 计算统计数据
            full_text = text.strip()
            all_confidences = [
                float(data['conf'][i])
                for i in range(len(data['conf']))
                if int(data['conf'][i]) > 0
            ]
            avg_confidence = (
                sum(all_confidences) / len(all_confidences) / 100
                if all_confidences
                else 0.0
            )

            # 清理预处理临时文件
            if preprocessed_path != image_path:
                try:
                    os.remove(preprocessed_path)
                except OSError:
                    pass

            processing_time = time.time() - start_time

            return {
                'success': True,
                'text': full_text,
                'confidence': avg_confidence,
                'blocks': [self._block_to_dict(b) for b in blocks],
                'paragraphs': paragraphs,
                'language': language,
                'processing_time': round(processing_time, 3),
                'total_characters': len(full_text),
                'total_words': len(full_text.split()) if full_text else 0,
                'total_lines': len([l for l in full_text.split('\n') if l.strip()]),
                'detected_languages': self._detect_languages(data),
                'preprocess_mode': preprocess_mode,
                'error': '',
            }

        except Exception as e:
            # 清理临时文件
            if preprocessed_path != image_path:
                try:
                    os.remove(preprocessed_path)
                except OSError:
                    pass
            return self._error_result(str(e))

    async def extract_text_batch(
        self,
        image_paths: List[str],
        language: str = 'chi_sim+eng',
        preprocess: bool = True,
        preprocess_mode: str = 'auto',
    ) -> List[Dict]:
        """批量 OCR 识别"""
        results = []
        for path in image_paths:
            result = await self.extract_text(
                path, language=language,
                preprocess=preprocess,
                preprocess_mode=preprocess_mode,
            )
            results.append(result)
        return results

    async def preprocess_image(
        self,
        image_path: str,
        mode: str = 'auto',
    ) -> str:
        """
        图片预处理 - 提高 OCR 准确率

        Args:
            image_path: 原始图片路径
            mode: 预处理模式

        Returns:
            预处理后的图片路径
        """
        try:
            img = cv2.imread(image_path)
            if img is None:
                raise ValueError(f"无法读取图片: {image_path}")

            # 第一步：倾斜校正
            img = self._deskew(img)

            if mode == 'auto':
                result = self._auto_preprocess(img)
            elif mode == 'grayscale':
                result = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            elif mode == 'high_contrast':
                result = self._high_contrast_preprocess(img)
            elif mode == 'binarize':
                result = self._binarize(img)
            elif mode == 'de_shadow':
                result = self._remove_shadows(img)
            else:
                return image_path

            # 保存预处理后的图片
            base, ext = os.path.splitext(image_path)
            preprocessed_path = f"{base}_ocr_prep.jpg"
            cv2.imwrite(preprocessed_path, result, [cv2.IMWRITE_JPEG_QUALITY, 95])
            return preprocessed_path

        except Exception as e:
            print(f"Image preprocessing failed: {e}")
            return image_path

    # ─── 内部预处理方法 ───

    def _auto_preprocess(self, img: np.ndarray) -> np.ndarray:
        """自动预处理：灰度 + 去噪 + 对比度增强"""
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # 非局部均值去噪 (保留边缘)
        denoised = cv2.fastNlMeansDenoising(gray, h=10, templateWindowSize=7, searchWindowSize=21)
        # 自适应阈值二值化
        binary = cv2.adaptiveThreshold(
            denoised, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            11, 2
        )
        return binary

    def _high_contrast_preprocess(self, img: np.ndarray) -> np.ndarray:
        """高对比度预处理"""
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # CLAHE 自适应直方图均衡化
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        return enhanced

    def _binarize(self, img: np.ndarray) -> np.ndarray:
        """二值化预处理 (Otsu 方法)"""
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        # 先轻度模糊去噪
        blurred = cv2.GaussianBlur(gray, (3, 3), 0)
        # Otsu 自动阈值二值化
        _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        return binary

    def _remove_shadows(self, img: np.ndarray) -> np.ndarray:
        """去阴影预处理"""
        # 转换到 LAB 色彩空间
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l_channel, a, b = cv2.split(lab)
        # 对 L 通道进行顶帽变换去除光照不均
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (51, 51))
        top_hat = cv2.morphologyEx(l_channel, cv2.MORPH_TOPHAT, kernel)
        # 合并回 LAB
        result_lab = cv2.merge([top_hat, a, b])
        result = cv2.cvtColor(result_lab, cv2.COLOR_LAB2BGR)
        gray = cv2.cvtColor(result, cv2.COLOR_BGR2GRAY)
        # 自适应二值化
        binary = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            15, 3
        )
        return binary

    def _deskew(self, img: np.ndarray) -> np.ndarray:
        """倾斜校正"""
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img
        # 边缘检测
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        # 霍夫直线检测
        lines = cv2.HoughLines(edges, 1, np.pi / 180, threshold=150)

        if lines is None or len(lines) == 0:
            return img

        # 计算中值角度
        angles = []
        for rho, theta in lines.reshape(-1, 2):
            angle = np.degrees(theta) - 90
            # 只考虑接近水平的线（文档文本行通常是水平的）
            if abs(angle) < 45:
                angles.append(angle)

        if not angles:
            return img

        median_angle = np.median(angles)

        # 角度太小则不校正
        if abs(median_angle) < 0.5:
            return img

        # 旋转图片
        h, w = img.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, median_angle, 1.0)
        rotated = cv2.warpAffine(
            img, M, (w, h),
            flags=cv2.INTER_CUBIC,
            borderMode=cv2.BORDER_REPLICATE,
        )
        return rotated

    # ─── 结果解析方法 ───

    def _parse_blocks(self, data: Dict) -> List[OcrBlockResult]:
        """将 Tesseract 原始数据解析为结构化 block 列表"""
        blocks_dict: Dict[Tuple[int, int, int], OcrBlockResult] = {}
        lines_dict: Dict[Tuple[int, int, int], OcrLineResult] = {}

        n = len(data['text'])
        for i in range(n):
            text = data['text'][i].strip()
            conf = int(data['conf'][i])
            if conf < 0:
                continue

            block_num = data['block_num'][i]
            par_num = data['par_num'][i]
            line_num = data['line_num'][i]
            word_num = data['word_num'][i]

            # 唯一键
            block_key = (block_num, par_num, 0)
            line_key = (block_num, par_num, line_num)

            # 创建 block
            if block_key not in blocks_dict:
                blocks_dict[block_key] = OcrBlockResult(
                    text='', confidence=0.0,
                    bbox={
                        'x': data['left'][i], 'y': data['top'][i],
                        'width': data['width'][i], 'height': data['height'][i],
                    },
                )

            # 创建 line
            if line_key not in lines_dict:
                line = OcrLineResult(
                    text='', confidence=0.0,
                    bbox={
                        'x': data['left'][i], 'y': data['top'][i],
                        'width': data['width'][i], 'height': data['height'][i],
                    },
                )
                lines_dict[line_key] = line
                blocks_dict[block_key].lines.append(line)

            # 添加 word
            if text and conf > 0:
                word = OcrWordResult(
                    text=text,
                    confidence=conf / 100.0,
                    bbox={
                        'x': data['left'][i], 'y': data['top'][i],
                        'width': data['width'][i], 'height': data['height'][i],
                    },
                    font_size=float(data['height'][i]),
                    is_bold=bool(data['is_bold'][i]) if 'is_bold' in data else False,
                    is_italic=bool(data['is_italic'][i]) if 'is_italic' in data else False,
                )
                lines_dict[line_key].words.append(word)

        # 重新组装文本
        for block in blocks_dict.values():
            block_lines = []
            confs = []
            for line in block.lines:
                line_words_text = [w.text for w in line.words]
                line.text = ' '.join(line_words_text)
                line_confidences = [w.confidence for w in line.words if w.confidence > 0]
                line.confidence = (
                    sum(line_confidences) / len(line_confidences)
                    if line_confidences else 0.0
                )
                block_lines.append(line.text)
                if line.confidence > 0:
                    confs.append(line.confidence)

            block.text = '\n'.join(block_lines)
            block.confidence = (
                sum(confs) / len(confs) if confs else 0.0
            )

        return list(blocks_dict.values())

    def _group_paragraphs(self, blocks: List[OcrBlockResult]) -> List[Dict]:
        """将 blocks 分组为段落（基于垂直间距）"""
        if not blocks:
            return []

        paragraphs = []
        current_blocks = [blocks[0]]

        for i in range(1, len(blocks)):
            prev_bbox = blocks[i - 1].bbox
            curr_bbox = blocks[i].bbox
            prev_bottom = prev_bbox.get('y', 0) + prev_bbox.get('height', 20)
            curr_top = curr_bbox.get('y', 0)
            gap = curr_top - prev_bottom
            line_height = prev_bbox.get('height', 20)

            if gap > line_height * 0.8:
                paragraphs.append(self._make_paragraph(current_blocks))
                current_blocks = [blocks[i]]
            else:
                current_blocks.append(blocks[i])

        if current_blocks:
            paragraphs.append(self._make_paragraph(current_blocks))

        return paragraphs

    def _make_paragraph(self, blocks: List[OcrBlockResult]) -> Dict:
        """构建段落字典"""
        text = '\n'.join(b.text for b in blocks if b.text.strip())
        confs = [b.confidence for b in blocks if b.confidence > 0]
        return {
            'text': text,
            'confidence': sum(confs) / len(confs) if confs else 0.0,
            'block_count': len(blocks),
        }

    def _detect_languages(self, data: Dict) -> Dict[str, float]:
        """从识别结果中推断检测到的语言（基于字符统计）"""
        lang_chars = {
            'CJK': r'[一-鿿㐀-䶿]',
            'Hiragana': r'[぀-ゟ]',
            'Katakana': r'[゠-ヿ]',
            'Hangul': r'[가-힯ᄀ-ᇿ]',
            'Latin': r'[a-zA-Z]',
            'Cyrillic': r'[Ѐ-ӿ]',
            'Arabic': r'[؀-ۿ]',
            'Devanagari': r'[ऀ-ॿ]',
            'Digit': r'[0-9]',
        }
        import re
        all_text = ' '.join(data.get('text', []))
        if not all_text.strip():
            return {}

        counts = {}
        total = 0
        for lang, pattern in lang_chars.items():
            c = len(re.findall(pattern, all_text))
            if c > 0:
                counts[lang] = c
                total += c

        if total == 0:
            return {}

        return {k: round(v / total, 3) for k, v in sorted(counts.items(), key=lambda x: -x[1])}

    def _block_to_dict(self, block: OcrBlockResult) -> Dict:
        """将 OcrBlockResult 转为字典"""
        return {
            'text': block.text,
            'confidence': round(block.confidence, 4),
            'bbox': block.bbox,
            'lines': [
                {
                    'text': line.text,
                    'confidence': round(line.confidence, 4),
                    'bbox': line.bbox,
                    'words': [
                        {
                            'text': w.text,
                            'confidence': round(w.confidence, 4),
                            'bbox': w.bbox,
                            'font_size': round(w.font_size, 1),
                        }
                        for w in line.words
                    ],
                }
                for line in block.lines
            ],
        }

    def _error_result(self, error: str) -> Dict:
        """构建错误结果"""
        return {
            'success': False,
            'text': '',
            'confidence': 0.0,
            'blocks': [],
            'paragraphs': [],
            'language': '',
            'processing_time': 0.0,
            'total_characters': 0,
            'total_words': 0,
            'total_lines': 0,
            'detected_languages': {},
            'preprocess_mode': '',
            'error': error,
        }
