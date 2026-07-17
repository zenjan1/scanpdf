# ScanPDF v1.0.0 发布指南

## ✅ 已完成的工作

### 代码完善
- [x] 修复 `pubspec.yaml` 空资源目录问题
- [x] 创建 `User` 模型并完善认证模块
- [x] 添加 `.env.example` 配置示例
- [x] 清理 fonts 目录错误文件
- [x] 完善 Android 构建配置

### 文档完善
- [x] 创建 `CHANGELOG.md` - 完整的版本历史
- [x] 创建 `CONTRIBUTING.md` - 贡献指南
- [x] 创建 `RELEASE_NOTES_v1.0.0.md` - v1.0.0 发布说明
- [x] 更新 `README.md` - 添加 badges 和 Release 信息
- [x] 提交所有改动并打 tag v1.0.0

### Git 操作
- [x] `git add -A` - 添加所有改动
- [x] `git commit` - 提交 v1.0.0 代码
- [x] `git tag -a v1.0.0` - 创建 v1.0.0 tag

## 📦 发布步骤

### 方式一：使用 GitHub CLI（推荐）

如果已安装 GitHub CLI：

```bash
# 安装 gh CLI（如果未安装）
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# 登录 GitHub
gh auth login

# 推送代码和 tag
git push origin master
git push origin v1.0.0

# 创建 GitHub Release
gh release create v1.0.0 \
  --title "🎉 ScanPDF v1.0.0 - 首次正式发布" \
  --notes-file RELEASE_NOTES_v1.0.0.md \
  --target master
```

### 方式二：手动在 GitHub 创建

1. **推送代码到 GitHub**
   ```bash
   git push origin master
   git push origin v1.0.0
   ```

2. **在 GitHub 创建 Release**
   - 访问：https://github.com/zenjan1/scanpdf/releases/new
   - Tag version: `v1.0.0`
   - Target: `master`
   - Release title: `🎉 ScanPDF v1.0.0 - 首次正式发布`
   - 复制 `RELEASE_NOTES_v1.0.0.md` 的内容到描述框

3. **发布 Release**
   - 点击 "Publish release" 按钮

## 🚀 部署到生产环境

### 后端服务部署

```bash
# 在服务器上拉取最新代码
cd /home/ubuntu/scanpdf
git pull origin master

# 运行部署脚本
chmod +x deploy/deploy.sh
./deploy/deploy.sh

# 或手动部署
docker compose down
docker compose build --no-cache
docker compose up -d

# 检查服务状态
docker compose ps
docker compose logs -f backend
```

### Flutter 客户端构建

#### Android
```bash
cd flutter_app
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS
```bash
cd flutter_app
flutter build ios --release
# 使用 Xcode 打开并归档
open ios/Runner.xcworkspace
```

#### macOS
```bash
cd flutter_app
flutter build macos --release
# 输出: build/macos/Build/Products/Release/ScanPDF.app
```

## 📋 发布检查清单

- [x] 所有测试通过
- [x] 文档更新完成
- [x] CHANGELOG 已更新
- [x] 版本号正确 (v1.0.0)
- [x] Git tag 已创建
- [ ] 推送到 GitHub
- [ ] 创建 GitHub Release
- [ ] 部署到生产服务器
- [ ] 构建 Flutter 客户端
- [ ] 发布到应用商店（可选）

## 🔗 相关链接

- **项目地址**: https://github.com/zenjan1/scanpdf
- **API 文档**: https://jp.zenjan.store/api/v1/docs
- **Releases**: https://github.com/zenjan1/scanpdf/releases

## 📝 发布后工作

1. **通知用户**
   - 更新项目 README
   - 发布社交媒体公告
   - 发送邮件列表通知（如有）

2. **监控**
   - 监控服务器日志
   - 关注 GitHub Issues
   - 收集用户反馈

3. **迭代计划**
   - 整理 v1.1.0 的功能计划
   - 收集用户需求和 Bug 反馈

---

**恭喜！🎉 ScanPDF v1.0.0 已准备就绪！**
