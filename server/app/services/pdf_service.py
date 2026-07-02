from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
from PIL import Image
import os
from typing import List


class PDFService:
    """PDF 生成服务"""
    
    def __init__(self):
        self.page_size = A4
        self.dpi = 300
    
    async def create_pdf_from_images(
        self,
        image_paths: List[str],
        output_path: str,
        page_size: tuple = None
    ) -> str:
        """
        从多张图片创建 PDF
        
        Args:
            image_paths: 图片路径列表
            output_path: 输出 PDF 路径
            page_size: 页面大小，默认 A4
            
        Returns:
            生成的 PDF 路径
        """
        try:
            if page_size is None:
                page_size = self.page_size
            
            c = canvas.Canvas(output_path, pagesize=page_size)
            width, height = page_size
            
            for image_path in image_paths:
                # 打开图片
                img = Image.open(image_path)
                
                # 计算图片在页面上的尺寸（保持比例）
                img_width, img_height = img.size
                aspect = img_height / float(img_width)
                
                # 根据页面大小调整
                if img_width > width:
                    img_width = width * 0.9
                    img_height = img_width * aspect
                
                if img_height > height:
                    img_height = height * 0.9
                    img_width = img_height / aspect
                
                # 居中放置图片
                x = (width - img_width) / 2
                y = (height - img_height) / 2
                
                # 绘制图片
                c.drawImage(
                    ImageReader(image_path),
                    x, y,
                    width=img_width,
                    height=img_height
                )
                
                # 添加新页
                c.showPage()
            
            # 保存 PDF
            c.save()
            
            return output_path
            
        except Exception as e:
            raise Exception(f"PDF creation failed: {e}")
    
    async def merge_pdfs(
        self,
        pdf_paths: List[str],
        output_path: str
    ) -> str:
        """
        合并多个 PDF 文件
        
        Args:
            pdf_paths: PDF 文件路径列表
            output_path: 输出路径
            
        Returns:
            合并后的 PDF 路径
        """
        try:
            from PyPDF2 import PdfMerger
            
            merger = PdfMerger()
            
            for pdf_path in pdf_paths:
                merger.append(pdf_path)
            
            merger.write(output_path)
            merger.close()
            
            return output_path
            
        except Exception as e:
            raise Exception(f"PDF merge failed: {e}")
    
    async def get_pdf_info(self, pdf_path: str) -> dict:
        """
        获取 PDF 信息
        
        Args:
            pdf_path: PDF 文件路径
            
        Returns:
            PDF 信息字典
        """
        try:
            from PyPDF2 import PdfReader
            
            reader = PdfReader(pdf_path)
            
            return {
                'pages': len(reader.pages),
                'metadata': reader.metadata,
                'encrypted': reader.is_encrypted
            }
            
        except Exception as e:
            raise Exception(f"Failed to get PDF info: {e}")
