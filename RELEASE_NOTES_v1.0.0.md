# ScanPDF v1.0.0 Release Notes

**发布日期**: 2026-07-06

## 🎉 首次正式发布

ScanPDF 是一款智能文档扫描应用，类似 CamScanner，支持 OCR 文字识别、PDF 生成、云端同步等功能。

## ✨ 核心功能

### 📸 智能扫描
- **自动边缘检测**: 使用 Canny 边缘检测和轮廓分析算法
- **透视矫正**: 自动校正拍摄角度，生成平整文档
- **文档增强**: 提升对比度、锐度和清晰度
- **多种滤镜**: 灰度、黑白、魔法等多种处理模式

### 🔍 OCR 文字识别
- **多语言支持**: 中文、英文、日文、韩文
- **Google ML Kit**: 移动端快速离线识别
- **Tesseract OCR**: 服务端高精度识别
- **文字块分析**: 支持置信度和位置信息

### 📄 PDF 生成
- **多图转 PDF**: 将多张图片合并为单个 PDF
- **可搜索 PDF**: OCR 文字层嵌入
- **打印支持**: 直接打印文档
- **分享功能**: 导出和分享 PDF

### 📁 文档管理
- **本地存储**: SQLite 数据库，数据不丢失
- **云端同步**: 支持后端服务同步
- **标签分类**: 灵活的文档组织方式
- **收藏功能**: 快速访问重要文档

## 📱 平台支持

- ✅ **Android** - Flutter 应用
- ✅ **iOS** - Flutter 应用
- ✅ **macOS** - Flutter 应用
- ✅ **HarmonyOS** - Flutter + 原生桥接
- ✅ **Web API** - FastAPI 后端服务

## 🏗️ 技术架构

### 客户端
- **Flutter 3.10+** - 跨平台 UI 框架
- **BLoC** - 状态管理
- **Google ML Kit** - OCR 识别
- **SQLite** - 本地数据库
- **image** - 图像处理

### 服务端
- **FastAPI** - 高性能 Web 框架
- **PostgreSQL** - 关系型数据库
- **Redis** - 缓存和会话管理
- **Tesseract OCR** - 服务端 OCR
- **ReportLab** - PDF 生成

### 部署
- **Docker Compose** - 一键部署
- **Nginx** - 反向代理
- **Let's Encrypt** - SSL 证书
- **Alembic** - 数据库迁移

## 🔒 安全特性

- JWT 认证机制
- bcrypt 密码加密
- HTTPS/SSL 支持
- CORS 配置
- 输入验证

## 📦 安装与部署

### Docker 部署（推荐）

```bash
git clone https://github.com/yourusername/scanpdf.git
cd scanpdf
docker compose up -d
```

访问: `https://your-domain.com/api/v1/docs`

### Flutter 客户端

```bash
cd flutter_app
flutter pub get
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build macos --release  # macOS
```

## 📚 文档

- [API 文档](https://your-domain.com/api/v1/docs)
- [部署指南](deploy/deploy.sh)
- [快速开始](QUICKSTART.md)
- [贡献指南](CONTRIBUTING.md)

## 🐛 Bug 修复

- 修复 `pubspec.yaml` 空资源目录导致构建失败的问题
- 修复认证模块未使用 User 模型的问题
- 清理 fonts 目录下的错误文件

## 🔄 升级说明

这是首个正式发布版本，无需升级操作。

## 📝 已知问题

- 部分功能的分享和重命名特性尚未实现（标记为 TODO）
- PDF 分割功能待实现
- 鸿蒙 HAP 构建需要进一步测试

## 🙏 致谢

感谢所有开源项目的启发：
- OpenScan
- MakeACopy
- CleanSCAN

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

**完整更新日志**: 查看 [CHANGELOG.md](CHANGELOG.md)
