#!/usr/bin/env python3
"""生成 ScanPDF 应用商店截图"""

from PIL import Image, ImageDraw, ImageFont
import os

# 创建输出目录
os.makedirs('/home/a/scanpdf/screenshots', exist_ok=True)

# 标准手机分辨率
WIDTH = 1080
HEIGHT = 2340

# 颜色定义
PRIMARY = '#667eea'
SECONDARY = '#764ba2'
WHITE = '#FFFFFF'
GRAY_LIGHT = '#F5F5F5'
GRAY = '#999999'
TEXT_DARK = '#333333'
TEXT_LIGHT = '#666666'

def create_gradient(width, height, color1, color2):
    """创建渐变背景"""
    base = Image.new('RGB', (width, height), color1)
    top = Image.new('RGB', (width, height), color2)
    mask = Image.new('L', (width, height))
    mask_data = []
    for y in range(height):
        mask_data.extend([int(255 * (y / height))] * width)
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def draw_rounded_rect(draw, xy, radius, fill):
    """绘制圆角矩形"""
    x1, y1, x2, y2 = xy
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    draw.pieslice([x1, y1, x1 + 2*radius, y1 + 2*radius], 180, 270, fill=fill)
    draw.pieslice([x2 - 2*radius, y1, x2, y1 + 2*radius], 270, 360, fill=fill)
    draw.pieslice([x1, y2 - 2*radius, x1 + 2*radius, y2], 90, 180, fill=fill)
    draw.pieslice([x2 - 2*radius, y2 - 2*radius, x2, y2], 0, 90, fill=fill)

def draw_status_bar(draw):
    """绘制状态栏"""
    draw.rectangle([0, 0, WIDTH, 80], fill='#000000')
    # 时间
    draw.text((50, 25), "9:41", fill=WHITE, font=ImageFont.load_default())
    # 信号和电池
    draw.text((WIDTH - 200, 25), "●●●●", fill=WHITE, font=ImageFont.load_default())
    draw.text((WIDTH - 100, 25), "100%", fill=WHITE, font=ImageFont.load_default())

def draw_bottom_nav(draw):
    """绘制底部导航栏"""
    draw.rectangle([0, HEIGHT - 150, WIDTH, HEIGHT], fill=WHITE)
    icons = ['🏠', '📁', '⚙️']
    labels = ['首页', '文档', '设置']
    for i, (icon, label) in enumerate(zip(icons, labels)):
        x = WIDTH * (i + 1) // 4
        draw.text((x - 20, HEIGHT - 120), icon, fill=PRIMARY if i == 0 else GRAY, font=ImageFont.load_default())
        draw.text((x - 20, HEIGHT - 80), label, fill=PRIMARY if i == 0 else GRAY, font=ImageFont.load_default())

# 截图1：主扫描界面
def create_screenshot_1():
    img = create_gradient(WIDTH, HEIGHT, PRIMARY, SECONDARY)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 标题
    draw.text((WIDTH//2 - 100, 150), "ScanPDF", fill=WHITE, font=ImageFont.load_default())
    
    # 相机预览区域
    draw_rounded_rect(draw, (50, 250, WIDTH-50, HEIGHT-250), 20, '#222222')
    
    # 扫描框
    box_x, box_y = WIDTH//2 - 200, 500
    box_w, box_h = 400, 500
    draw.rectangle([box_x, box_y, box_x + box_w, box_y + box_h], outline=PRIMARY, width=3)
    
    # 角落标记
    corner_len = 50
    # 左上
    draw.line([box_x, box_y, box_x + corner_len, box_y], fill=WHITE, width=5)
    draw.line([box_x, box_y, box_x, box_y + corner_len], fill=WHITE, width=5)
    # 右上
    draw.line([box_x + box_w, box_y, box_x + box_w - corner_len, box_y], fill=WHITE, width=5)
    draw.line([box_x + box_w, box_y, box_x + box_w, box_y + corner_len], fill=WHITE, width=5)
    # 左下
    draw.line([box_x, box_y + box_h, box_x + corner_len, box_y + box_h], fill=WHITE, width=5)
    draw.line([box_x, box_y + box_h, box_x, box_y + box_h - corner_len], fill=WHITE, width=5)
    # 右下
    draw.line([box_x + box_w, box_y + box_h, box_x + box_w - corner_len, box_y + box_h], fill=WHITE, width=5)
    draw.line([box_x + box_w, box_y + box_h, box_x + box_w, box_y + box_h - corner_len], fill=WHITE, width=5)
    
    # 提示文字
    draw.text((WIDTH//2 - 150, 1100), "将文档放入框内", fill=WHITE, font=ImageFont.load_default())
    
    # 扫描按钮
    button_y = HEIGHT - 350
    draw.ellipse([WIDTH//2 - 80, button_y, WIDTH//2 + 80, button_y + 160], fill=WHITE)
    draw.text((WIDTH//2 - 30, button_y + 50), "📸", fill=PRIMARY, font=ImageFont.load_default())
    
    draw_bottom_nav(draw)
    
    img.save('/home/a/scanpdf/screenshots/01_scan_interface.png')
    print("✓ 截图1：扫描界面")

# 截图2：OCR识别结果
def create_screenshot_2():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 80, WIDTH, 180], fill=PRIMARY)
    draw.text((50, 110), "OCR 识别结果", fill=WHITE, font=ImageFont.load_default())
    
    # 文档预览
    draw_rounded_rect(draw, (50, 220, WIDTH-50, 700), 15, GRAY_LIGHT)
    draw.text((100, 280), "发票样本", fill=TEXT_DARK, font=ImageFont.load_default())
    draw.text((100, 350), "金额：¥1,234.56", fill=TEXT_LIGHT, font=ImageFont.load_default())
    draw.text((100, 420), "日期：2026-07-16", fill=TEXT_LIGHT, font=ImageFont.load_default())
    draw.text((100, 490), "商家：示例公司", fill=TEXT_LIGHT, font=ImageFont.load_default())
    
    # 识别结果
    draw.text((50, 750), "识别文本", fill=TEXT_DARK, font=ImageFont.load_default())
    draw_rounded_rect(draw, (50, 820, WIDTH-50, 1400), 15, GRAY_LIGHT)
    
    text_content = """
发票代码：011001900111
发票号码：12345678
开票日期：2026年07月16日

购买方：示例科技有限公司
金额：¥1,234.56
税额：¥160.49
价税合计：¥1,395.05

销售方：测试服务有限公司
    """
    y_pos = 850
    for line in text_content.strip().split('\n'):
        draw.text((80, y_pos), line.strip(), fill=TEXT_DARK, font=ImageFont.load_default())
        y_pos += 60
    
    # 操作按钮
    button_y = 1500
    draw_rounded_rect(draw, (50, button_y, WIDTH//2 - 70, button_y + 100), 15, PRIMARY)
    draw.text((150, button_y + 30), "复制文本", fill=WHITE, font=ImageFont.load_default())
    
    draw_rounded_rect(draw, (WIDTH//2 + 20, button_y, WIDTH-50, button_y + 100), 15, SECONDARY)
    draw.text((WIDTH//2 + 100, button_y + 30), "导出PDF", fill=WHITE, font=ImageFont.load_default())
    
    # 置信度
    draw.text((50, 1700), "识别置信度：98%", fill=PRIMARY, font=ImageFont.load_default())
    
    draw_bottom_nav(draw)
    
    img.save('/home/a/scanpdf/screenshots/02_ocr_result.png')
    print("✓ 截图2：OCR识别结果")

# 截图3：PDF处理功能
def create_screenshot_3():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 80, WIDTH, 180], fill=PRIMARY)
    draw.text((50, 110), "PDF 处理", fill=WHITE, font=ImageFont.load_default())
    
    # 功能网格
    features = [
        ('📄', '生成PDF', '从图片创建'),
        ('🔗', '合并PDF', '合并多个文件'),
        ('✂️', '拆分PDF', '按页拆分文件'),
        ('🗜️', '压缩PDF', '减小文件大小'),
        ('💧', '添加水印', '保护文档'),
        ('✍️', '电子签名', '在文档签名'),
        ('🔒', '加密PDF', '设置密码'),
        ('📊', '表格识别', '提取表格数据'),
    ]
    
    cols = 2
    card_width = (WIDTH - 150) // cols
    card_height = 200
    start_y = 250
    
    for i, (icon, title, desc) in enumerate(features):
        row = i // cols
        col = i % cols
        x = 50 + col * (card_width + 50)
        y = start_y + row * (card_height + 30)
        
        draw_rounded_rect(draw, (x, y, x + card_width, y + card_height), 15, GRAY_LIGHT)
        draw.text((x + 30, y + 30), icon, fill=PRIMARY, font=ImageFont.load_default())
        draw.text((x + 30, y + 90), title, fill=TEXT_DARK, font=ImageFont.load_default())
        draw.text((x + 30, y + 140), desc, fill=TEXT_LIGHT, font=ImageFont.load_default())
    
    # 最近文件
    draw.text((50, 1300), "最近处理", fill=TEXT_DARK, font=ImageFont.load_default())
    
    files = [
        ('合同.pdf', '2.3 MB', '今天 14:30'),
        ('发票.pdf', '456 KB', '今天 10:15'),
        ('报告.pdf', '5.1 MB', '昨天'),
    ]
    
    y_pos = 1380
    for filename, size, time in files:
        draw_rounded_rect(draw, (50, y_pos, WIDTH-50, y_pos + 120), 10, GRAY_LIGHT)
        draw.text((80, y_pos + 20), "📄", fill=PRIMARY, font=ImageFont.load_default())
        draw.text((150, y_pos + 20), filename, fill=TEXT_DARK, font=ImageFont.load_default())
        draw.text((150, y_pos + 70), f"{size} · {time}", fill=TEXT_LIGHT, font=ImageFont.load_default())
        y_pos += 150
    
    draw_bottom_nav(draw)
    
    img.save('/home/a/scanpdf/screenshots/03_pdf_features.png')
    print("✓ 截图3：PDF处理功能")

# 截图4：文档管理
def create_screenshot_4():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 80, WIDTH, 180], fill=PRIMARY)
    draw.text((50, 110), "我的文档", fill=WHITE, font=ImageFont.load_default())
    
    # 搜索框
    draw_rounded_rect(draw, (50, 220, WIDTH-50, 320), 20, GRAY_LIGHT)
    draw.text((80, 250), "🔍 搜索文档...", fill=GRAY, font=ImageFont.load_default())
    
    # 分类标签
    tags = ['全部', '工作', '学习', '生活', '财务']
    tag_x = 50
    for i, tag in enumerate(tags):
        tag_width = 120
        if i == 0:
            draw_rounded_rect(draw, (tag_x, 360, tag_x + tag_width, 420), 15, PRIMARY)
            draw.text((tag_x + 35, 375), tag, fill=WHITE, font=ImageFont.load_default())
        else:
            draw_rounded_rect(draw, (tag_x, 360, tag_x + tag_width, 420), 15, GRAY_LIGHT)
            draw.text((tag_x + 35, 375), tag, fill=TEXT_DARK, font=ImageFont.load_default())
        tag_x += tag_width + 20
    
    # 文档列表
    docs = [
        ('📄', '项目合同', '2.3 MB', '今天 14:30', '工作'),
        ('📄', '会议记录', '1.1 MB', '今天 10:15', '工作'),
        ('📄', '学习笔记', '856 KB', '昨天', '学习'),
        ('📄', '购物清单', '234 KB', '昨天', '生活'),
        ('📄', '发票汇总', '3.2 MB', '3天前', '财务'),
        ('📄', '简历', '1.5 MB', '1周前', '工作'),
    ]
    
    y_pos = 480
    for icon, name, size, time, tag in docs:
        draw_rounded_rect(draw, (50, y_pos, WIDTH-50, y_pos + 180), 15, GRAY_LIGHT)
        
        # 图标
        draw.text((80, y_pos + 30), icon, fill=PRIMARY, font=ImageFont.load_default())
        
        # 文件名和大小
        draw.text((150, y_pos + 25), name, fill=TEXT_DARK, font=ImageFont.load_default())
        draw.text((150, y_pos + 75), f"{size} · {time}", fill=TEXT_LIGHT, font=ImageFont.load_default())
        
        # 标签
        draw_rounded_rect(draw, (150, y_pos + 120, 250, y_pos + 155), 10, PRIMARY)
        draw.text((165, y_pos + 128), tag, fill=WHITE, font=ImageFont.load_default())
        
        # 更多按钮
        draw.text((WIDTH - 100, y_pos + 60), "⋮", fill=GRAY, font=ImageFont.load_default())
        
        y_pos += 210
    
    # 浮动按钮
    draw.ellipse([WIDTH - 150, HEIGHT - 350, WIDTH - 50, HEIGHT - 250], fill=PRIMARY)
    draw.text((WIDTH - 115, HEIGHT - 320), "+", fill=WHITE, font=ImageFont.load_default())
    
    draw_bottom_nav(draw)
    
    img.save('/home/a/scanpdf/screenshots/04_document_management.png')
    print("✓ 截图4：文档管理")

# 截图5：云同步设置
def create_screenshot_5():
    img = Image.new('RGB', (WIDTH, HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    
    draw_status_bar(draw)
    
    # 顶部栏
    draw.rectangle([0, 80, WIDTH, 180], fill=PRIMARY)
    draw.text((50, 110), "设置", fill=WHITE, font=ImageFont.load_default())
    
    # 用户信息
    draw_rounded_rect(draw, (50, 220, WIDTH-50, 400), 15, GRAY_LIGHT)
    draw.ellipse([100, 260, 200, 360], fill=PRIMARY)
    draw.text((130, 285), "👤", fill=WHITE, font=ImageFont.load_default())
    draw.text((230, 270), "用户名", fill=TEXT_DARK, font=ImageFont.load_default())
    draw.text((230, 320), "user@example.com", fill=TEXT_LIGHT, font=ImageFont.load_default())
    
    # 云同步设置
    draw.text((50, 450), "云同步", fill=TEXT_DARK, font=ImageFont.load_default())
    
    settings = [
        ('自动同步', True),
        ('仅 WiFi 同步', True),
        ('同步图片', True),
        ('同步文档', True),
    ]
    
    y_pos = 520
    for title, enabled in settings:
        draw_rounded_rect(draw, (50, y_pos, WIDTH-50, y_pos + 100), 10, GRAY_LIGHT)
        draw.text((80, y_pos + 30), title, fill=TEXT_DARK, font=ImageFont.load_default())
        
        # 开关
        switch_x = WIDTH - 150
        if enabled:
            draw_rounded_rect(draw, (switch_x, y_pos + 30, switch_x + 80, y_pos + 70), 20, PRIMARY)
            draw.ellipse([switch_x + 40, y_pos + 30, switch_x + 80, y_pos + 70], fill=WHITE)
        else:
            draw_rounded_rect(draw, (switch_x, y_pos + 30, switch_x + 80, y_pos + 70), 20, GRAY)
            draw.ellipse([switch_x, y_pos + 30, switch_x + 40, y_pos + 70], fill=WHITE)
        
        y_pos += 120
    
    # 其他设置
    draw.text((50, 1100), "其他设置", fill=TEXT_DARK, font=ImageFont.load_default())
    
    other_settings = [
        '🔒 隐私设置',
        '🌐 语言设置',
        '🎨 主题设置',
        '📱 关于应用',
    ]
    
    y_pos = 1170
    for setting in other_settings:
        draw_rounded_rect(draw, (50, y_pos, WIDTH-50, y_pos + 100), 10, GRAY_LIGHT)
        draw.text((80, y_pos + 30), setting, fill=TEXT_DARK, font=ImageFont.load_default())
        draw.text((WIDTH - 100, y_pos + 30), ">", fill=GRAY, font=ImageFont.load_default())
        y_pos += 120
    
    # 同步状态
    draw_rounded_rect(draw, (50, HEIGHT - 350, WIDTH-50, HEIGHT - 200), 15, GRAY_LIGHT)
    draw.text((80, HEIGHT - 320), "同步状态", fill=TEXT_DARK, font=ImageFont.load_default())
    draw.text((80, HEIGHT - 270), "上次同步：5分钟前", fill=TEXT_LIGHT, font=ImageFont.load_default())
    draw.text((80, HEIGHT - 230), "已同步 128 个文档", fill=PRIMARY, font=ImageFont.load_default())
    
    draw_bottom_nav(draw)
    
    img.save('/home/a/scanpdf/screenshots/05_cloud_sync.png')
    print("✓ 截图5：云同步设置")

if __name__ == '__main__':
    print("正在生成应用商店截图...")
    create_screenshot_1()
    create_screenshot_2()
    create_screenshot_3()
    create_screenshot_4()
    create_screenshot_5()
    print("\n✅ 所有截图已生成！")
    print("位置：/home/a/scanpdf/screenshots/")
