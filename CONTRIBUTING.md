# Contributing to ScanPDF

首先，感谢您考虑为 ScanPDF 做出贡献！

## 📋 行为准则

本项目采用友善的行为准则，旨在为所有贡献者创造一个开放和友好的环境。

## 🚀 如何贡献

### 报告 Bug

如果您发现 Bug，请创建一个 Issue 并包含以下信息：

1. 清晰的标题
2. 重现步骤
3. 预期行为
4. 实际行为
5. 环境信息（操作系统、Flutter 版本等）
6. 截图或错误日志（如果适用）

### 提出新功能

欢迎新功能建议！请创建 Issue 并标记为 `enhancement`，讨论：

- 功能描述
- 使用场景
- 实现思路（可选）

### 提交 Pull Request

#### 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

#### 代码规范

**Flutter/Dart:**
- 遵循 [Effective Dart](https://dart.dev/guides/style)
- 使用 `flutter format` 格式化代码
- 确保 `flutter analyze` 无警告
- 添加必要的注释和文档
- 编写单元测试

**Python:**
- 遵循 [PEP 8](https://pep8.org/)
- 使用 `black` 格式化代码
- 使用 `flake8` 或 `pylint` 检查代码
- 添加类型提示
- 编写测试用例

#### 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型 (type):**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具/依赖更新

**示例:**
```
feat(scanner): 添加自动边缘检测功能

- 实现 Canny 边缘检测
- 添加轮廓检测算法
- 支持四边形自动识别

Closes #12
```

### 开发环境设置

#### Flutter 客户端

```bash
# 克隆仓库
git clone https://github.com/yourusername/scanpdf.git
cd scanpdf/flutter_app

# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行应用
flutter run
```

#### Python 服务端

```bash
# 进入服务端目录
cd server

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 运行测试
pytest

# 启动服务
uvicorn main:app --reload
```

### 测试

**Flutter:**
```bash
cd flutter_app
flutter test
```

**Python:**
```bash
cd server
pytest tests/
```

### 文档贡献

- 改进 README.md
- 添加使用示例
- 更新 API 文档
- 翻译文档

## 💡 贡献建议

### 适合新手的任务

- 修复文档错误
- 添加单元测试
- 改进错误信息
- 优化 UI 文案
- 添加代码注释

### 高级任务

- 实现新功能
- 性能优化
- 重构复杂模块
- 添加新的平台支持

## 📝 代码审查流程

所有 Pull Request 都需要经过代码审查：

1. 自动化检查（CI/CD）
2. 至少一位维护者审查
3. 解决所有评论
4. 合并到主分支

## 🔧 开发工具

推荐使用：
- **IDE**: VS Code 或 Android Studio
- **Flutter 扩展**: Dart, Flutter
- **Python 扩展**: Python, Pylance, Black
- **版本控制**: Git with GitLens

## ❓ 需要帮助？

- 查看 [README.md](README.md)
- 查看现有 Issues
- 加入讨论

## 📄 许可证

通过贡献代码，您同意您的贡献将使用相同的 MIT 许可证。

---

再次感谢您的贡献！🎉
