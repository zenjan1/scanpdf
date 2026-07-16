# ScanPDF 应用市场发布指南

## ✅ 已完成准备

### 1. 隐私政策
- **网页地址**: https://zenjan1.github.io/scanpdf/privacy.html
- **源文件**: `/home/a/scanpdf/privacy.html`

### 2. 应用截图 (1080x2340)
已生成 5 张专业截图：
1. `01_scan_interface.png` - 主扫描界面
2. `02_ocr_result.png` - OCR 识别结果
3. `03_pdf_features.png` - PDF 处理功能
4. `04_document_management.png` - 文档管理
5. `05_cloud_sync.png` - 云同步设置

### 3. 应用信息
- **包名**: `com.scanpdf.app`
- **版本**: 1.2.0
- **APK 位置**: `/home/a/scanpdf/release/v1.2.0/scanpdf-v1.2.0.apk`
- **签名密钥**: `/home/a/scanpdf/flutter_app/android/app/upload-keystore.jks`

### 4. 商店描述
详见 `STORE_LISTING.md` 和 `STORE_MATERIALS.md`

---

## 📱 应用市场发布步骤

### 1. Google Play (全球市场)

**注册**: https://play.google.com/console/signup ($25 一次性)

**发布步骤**:
1. 登录 Google Play Console
2. 创建应用 → 选择"应用" → "免费"
3. 填写商店信息：
   - 应用名称：ScanPDF
   - 简短描述：Smart document scanner with OCR, PDF generation
   - 完整描述：从 `STORE_LISTING.md` 复制英文版
4. 上传截图：
   - 手机截图：上传全部 5 张
   - 平板截图（可选）：可复用手机截图
5. 上传 APK：`release/v1.2.0/scanpdf-v1.2.0.apk`
6. 内容分级：Everyone
7. 定价：免费
8. 隐私政策：https://zenjan1.github.io/scanpdf/privacy.html
9. 提交审核（1-3 天）

---

### 2. 华为应用市场 (中国)

**已注册**: ✅ 华为开发者账号

**发布步骤**:
1. 登录华为 AppGallery Connect
2. 创建应用 → 包名 `com.scanpdf.app`
3. 填写信息：
   - 应用名称：ScanPDF
   - 一句话简介：智能文档扫描，OCR识别，PDF生成
   - 详细介绍：从 `STORE_LISTING.md` 复制中文版
4. 上传截图（至少 3 张）
5. 上传 APK
6. 隐私政策链接：https://zenjan1.github.io/scanpdf/privacy.html
7. 软件版权证书（可选，建议后续补充）
8. 提交审核（1-3 天）

---

### 3. 小米应用商店

**注册**: https://dev.mi.com (免费)

**发布步骤**:
1. 实名认证（身份证）
2. 创建应用 → 包名 `com.scanpdf.app`
3. 填写信息（同华为）
4. 上传 APK + 截图
5. 隐私政策链接
6. 提交审核（1-3 天）

---

### 4. OPPO 软件商店

**注册**: https://open.oppomobile.com (免费)

**发布步骤**:
1. 实名认证
2. 应用管理 → 创建应用
3. 填写信息
4. 上传 APK + 截图
5. 隐私政策链接
6. 提交审核

---

### 5. vivo 应用商店

**注册**: https://dev.vivo.com.cn (免费)

**发布步骤**:
1. 实名认证
2. 创建应用
3. 填写信息
4. 上传 APK + 截图
5. 隐私政策链接
6. 提交审核

---

### 6. 应用宝 (腾讯)

**注册**: https://app.open.qq.com (免费)

**发布步骤**:
1. QQ 登录 + 实名认证
2. 创建应用
3. 填写信息
4. 上传 APK + 截图
5. 隐私政策链接
6. 提交审核

---

## 📋 发布检查清单

### 通用要求
- [x] 隐私政策网页
- [x] 应用截图 (5张)
- [x] 应用图标 (512x512)
- [x] APK 文件 (已签名)
- [x] 商店描述 (中英文)
- [x] 联系邮箱：support@scanpdf.zenjan.store

### 各市场账号状态
- [x] 华为应用市场 - 已注册
- [ ] Google Play - 待注册 ($25)
- [ ] 小米应用商店 - 待注册
- [ ] OPPO 软件商店 - 待注册
- [ ] vivo 应用商店 - 待注册
- [ ] 应用宝 - 待注册

---

## 🔧 技术细节

### 应用权限
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### 内容分级
- 选择"所有人"或"Everyone"
- 无暴力、无成人内容、无赌博

### 关键词优化
**中文**: 扫描,文档扫描,OCR,文字识别,PDF,扫描仪,图片转PDF,证件扫描,发票扫描

**英文**: scanner,document scanner,OCR,text recognition,PDF,document scan,image to PDF

---

## 📞 联系信息

- **支持邮箱**: support@scanpdf.zenjan.store
- **隐私政策**: https://zenjan1.github.io/scanpdf/privacy.html
- **官方网站**: https://zenjan1.github.io/scanpdf/
- **源码仓库**: https://github.com/zenjan1/scanpdf

---

## 🚀 下一步行动

### 立即执行
1. **注册 Google Play** (最重要，全球市场)
   - 访问：https://play.google.com/console/signup
   - 支付 $25
   - 等待审核

2. **注册其他市场** (按顺序)
   - 小米 → OPPO → vivo → 应用宝

3. **提交应用**
   - 先提交华为（已注册）
   - 再提交 Google Play
   - 最后提交其他市场

### 预计时间
- 账号注册：1-2 天
- 应用审核：3-7 天
- 全部上架：1-2 周

---

## 💡 提示

1. **首次提交建议**：
   - 先提交 1-2 个市场，熟悉流程
   - 遇到问题及时调整
   - 再批量提交其他市场

2. **审核注意事项**：
   - 确保隐私政策可访问
   - 截图清晰，展示核心功能
   - 描述真实，不夸大功能
   - APK 无病毒，无恶意代码

3. **后续优化**：
   - 收集用户反馈
   - 定期更新版本
   - 回复用户评价
   - 优化商店页面
