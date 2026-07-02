import cv2
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
from typing import List, Tuple, Optional
import os


class ImageProcessor:
    """图像处理服务 - 边缘检测、透视矫正、增强"""

    def detect_edges(self, image_path: str) -> List[Tuple[int, int]]:
        """
        检测文档边缘，返回四个角点坐标
        基于 OpenCV 的 Canny + 轮廓检测
        """
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Cannot read image: {image_path}")

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edged = cv2.Canny(blurred, 50, 200)

        # 形态学操作闭合边缘
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        closed = cv2.morphologyEx(edged, cv2.MORPH_CLOSE, kernel)

        contours, _ = cv2.findContours(
            closed, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
        )

        if not contours:
            h, w = img.shape[:2]
            return [(0, 0), (w, 0), (w, h), (0, h)]

        # 找到最大轮廓
        contours = sorted(contours, key=cv2.contourArea, reverse=True)
        max_contour = contours[0]

        # 近似多边形
        peri = cv2.contourPerimeter(max_contour)
        approx = cv2.approxPolyDP(max_contour, 0.02 * peri, True)

        if len(approx) == 4:
            points = approx.reshape(4, 2).tolist()
            return [tuple(p) for p in self._order_points(points)]

        # 如果找不到四边形，返回图片四角
        h, w = img.shape[:2]
        return [(0, 0), (w, 0), (w, h), (0, h)]

    def perspective_transform(
        self, image_path: str, corners: List[Tuple[int, int]], output_path: str
    ) -> str:
        """
        透视矫正
        """
        img = cv2.imread(image_path)
        ordered = self._order_points(corners)

        # 计算目标尺寸
        width_top = np.linalg.norm(
            np.array(ordered[0]) - np.array(ordered[1])
        )
        width_bottom = np.linalg.norm(
            np.array(ordered[3]) - np.array(ordered[2])
        )
        max_width = max(int(width_top), int(width_bottom))

        height_left = np.linalg.norm(
            np.array(ordered[0]) - np.array(ordered[3])
        )
        height_right = np.linalg.norm(
            np.array(ordered[1]) - np.array(ordered[2])
        )
        max_height = max(int(height_left), int(height_right))

        src = np.array(ordered, dtype=np.float32)
        dst = np.array(
            [[0, 0], [max_width - 1, 0],
             [max_width - 1, max_height - 1], [0, max_height - 1]],
            dtype=np.float32,
        )

        matrix = cv2.getPerspectiveTransform(src, dst)
        warped = cv2.warpPerspective(img, matrix, (max_width, max_height))
        cv2.imwrite(output_path, warped)
        return output_path

    def enhance_document(self, image_path: str, output_path: str) -> str:
        """文档增强 - 去阴影、提高对比度、锐化"""
        img = Image.open(image_path)

        # 转灰度
        gray = img.convert('L')

        # 增强对比度
        enhancer = ImageEnhance.Contrast(gray)
        enhanced = enhancer.enhance(1.5)

        # 增强锐度
        enhancer = ImageEnhance.Sharpness(enhanced)
        sharpened = enhancer.enhance(2.0)

        # 自适应阈值
        img_cv = cv2.cvtColor(np.array(sharpened), cv2.COLOR_GRAY2BGR)
        gray_cv = cv2.cvtColor(img_cv, cv2.COLOR_BGR2GRAY)
        result = cv2.adaptiveThreshold(
            gray_cv, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, 11, 2
        )

        cv2.imwrite(output_path, result)
        return output_path

    def create_thumbnail(
        self, image_path: str, output_path: str, size: Tuple[int, int] = (200, 200)
    ) -> str:
        """生成缩略图"""
        img = Image.open(image_path)
        img.thumbnail(size, Image.Resampling.LANCZOS)
        img.save(output_path, "JPEG", quality=85)
        return output_path

    @staticmethod
    def _order_points(points: List) -> List[Tuple[int, int]]:
        """按 [左上, 右上, 右下, 左下] 排序"""
        pts = np.array(points, dtype=np.float32)
        rect = np.zeros((4, 2), dtype=np.float32)

        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[2] = pts[np.argmax(s)]

        d = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(d)]
        rect[3] = pts[np.argmax(d)]

        return [(int(p[0]), int(p[1])) for p in rect]
