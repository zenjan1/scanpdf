# Release Notes v1.3.0

## 新功能

### 自动更新功能
- ✅ 应用启动后自动检查 GitHub Releases 最新版本
- ✅ 发现新版本时弹出更新对话框，显示版本信息、更新日志、APK 大小
- ✅ 用户可选择：立即更新 / 跳过此版本 / 稍后更新
- ✅ 下载 APK 并自动调用系统安装
- ✅ 设置页面添加"检查更新"入口，支持手动检查

### 技术实现
- 新增 `UpdateService`：从 GitHub Releases API 获取版本信息，下载 APK
- 新增 `UpdateBloc`：BLoC 状态管理，处理更新流程
- 新增 `UpdateDialog`：更新提示弹窗 UI
- 添加依赖：`package_info_plus`（获取当前版本）、`open_file`（安装 APK）
- 应用启动 3 秒后自动检查更新，避免影响启动速度

## 修复
- 修复 scanner_screen.dart 中重复方法声明问题
- 修复 update_dialog.dart 中逻辑错误
- 禁用 R8 混淆以解决 ML Kit 类缺失问题
- 修复测试中 Timer 未取消的问题

## 构建信息
- APK 大小：30.4MB
- 版本号：1.3.0+5
- 测试状态：✅ 全部通过
