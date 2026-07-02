import pytesseract
from PIL import Image
import cv2
import numpy as np
from typing import List, Dict
import os


class OCRService:
    """OCR 服务 - 使用 Tesseract 进行文字识别"""
    
    def __init__(self):
        self.supported_languages = ['chi_sim', 'eng', 'jpn', 'kor']
    
    async def extract_text(self, image_path: str, language: str = 'chi_sim+eng') -> Dict:
        """
        从图片中提取文字
        
        Args:
            image_path: 图片路径
            language: OCR 语言，默认中英文混合
            
        Returns:
            包含识别结果和置信度的字典
        """
        try:
            # 读取图片
            image = Image.open(image_path)
            
            # 执行 OCR
            text = pytesseract.image_to_string(image, lang=language)
            data = pytesseract.image_to_data(image, lang=language, output_type=pytesseract.Output.DICT)
            
            # 计算置信度
            confidences = [float(conf) for conf in data['conf'] if int(conf) > 0]
            avg_confidence = sum(confidences) / len(confidences) if confidences else 0
            
            # 提取文字块信息
            blocks = []
            for i in range(len(data['text'])):
                if int(data['conf'][i]) > 0:  # 只保留有置信度的
                    blocks.append({
                        'text': data['text'][i],
                        'confidence': float(data['conf'][i]) / 100,
                        'bbox': {
                            'x': data['left'][i],
                            'y': data['top'][i],
                            'width': data['width'][i],
                            'height': data['height'][i]
                        }
                    })
            
            return {
                'success': True,
                'text': text.strip(),
                'confidence': avg_confidence / 100,
                'blocks': blocks,
                'language': language
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'text': '',
                'confidence': 0
            }
    
    async def preprocess_image(self, image_path: str) -> str:
        """
        图片预处理 - 提高 OCR 准确率
        
        Args:
            image_path: 原始图片路径
            
        Returns:
            预处理后的图片路径
        """
        try:
            # 读取图片
            img = cv2.imread(image_path)
            
            # 转换为灰度图
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # 应用高斯模糊去噪
            blurred = cv2.GaussianBlur(gray, (5, 5), 0)
            
            # 自适应阈值二值化
            thresh = cv2.adaptiveThreshold(
                blurred, 255,
                cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY,
                11, 2
            )
            
            # 保存预处理后的图片
            preprocessed_path = image_path.replace('.jpg', '_preprocessed.jpg')
            cv2.imwrite(preprocessed_path, thresh)
            
            return preprocessed_path
            
        except Exception as e:
            print(f"Image preprocessing failed: {e}")
            return image_path
