# ScanPDF 架构设计文档

## 系统架构

### 整体架构

ScanPDF 采用前后端分离的架构设计：

```
┌─────────────────────────────────────────────────────────┐
│                    客户端层 (Flutter)                      │
├─────────────────────────────────────────────────────────┤
│  Android  │  HarmonyOS  │  iOS  │  macOS                │
├─────────────────────────────────────────────────────────┤
│  UI Layer (Presentation) - BLoC Pattern                 │
│  ├── Camera Screen  ├── Scanner Screen                 │
│  ├── OCR Screen     ├── Document List                   │
│  └── Settings       └── Navigation                      │
├─────────────────────────────────────────────────────────┤
│  Business Logic Layer (Domain)                          │
│  ├── Entities (Document, User, ScanResult)              │
│  ├── Use Cases (CreateDocument, ExtractText)            │
│  └── Repository Interfaces                              │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                             │
│  ├── Local Storage (SQLite)                             │
│  ├── Remote API (HTTP/Dio)                              │
│  └── File System                                        │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTPS
┌─────────────────────────────────────────────────────────┐
│                    服务器层 (FastAPI)                      │
├─────────────────────────────────────────────────────────┤
│  API Layer (Routes)                                     │
│  ├── /api/v1/documents  - 文档管理                       │
│  ├── /api/v1/auth       - 用户认证                       │
│  ├── /api/v1/ocr        - OCR 识别                      │
│  └── /api/v1/scan       - 扫描处理                       │
├─────────────────────────────────────────────────────────┤
│  Service Layer                                          │
│  ├── OCR Service (Tesseract)                            │
│  ├── Image Processor (OpenCV)                           │
│  ├── PDF Generator (ReportLab)                          │
│  └── Sync Service                                       │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                             │
│  ├── PostgreSQL Database                                │
│  ├── Redis Cache                                        │
│  └── File Storage                                       │
└─────────────────────────────────────────────────────────┘
```

## 核心模块

### 1. 相机模块 (Camera)
- **功能**：文档拍摄、自动对焦、闪光灯控制、批量拍摄
- **技术**：camera package, CameraX (Android)
- **特性**：
  - 实时边缘检测预览
  - 自动曝光和白平衡
  - 连拍模式

### 2. 扫描处理模块 (Scanner)
- **功能**：边缘检测、透视矫正、图像增强
- **技术**：OpenCV, Google ML Kit
- **处理流程**：
  1. 边缘检测 (Canny)
  2. 轮廓识别
  3. 透视变换
  4. 图像增强（对比度、锐化、去阴影）

### 3. OCR 模块
- **功能**：文字识别、多语言支持
- **技术**：Google ML Kit (客户端), Tesseract (服务端)
- **支持语言**：中文、英文、日文、韩文

### 4. 文档管理模块 (Document)
- **功能**：文档 CRUD、标签管理、搜索、收藏
- **存储**：SQLite (本地), PostgreSQL (云端)
- **同步**：离线优先，自动同步

### 5. PDF 生成模块
- **功能**：图片转 PDF、多页合并、可搜索 PDF
- **技术**：pdf package, ReportLab
- **特性**：
  - 自定义页面大小
  - 文字层嵌入（OCR 结果）
  - 压缩优化

## 数据流

### 扫描流程

```
拍照 → 边缘检测 → 透视矫正 → 图像增强 → OCR(可选) → PDF生成 → 保存
  ↓         ↓          ↓          ↓           ↓          ↓
Camera  OpenCV     OpenCV    OpenCV    MLKit/Tesseract  ReportLab
```

### 同步流程

```
本地操作 → SQLite → 标记变更 → 后台同步 → API → PostgreSQL
                                              ↓
                                         Redis Cache
```

## 技术栈详解

### 客户端
- **Flutter 3.10+**：跨平台 UI
- **BLoC**：状态管理
- **GetIt**：依赖注入
- **GoRouter**：路由管理
- **Google ML Kit**：OCR + 文档扫描
- **OpenCV**：图像处理
- **SQLite**：本地数据库
- **Dio**：HTTP 客户端

### 服务端
- **FastAPI**：高性能 API
- **PostgreSQL**：主数据库
- **Redis**：缓存 + 会话
- **Tesseract**：OCR
- **OpenCV**：图像处理
- **ReportLab**：PDF 生成
- **Alembic**：数据库迁移

## 安全设计

### 认证
- JWT Token 认证
- Bearer Token
- 密码 bcrypt 加密

### 数据安全
- HTTPS 传输加密
- 本地数据库加密（可选）
- 文件访问控制

### API 安全
- CORS 配置
- 请求频率限制
- 文件大小限制
- 输入验证

## 性能优化

### 客户端
- 懒加载和分页
- 图片缓存
- 异步处理
- 后台同步

### 服务端
- 数据库索引优化
- Redis 缓存
- 异步任务队列（可选）
- CDN 加速静态资源

## 可扩展性

### 模块化设计
每个功能模块独立，可单独开发、测试、部署。

### 插件化架构
OCR、图像处理等核心功能可替换不同实现。

### 多端适配
Flutter 跨平台，一套代码多端运行。

## 未来规划

### 短期
- [ ] 完善文档详情页面
- [ ] 添加文档编辑功能
- [ ] 实现批量操作
- [ ] 添加更多滤镜效果

### 中期
- [ ] 实时扫描（视频流）
- [ ] 手写识别
- [ ] 表格识别
- [ ] 证件扫描（身份证、护照）

### 长期
- [ ] AI 文档分类
- [ ] 智能关键词提取
- [ ] 多人协作
- [ ] 工作流自动化
