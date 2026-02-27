# My Note - Flutter 移动端

> 本地优先的跨设备笔记应用，支持 iOS 和 Android

## ✨ 功能特性

- 📝 **富文本编辑** - 基于 flutter_quill，支持格式化文本、图片、列表等
- 🔄 **实时同步** - 通过 HTTP + WebSocket 与桌面端同步
- 📱 **离线优先** - 完整的本地数据库，离线可用
- 🔍 **全文搜索** - FTS5 全文搜索引擎，支持中文分词
- 📁 **文件夹管理** - 树形文件夹结构，灵活组织笔记
- 🔐 **设备配对** - QR 码扫描配对，安全便捷
- 🖼️ **图片处理** - 自动压缩，Base64 嵌入
- 📤 **导出功能** - 支持 Markdown、PDF、纯文本导出
- ⚡ **冲突解决** - 智能检测同步冲突，提供多种解决方案

## 🛠️ 技术栈

- **Flutter** 3.41.2 - 跨平台 UI 框架
- **Riverpod** 2.6.1 - 状态管理
- **Drift** 2.21.0 - SQLite 数据库 ORM
- **flutter_quill** 11.5.0 - 富文本编辑器
- **Dio** 5.4.1 - HTTP 客户端
- **WebSocket** - 实时通信
- **nsd** 2.3.0 - mDNS 服务发现

## 📋 系统要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- iOS 12.0+ / Android 5.0+ (API 21+)
- 桌面端应用（用于同步）

## 🚀 快速开始

### 1. 安装依赖

```bash
cd mobile
flutter pub get
```

### 2. 生成代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 运行应用

```bash
# 连接设备后运行
flutter run

# 或指定设备
flutter run -d <device-id>
```

## 📱 设备配对

1. 启动桌面端应用
2. 在桌面端生成配对码
3. 打开移动端应用
4. 扫描桌面端显示的 QR 码
5. 配对成功后自动开始同步

## 🔧 开发指南

### 项目结构

```
mobile/
├── lib/
│   ├── core/              # 核心工具和常量
│   ├── data/              # 数据层
│   │   ├── database/      # Drift 数据库
│   │   ├── models/        # 数据模型
│   │   ├── repositories/  # 业务逻辑
│   │   └── services/      # 服务层
│   └── presentation/      # UI 层
│       ├── providers/     # Riverpod providers
│       ├── screens/       # 页面
│       └── widgets/       # 组件
├── test/                  # 单元测试
└── integration_test/      # 集成测试
```

### 代码规范

- 使用 Riverpod 进行状态管理
- 遵循 Flutter 官方代码风格
- 所有数据库操作通过 Repository 层
- UI 组件保持无状态，状态由 Provider 管理

## 📦 构建部署

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (推荐用于 Google Play)
flutter build appbundle --release
```

### iOS

```bash
# 需要 macOS 和 Xcode
flutter build ios --release
```

### 使用 Codemagic CI/CD

项目已配置 `codemagic.yaml`，推送到 GitHub 后可自动构建：

1. 访问 https://codemagic.io
2. 连接 GitHub 仓库
3. 选择 workflow 并开始构建
4. 构建完成后下载 APK/IPA

## 🧪 测试

```bash
# 单元测试
flutter test

# 集成测试
flutter test integration_test/
```

## 📄 相关文档

- [BUILD.md](BUILD.md) - 详细构建指南
- [PERFORMANCE.md](PERFORMANCE.md) - 性能优化建议
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 项目总结

## 📝 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
