# ScanPDF 快速开始指南

## 🚀 5 分钟快速启动

### 前置要求

**客户端开发：**
- Flutter 3.10+ 已安装
- Android Studio（Android 开发）
- Xcode（iOS/macOS 开发）
- DevEco Studio（鸿蒙开发）

**服务端部署：**
- Docker 和 Docker Compose
- 域名已解析到服务器（如 jp.zenjan.store）
- 服务器端口 80/443 已开放

---

## 📱 客户端开发

### 1. 安装依赖

```bash
cd flutter_app
flutter pub get
```

### 2. 运行应用

**Android:**
```bash
flutter run -d android
# 或指定设备
flutter devices  # 查看可用设备
flutter run -d <device_id>
```

**iOS/macOS:**
```bash
flutter run -d ios
flutter run -d macos
```

**鸿蒙:**
使用 DevEco Studio 打开 `flutter_app/harmony` 目录

### 3. 构建发布包

**Android APK:**
```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle:**
```bash
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab
```

**iOS IPA:**
```bash
flutter build ios --release
# 然后在 Xcode 中 Archive 并导出 IPA
```

**macOS DMG:**
```bash
flutter build macos --release
# 输出: build/macos/Build/Products/Release/ScanPDF.app
```

---

## 🖥️ 服务端部署

### 方式一：一键部署（推荐）

```bash
# 1. SSH 登录服务器
ssh ubuntu@jp.zenjan.store

# 2. 克隆项目
git clone <your-repo-url> /home/ubuntu/scanpdf
cd /home/ubuntu/scanpdf

# 3. 运行部署脚本
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

脚本会自动：
- 安装 Docker 和依赖
- 申请 SSL 证书
- 启动所有服务
- 配置 Nginx 反向代理

### 方式二：手动部署

```bash
# 1. 准备环境变量
cp server/.env.example server/.env
nano server/.env
# 修改 SECRET_KEY、DATABASE_URL 等配置

# 2. 启动服务
docker compose up -d

# 3. 查看日志
docker compose logs -f backend

# 4. 申请 SSL 证书（首次）
sudo certbot --nginx -d jp.zenjan.store
```

---

## 🧪 测试

### 客户端测试

```bash
cd flutter_app

# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 生成测试覆盖率
flutter test --coverage
```

### 服务端测试

```bash
cd server

# 创建虚拟环境
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 运行测试
pytest tests/

# 运行特定测试
pytest tests/test_main.py -v
```

---

## 🔧 开发配置

### Flutter 环境

**检查环境:**
```bash
flutter doctor
```

**常见问题:**
- Android SDK 未安装：安装 Android Studio 并配置 SDK
- Xcode 未安装：从 App Store 安装 Xcode 并运行 `sudo xcode-select --switch /Applications/Xcode.app`
- CocoaPods 未安装：`sudo gem install cocoapods`

### Python 环境

**创建虚拟环境:**
```bash
cd server
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

**IDE 配置:**
- VS Code: 安装 Python、Django 插件
- PyCharm: 配置项目解释器为虚拟环境

---

## 📖 API 测试

### 使用 Swagger UI

访问：https://jp.zenjan.store/api/v1/docs

### 使用 curl

**注册:**
```bash
curl -X POST https://jp.zenjan.store/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","username":"测试用户"}'
```

**登录:**
```bash
curl -X POST https://jp.zenjan.store/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**上传文档:**
```bash
curl -X POST https://jp.zenjan.store/api/v1/documents \
  -H "Authorization: Bearer <your_token>" \
  -F "file=@test.pdf" \
  -F "title=测试文档" \
  -F "tags=测试,文档"
```

**获取文档列表:**
```bash
curl -X GET https://jp.zenjan.store/api/v1/documents \
  -H "Authorization: Bearer <your_token>"
```

---

## 🐛 常见问题

### 客户端问题

**Q: Flutter 运行时报错 "No connected devices"**
```bash
# 查看可用设备
flutter devices

# Android 模拟器
flutter emulators --create  # 创建模拟器
flutter emulators --launch <emulator_id>  # 启动模拟器

# iOS 模拟器
open -a Simulator
```

**Q: Android 构建失败 "SDK location not found"**
```bash
# 设置 ANDROID_HOME
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

**Q: iOS 构建失败 "CocoaPods not installed"**
```bash
sudo gem install cocoapods
cd ios
pod install
```

### 服务端问题

**Q: Docker 构建失败**
```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建
docker compose build --no-cache
```

**Q: 数据库连接失败**
```bash
# 检查 PostgreSQL 是否运行
docker compose ps

# 查看数据库日志
docker compose logs postgres

# 重启数据库
docker compose restart postgres
```

**Q: 502 Bad Gateway**
```bash
# 检查后端服务
docker compose logs backend

# 重启服务
docker compose restart backend nginx
```

---

## 📊 性能优化

### 客户端

**减少应用大小:**
```bash
# 构建时压缩
flutter build apk --release --split-per-abi

# 移除未使用的资源
flutter clean
flutter pub get
```

**优化启动速度:**
- 延迟初始化非关键服务
- 使用 `deferred components` 按需加载
- 预编译关键路径

### 服务端

**数据库优化:**
```sql
-- 添加索引
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_created_at ON documents(created_at);
```

**缓存策略:**
- Redis 缓存热点数据
- 客户端缓存文档列表
- CDN 加速静态资源

---

## 🔐 安全配置

### 生产环境检查清单

**服务端:**
- [ ] 修改 `SECRET_KEY` 为随机长字符串
- [ ] 修改数据库密码
- [ ] 配置 CORS 允许的域名
- [ ] 启用 HTTPS（SSL 证书）
- [ ] 设置文件上传大小限制
- [ ] 配置日志级别为 WARNING
- [ ] 禁用 DEBUG 模式
- [ ] 定期备份数据库

**客户端:**
- [ ] 使用 Release 模式构建
- [ ] 代码混淆（Android ProGuard）
- [ ] 证书固定（Certificate Pinning）
- [ ] 敏感数据加密存储

---

## 📦 发布流程

### Android

1. **准备签名密钥:**
```bash
keytool -genkey -v -keystore ~/upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

2. **配置 Gradle:**
编辑 `android/app/build.gradle`，配置签名

3. **构建 App Bundle:**
```bash
flutter build appbundle --release
```

4. **上传到 Google Play Console**

### iOS

1. **配置 Xcode:**
   - 设置 Team 和 Bundle Identifier
   - 配置签名证书和 Provisioning Profile

2. **Archive:**
   - Xcode → Product → Archive
   - Window → Organizer → Distribute App

3. **上传到 App Store Connect**

### macOS

1. **配置签名:**
   - Xcode → Signing & Capabilities
   - 选择 Team 和证书

2. **构建:**
```bash
flutter build macos --release
```

3. **公证和分发:**
   - 使用 Xcode 导出 DMG
   - 上传到 App Store Connect 或直接分发

---

## 🆘 获取帮助

- 📖 查看完整文档: [README.md](README.md)
- 🏗️ 架构设计: [docs/architecture/OVERVIEW.md](docs/architecture/OVERVIEW.md)
- 📡 API 文档: [docs/api/README.md](docs/api/README.md)
- 🐛 问题反馈: [GitHub Issues](https://github.com/yourusername/scanpdf/issues)

---

**下一步:**
1. 运行 `flutter doctor` 检查环境
2. 启动服务端: `docker compose up -d`
3. 运行客户端: `flutter run`
4. 开始开发！
