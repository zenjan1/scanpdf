# ScanPDF - 智能扫描办公

> 一款类似扫描全能王（CamScanner）的开源文档扫描应用，支持安卓、鸿蒙、macOS 等平台。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-009688.svg)](https://fastapi.tiangolo.com)

## 📱 特性

### 核心功能
- **智能扫描**：自动边缘检测、透视矫正、文档增强
- **OCR 文字识别**：支持中英文、日文、韩文等多语言识别
- **PDF 生成**：从图片生成高质量 PDF，支持多页合并
- **文档管理**：本地存储、云端同步、标签分类、快速搜索
- **隐私保护**：本地优先，数据加密，无广告无追踪

### 平台支持
- ✅ Android（Flutter）
- ✅ HarmonyOS（Flutter + 原生桥接）
- ✅ iOS（Flutter）
- ✅ macOS（Flutter 原生）
- ✅ 后端服务（FastAPI + PostgreSQL）

## 🚀 快速开始

### 环境要求

**Flutter 客户端：**
- Flutter 3.10+
- Dart 3.0+
- Android Studio / VS Code
- Android SDK（Android 开发）
- Xcode（iOS/macOS 开发）
- DevEco Studio（鸿蒙开发）

**后端服务：**
- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose（推荐）

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/scanpdf.git
cd scanpdf
```

### 2. 部署后端服务

```bash
# 进入项目目录
cd /home/ubuntu/scanpdf

# 运行部署脚本
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

或者手动部署：

```bash
# 使用 Docker Compose
docker compose up -d

# 查看日志
docker compose logs -f backend
```

### 3. 配置环境变量

编辑 `server/.env`：

```bash
DATABASE_URL=postgresql://scanpdf:scanpdf_password@postgres:5432/scanpdf
REDIS_URL=redis://redis:6379/0
SECRET_KEY=your-secret-key-here
UPLOAD_DIR=/data/scanpdf/uploads
DEBUG=false
```

### 4. 运行 Flutter 客户端

```bash
# 进入 Flutter 项目目录
cd flutter_app

# 安装依赖
flutter pub get

# 运行应用（Android）
flutter run -d android

# 运行应用（iOS）
flutter run -d ios

# 运行应用（macOS）
flutter run -d macos

# 构建 APK
flutter build apk --release

# 构建鸿蒙 HAP
# 使用 DevEco Studio 打开 harmony 目录构建
```

## 📁 项目结构

```
scanpdf/
├── flutter_app/              # Flutter 客户端
│   ├── lib/
│   │   ├── app/             # 应用入口和路由
│   │   ├── core/            # 核心功能
│   │   │   ├── constants/   # 常量定义
│   │   │   ├── errors/      # 错误处理
│   │   │   ├── services/    # 核心服务
│   │   │   ├── theme/       # 主题配置
│   │   │   └── utils/       # 工具类
│   │   ├── features/        # 功能模块
│   │   │   ├── camera/      # 相机模块
│   │   │   ├── document/    # 文档管理
│   │   │   ├── ocr/         # OCR 识别
│   │   │   ├── scanner/     # 扫描处理
│   │   │   └── settings/    # 设置页面
│   │   └── shared/          # 共享组件
│   ├── android/             # Android 配置
│   ├── ios/                 # iOS 配置
│   ├── macos/               # macOS 配置
│   ├── harmony/             # 鸿蒙配置
│   └── pubspec.yaml         # Flutter 依赖
│
├── server/                  # 后端服务
│   ├── app/
│   │   ├── api/v1/         # API 路由
│   │   │   ├── auth.py     # 用户认证
│   │   │   ├── documents.py # 文档管理
│   │   │   ├── ocr.py      # OCR 接口
│   │   │   └── scan.py     # 扫描处理
│   │   ├── core/           # 核心配置
│   │   │   ├── config/     # 配置文件
│   │   │   ├── middleware/ # 中间件
│   │   │   └── security/   # 安全认证
│   │   ├── models/         # 数据模型
│   │   ├── services/       # 业务服务
│   │   │   ├── image_processor.py  # 图像处理
│   │   │   ├── ocr_service.py      # OCR 服务
│   │   │   └── pdf_service.py      # PDF 生成
│   │   └── utils/          # 工具函数
│   ├── migrations/         # 数据库迁移
│   ├── main.py             # 应用入口
│   ├── requirements.txt    # Python 依赖
│   └── Dockerfile          # Docker 配置
│
├── deploy/                 # 部署配置
│   ├── deploy.sh           # 部署脚本
│   ├── nginx.conf          # Nginx 配置
│   └── ssl/                # SSL 证书目录
│
├── docker-compose.yml      # Docker Compose 配置
└── README.md               # 项目说明
```

## 🔧 技术栈

### 客户端
- **Flutter** - 跨平台 UI 框架
- **BLoC** - 状态管理
- **Google ML Kit** - OCR 文字识别
- **OpenCV** - 图像处理
- **SQLite** - 本地数据库

### 服务端
- **FastAPI** - 高性能 Python Web 框架
- **PostgreSQL** - 关系型数据库
- **Redis** - 缓存和会话管理
- **Tesseract OCR** - 服务端文字识别
- **OpenCV** - 服务端图像处理
- **ReportLab** - PDF 生成

### 部署
- **Docker** - 容器化部署
- **Nginx** - 反向代理
- **Let's Encrypt** - SSL 证书
- **Ubuntu** - 服务器系统

## 📖 API 文档

启动后端服务后，访问以下文档：

- **Swagger UI**: `https://jp.zenjan.store/api/v1/docs`
- **ReDoc**: `https://jp.zenjan.store/api/v1/redoc`
- **OpenAPI JSON**: `https://jp.zenjan.store/api/v1/openapi.json`

### 主要接口

| 模块 | 路径 | 说明 |
|------|------|------|
| 文档 | `/api/v1/documents` | 文档 CRUD |
| 认证 | `/api/v1/auth` | 用户注册/登录 |
| OCR | `/api/v1/ocr/extract` | 文字识别 |
| 扫描 | `/api/v1/scan/*` | 边缘检测、透视矫正、增强 |

## 🧪 测试

### Flutter 测试

```bash
cd flutter_app
flutter test
```

### 后端测试

```bash
cd server
pytest tests/
```

## 📦 构建发布

### Android

```bash
cd flutter_app
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
cd flutter_app
flutter build ios --release
# 使用 Xcode 打开并归档
open ios/Runner.xcworkspace
```

### macOS

```bash
cd flutter_app
flutter build macos --release
# 输出: build/macos/Build/Products/Release/ScanPDF.app
```

### 鸿蒙

使用 DevEco Studio 打开 `flutter_app/harmony` 目录，构建 HAP 包。

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

本项目参考了以下优秀的开源项目：

- [OpenScan](https://github.com/ethereal-developers/OpenScan) - Flutter 文档扫描
- [MakeACopy](https://github.com/egdels/makeacopy) - 离线 OCR 文档扫描
- [CleanSCAN](https://github.com/clean-apps/CleanSCAN) - Android 文档扫描

## 📞 联系方式

- 项目主页: [https://github.com/yourusername/scanpdf](https://github.com/yourusername/scanpdf)
- 问题反馈: [GitHub Issues](https://github.com/yourusername/scanpdf/issues)
- 邮件: admin@zenjan.store

---

**注意**：本项目为演示版本，部分功能需要进一步完善。生产环境部署前，请确保：
1. 修改默认密钥和数据库密码
2. 配置正确的 SSL 证书
3. 配置 CORS 允许的域名
4. 设置适当的上传文件大小限制
5. 启用日志监控和告警
