#!/usr/bin/env python3
"""生成符合华为 AppGallery 要求的截图"""

from PIL import Image, ImageDraw, ImageFont
import os

# 华为要求的截图尺寸
# 竖屏：1080x1920 或 1080x2340
WIDTH = 1080
HEIGHT = 1920  # 使用标准 16:9 比例

# 颜色定义
PRIMARY = '#667eea'
SECONDARY = '#764ba2'
WHITE = '#FFFFFF'
GRAY_LIGHT = '#F8F9FA'
GRAY = '#E9ECEF'
TEXT_DARK = '#212529'
TEXT_LIGHT = '#6C757D'

def create_gradient_bg(width, height):
    """创建渐变背景"""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        ratio = y / height
        r = int(102 + (118 - 102) * ratio)
        g = int(126 + (75 - 126) * ratio)
        b = int(234 + (162 - 234) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img

def draw_rounded_rect(draw, xy, radius, fill):
    """绘制圆角矩形"""
    x1, y1, x2, y2 = xy
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    draw.pieslice([x1, y1, x1 + 2*radius, y1 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x2 - 2*radius, y1, x2, y1 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x1, y2 - 2*radius, x1 + 2*radius, y2], 90, 180, fill=fill)
    draw.pieslice([x2 - 2*radius, y2 - 2*radius, x2, y2], 0, 90, fill=fill)

def draw_status_bar(draw, time_text="9:41"):
    """绘制状态栏"""
    # 状态栏背景
    draw.rectangle([0, 0, WIDTH, 60], fill='#000000')
    # 时间
    draw.text((40, 18), time_text, fill=WHITE)
    # 信号图标
    for i in range(4):
        draw.rectangle([WIDTH - 200 + i*15, 25 + i*5, WIDTH - 185 + i*15, 45], fill=WHITE)
    # WiFi 图标
    draw.text((WIDTH - 150, 18), "WiFi", fill=WHITE)
    # 电池
    draw.rectangle([WIDTH - 100, 20, WIDTH - 50, 40], outline=WHITE, width=2)
    draw.rectangle([WIDTH - 95, 25, WIDTH - 55, 35], fill=WHITE)

def draw_bottom_nav(draw, active_index=0):
    """绘制底部导航栏"""
    nav_height = 120
    draw.rectangle([0, HEIGHT - nav_height, WIDTH, HEIGHT], fill=WHITE)
    draw.line([0, HEIGHT - nav_height, WIDTH, HEIGHT - nav_height], fill=GRAY, width=1)
    
    icons = ['首页', '文档', '设置']
    for i, label in enumerate(icons):
        x = WIDTH * (i + 1) // 4
        color = PRIMARY if i == active_index else TEXT_LIGHT
        draw.text((x - 30, HEIGHT - nav_height + 30), label, fill=color)

# 截图1：主扫描界面
def create_screenshot_1():
    img = create_gradient_bg(WIDTH, HEIGHT)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 应用标题
    draw.text((WIDTH//2 - 80, 100), "ScanPDF", fill=WHITE)
    
    # 相机预览区域
    preview_y = 180
    preview_h = HEIGHT - 350
    draw_rounded_rect(draw, (40, preview_y, WIDTH-40, preview_y + preview_h), 20, '#1A1A1A')
    
    # 扫描框
    box_x = WIDTH//2 - 250
    box_y = preview_y + 200
    box_w = 500
    box_h = 600
    
    # 扫描框边框
    draw.rectangle([box_x, box_y, box_x + box_w, box_y + box_h], outline=PRIMARY, width=4)
    
    # 角落标记
    corner = 60
    mark_w = 6
    # 左上
    draw.rectangle([box_x, box_y, box_x + corner, box_y + mark_w], fill=WHITE)
    draw.rectangle([box_x, box_y, box_x + mark_w, box_y + corner], fill=WHITE)
    # 右上
    draw.rectangle([box_x + box_w - corner, box_y, box_x + box_w, box_y + mark_w], fill=WHITE)
    draw.rectangle([box_x + box_w - mark_w, box_y, box_x + box_w, box_y + corner], fill=WHITE)
    # 左下
    draw.rectangle([box_x, box_y + box_h - mark_w, box_x + corner, box_y + box_h], fill=WHITE)
    draw.rectangle([box_x, box_y + box_h - corner, box_x + mark_w, box_y + box_h], fill=WHITE)
    # 右下
    draw.rectangle([box_x + box_w - corner, box_y + box_h - mark_w, box_x + box_w, box_y + box_h], fill=WHITE)
    draw.rectangle([box_x + box_w - mark_w, box_y + box_h - corner, box_x + box_w, box_y + box_h], fill=WHITE)
    
    # 提示文字
    draw.text((WIDTH//2 - 100, box_y + box_h + 80), "将文档放入框内", fill=WHITE)
    
    # 扫描按钮
    button_y = HEIGHT - 280
    draw.ellipse([WIDTH//2 - 90, button_y, WIDTH//2 + 90, button_y + 180], fill=WHITE)
    draw.text((WIDTH//2 - 20, button_y + 60), "拍照", fill=PRIMARY)
    
    draw_bottom_nav(draw, 0)
    
    img.save('/home/a/scanpdf/screenshots/huawei_01_scan.png')
    print("✓ 截图1：扫描界面")

# 截图2：OCR识别结果
def create_screenshot_2():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 60, WIDTH, 140], fill=PRIMARY)
    draw.text((40, 85), "OCR 识别结果", fill=WHITE)
    
    # 文档预览
    draw_rounded_rect(draw, (40, 180, WIDTH-40, 600), 15, GRAY_LIGHT)
    draw.text((80, 220), "发票样本", fill=TEXT_DARK)
    draw.text((80, 280), "金额：¥1,234.56", fill=TEXT_LIGHT)
    draw.text((80, 340), "日期：2026-07-16", fill=TEXT_LIGHT)
    draw.text((80, 400), "商家：示例公司", fill=TEXT_LIGHT)
    
    # 识别结果区域
    draw.text((40, 650), "识别文本", fill=TEXT_DARK)
    draw_rounded_rect(draw, (40, 700, WIDTH-40, 1300), 15, GRAY_LIGHT)
    
    text_lines = [
        "发票代码：011001900111",
        "发票号码：12345678",
        "开票日期：2026年07月16日",
        "",
        "购买方：示例科技有限公司",
        "金额：¥1,234.56",
        "税额：¥160.49",
        "价税合计：¥1,395.05",
        "",
        "销售方：测试服务有限公司"
    ]
    
    y_pos = 740
    for line in text_lines:
        draw.text((80, y_pos), line, fill=TEXT_DARK)
        y_pos += 50
    
    # 操作按钮
    button_y = 1400
    draw_rounded_rect(draw, (40, button_y, WIDTH//2 - 60, button_y + 100), 15, PRIMARY)
    draw.text((WIDTH//4 - 20, button_y + 35), "复制文本", fill=WHITE)
    
    draw_rounded_rect(draw, (WIDTH//2 + 10, button_y, WIDTH-40, button_y + 100), 15, SECONDARY)
    draw.text((WIDTH*3//4 - 20, button_y + 35), "导出PDF", fill=WHITE)
    
    # 置信度
    draw.text((40, 1550), "识别置信度：98%", fill=PRIMARY)
    
    draw_bottom_nav(draw, 0)
    
    img.save('/home/a/scanpdf/screenshots/huawei_02_ocr.png')
    print("✓ 截图2：OCR识别")

# 截图3：PDF处理功能
def create_screenshot_3():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 60, WIDTH, 140], fill=PRIMARY)
    draw.text((40, 85), "PDF 处理", fill=WHITE)
    
    # 功能网格
    features = [
        ('生成PDF', '从图片创建'),
        ('合并PDF', '合并多个文件'),
        ('拆分PDF', '按页拆分文件'),
        ('压缩PDF', '减小文件大小'),
        ('添加水印', '保护文档'),
        ('电子签名', '在文档签名'),
        ('加密PDF', '设置密码'),
        ('表格识别', '提取表格数据'),
    ]
    
    cols = 2
    card_width = (WIDTH - 120) // cols
    card_height = 180
    start_y = 180
    
    for i, (title, desc) in enumerate(features):
        row = i // cols
        col = i % cols
        x = 40 + col * (card_width + 40)
        y = start_y + row * (card_height + 30)
        
        draw_rounded_rect(draw, (x, y, x + card_width, y + card_height), 15, GRAY_LIGHT)
        draw.text((x + 30, y + 30), title, fill=TEXT_DARK)
        draw.text((x + 30, y + 80), desc, fill=TEXT_LIGHT)
    
    # 最近文件
    draw.text((40, 1100), "最近处理", fill=TEXT_DARK)
    
    files = [
        ('合同.pdf', '2.3 MB', '今天 14:30'),
        ('发票.pdf', '456 KB', '今天 10:15'),
        ('报告.pdf', '5.1 MB', '昨天'),
    ]
    
    y_pos = 1160
    for filename, size, time in files:
        draw_rounded_rect(draw, (40, y_pos, WIDTH-40, y_pos + 120), 10, GRAY_LIGHT)
        draw.text((70, y_pos + 20), filename, fill=TEXT_DARK)
        draw.text((70, y_pos + 70), f"{size} · {time}", fill=TEXT_LIGHT)
        y_pos += 140
    
    draw_bottom_nav(draw, 0)
    
    img.save('/home/a/scanpdf/screenshots/huawei_03_pdf.png')
    print("✓ 截图3：PDF处理")

# 截图4：文档管理
def create_screenshot_4():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 60, WIDTH, 140], fill=PRIMARY)
    draw.text((40, 85), "我的文档", fill=WHITE)
    
    # 搜索框
    draw_rounded_rect(draw, (40, 180, WIDTH-40, 260), 20, GRAY_LIGHT)
    draw.text((70, 205), "搜索文档...", fill=TEXT_LIGHT)
    
    # 分类标签
    tags = ['全部', '工作', '学习', '生活', '财务']
    tag_x = 40
    for i, tag in enumerate(tags):
        tag_width = 120
        if i == 0:
            draw_rounded_rect(draw, (tag_x, 300, tag_x + tag_width, 360), 15, PRIMARY)
            draw.text((tag_x + 35, 320), tag, fill=WHITE)
        else:
            draw_rounded_rect(draw, (tag_x, 300, tag_x + tag_width, 360), 15, GRAY_LIGHT)
            draw.text((tag_x + 35, 320), tag, fill=TEXT_DARK)
        tag_x += tag_width + 20
    
    # 文档列表
    docs = [
        ('项目合同', '2.3 MB', '今天 14:30', '工作'),
        ('会议记录', '1.1 MB', '今天 10:15', '工作'),
        ('学习笔记', '856 KB', '昨天', '学习'),
        ('购物清单', '234 KB', '昨天', '生活'),
        ('发票汇总', '3.2 MB', '3天前', '财务'),
    ]
    
    y_pos = 400
    for name, size, time, tag in docs:
        draw_rounded_rect(draw, (40, y_pos, WIDTH-40, y_pos + 160), 15, GRAY_LIGHT)
        
        draw.text((70, y_pos + 25), name, fill=TEXT_DARK)
        draw.text((70, y_pos + 75), f"{size} · {time}", fill=TEXT_LIGHT)
        
        # 标签
        draw_rounded_rect(draw, (70, y_pos + 110, 170, y_pos + 140), 10, PRIMARY)
        draw.text((85, y_pos + 118), tag, fill=WHITE)
        
        y_pos += 180
    
    # 浮动按钮
    draw.ellipse([WIDTH - 160, HEIGHT - 300, WIDTH - 60, HEIGHT - 200], fill=PRIMARY)
    draw.text((WIDTH - 120, HEIGHT - 270), "+", fill=WHITE)
    
    draw_bottom_nav(draw, 1)
    
    img.save('/home/a/scanpdf/screenshots/huawei_04_docs.png')
    print("✓ 截图4：文档管理")

# 截图5：云同步设置
def create_screenshot_5():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 60, WIDTH, 140], fill=PRIMARY)
    draw.text((40, 85), "设置", fill=WHITE)
    
    # 用户信息
    draw_rounded_rect(draw, (40, 180, WIDTH-40, 340), 15, GRAY_LIGHT)
    draw.ellipse([80, 210, 160, 290], fill=PRIMARY)
    draw.text((105, 235), "用户", fill=WHITE)
    draw.text((190, 220), "用户名", fill=TEXT_DARK)
    draw.text((190, 270), "user@example.com", fill=TEXT_LIGHT)
    
    # 云同步设置
    draw.text((40, 400), "云同步", fill=TEXT_DARK)
    
    settings = [
        ('自动同步', True),
        ('仅 WiFi 同步', True),
        ('同步图片', True),
        ('同步文档', True),
    ]
    
    y_pos = 460
    for title, enabled in settings:
        draw_rounded_rect(draw, (40, y_pos, WIDTH-40, y_pos + 100), 10, GRAY_LIGHT)
        draw.text((70, y_pos + 35), title, fill=TEXT_DARK)
        
        # 开关
        switch_x = WIDTH - 160
        if enabled:
            draw_rounded_rect(draw, (switch_x, y_pos + 35, switch_x + 80, y_pos + 65), 15, PRIMARY)
            draw.ellipse([switch_x + 40, y_pos + 35, switch_x + 80, y_pos + 65], fill=WHITE)
        else:
            draw_rounded_rect(draw, (switch_x, y_pos + 35, switch_x + 80, y_pos + 65), 15, GRAY)
            draw.ellipse([switch_x, y_pos + 35, switch_x + 40, y_pos + 65], fill=WHITE)
        
        y_pos += 120
    
    # 其他设置
    draw.text((40, 900), "其他设置", fill=TEXT_DARK)
    
    other_settings = [
        '隐私设置',
        '语言设置',
        '主题设置',
        '关于应用',
    ]
    
    y_pos = 960
    for setting in other_settings:
        draw_rounded_rect(draw, (40, y_pos, WIDTH-40, y_pos + 100), 10, GRAY_LIGHT)
        draw.text((70, y_pos + 35), setting, fill=TEXT_DARK)
        draw.text((WIDTH - 100, y_pos + 35), ">", fill=TEXT_LIGHT)
        y_pos += 120
    
    # 同步状态
    draw_rounded_rect(draw, (40, HEIGHT - 300, WIDTH-40, HEIGHT - 180), 15, GRAY_LIGHT)
    draw.text((70, HEIGHT - 270), "同步状态", fill=TEXT_DARK)
    draw.text((70, HEIGHT - 230), "上次同步：5分钟前", fill=TEXT_LIGHT)
    draw.text((70, HEIGHT - 200), "已同步 128 个文档", fill=PRIMARY)
    
    draw_bottom_nav(draw, 2)
    
    img.save('/home/a/scanpdf/screenshots/huawei_05_settings.png')
    print("✓ 截图5：设置页面")

if __name__ == '__main__':
    print("正在生成华为应用市场截图 (1080x1920)...")
    create_screenshot_1()
    create_screenshot_2()
    create_screenshot_3()
    create_screenshot_4()
    create_screenshot_5()
    print("\n✅ 所有截图已生成！")
    print("位置：/home/a/scanpdf/screenshots/huawei_*.png")
