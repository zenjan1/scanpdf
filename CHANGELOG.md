# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-06

### 🎉 首次正式发布

#### ✨ 新增功能
- **智能扫描**
  - 自动边缘检测（Canny + 轮廓检测）
  - 透视矫正（四点变换）
  - 文档增强（对比度、锐化、自适应阈值）
  - 灰度转换和黑白模式
  
- **OCR 文字识别**
  - 支持中英文、日文、韩文
  - Google ML Kit 移动端识别
  - Tesseract OCR 服务端识别
  - 文字块级别置信度分析
  
- **PDF 生成**
  - 从多张图片生成 PDF
  - 可搜索 PDF（隐藏文字层）
  - PDF 合并功能
  - 打印和分享功能
  
- **文档管理**
  - 本地 SQLite 数据库
  - 云端同步支持
  - 标签分类系统
  - 收藏和搜索功能
  - 缩略图生成
  
- **图像处理**
  - 自动裁剪空白边缘
  - 多种滤镜效果（原图、灰度、增强、黑白、魔法）
  - 批量图像处理
  - 缩略图生成

#### 📱 平台支持
- ✅ Android（Flutter）
- ✅ iOS（Flutter）
- ✅ macOS（Flutter）
- ✅ HarmonyOS（Flutter + 原生桥接）
- ✅ Web API（FastAPI）

#### 🏗️ 架构
- **客户端**: Flutter 3.10+ with BLoC state management
- **服务端**: FastAPI + PostgreSQL + Redis
- **部署**: Docker Compose + Nginx + SSL
- **OCR**: Google ML Kit (客户端) + Tesseract (服务端)

#### 🔒 安全特性
- JWT 认证
- bcrypt 密码加密
- HTTPS/SSL 支持
- CORS 配置
- 输入验证

#### 📦 部署
- Docker Compose 一键部署
- Nginx 反向代理配置
- Let's Encrypt SSL 证书自动化
- 数据库迁移脚本

#### 📚 文档
- 完整的 API 文档（Swagger/ReDoc）
- 部署指南
- 快速开始文档
- 架构说明

---

## [0.1.0] - 2026-07-02

### 🚧 初始版本

- 项目初始化
- 基础架构搭建
- 核心功能开发
- 内部测试版本

---

[1.0.0]: https://github.com/zenjan1/scanpdf/releases/tag/v1.0.0
[0.1.0]: https://github.com/zenjan1/scanpdf/releases/tag/v0.1.0
