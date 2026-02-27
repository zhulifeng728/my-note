# Flutter 移动端构建指南

## 环境要求

### Android
- Android Studio
- Android SDK (API 21+)
- Java 8+

### iOS
- Xcode 14+
- CocoaPods
- macOS

## 构建步骤

### 1. 安装依赖

```bash
cd mobile
flutter pub get
```

### 2. 生成代码

```bash
# 生成 Drift 数据库代码
flutter pub run build_runner build --delete-conflicting-outputs

# 或者使用 watch 模式（开发时）
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Android 构建

#### Debug 版本
```bash
flutter build apk --debug
```

#### Release 版本
```bash
flutter build apk --release
```

#### App Bundle（推荐用于 Google Play）
```bash
flutter build appbundle --release
```

输出位置：
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 4. iOS 构建

#### Debug 版本
```bash
flutter build ios --debug
```

#### Release 版本
```bash
flutter build ios --release
```

#### 使用 Xcode 构建
```bash
open ios/Runner.xcworkspace
```

然后在 Xcode 中选择 Product > Archive

### 5. 签名配置

#### Android 签名

1. 创建密钥库：
```bash
keytool -genkey -v -keystore ~/my-notes-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-notes
```

2. 创建 `android/key.properties`：
```properties
storePassword=<密码>
keyPassword=<密码>
keyAlias=my-notes
storeFile=<密钥库路径>
```

3. 更新 `android/app/build.gradle`：
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### iOS 签名

在 Xcode 中配置：
1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner 项目
3. 在 Signing & Capabilities 中配置 Team 和 Bundle Identifier

## 测试

### 运行测试
```bash
flutter test
```

### 运行集成测试
```bash
flutter test integration_test
```

## 常见问题

### 1. Drift 代码生成失败
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Android 构建失败
- 检查 Android SDK 版本
- 清理构建缓存：`flutter clean`
- 检查 Gradle 版本

### 3. iOS 构建失败
- 运行 `pod install` 在 ios 目录
- 清理 Xcode 缓存：Product > Clean Build Folder
- 检查证书和配置文件

## 发布

### Google Play
1. 构建 App Bundle：`flutter build appbundle --release`
2. 上传到 Google Play Console
3. 填写应用信息和截图
4. 提交审核

### App Store
1. 在 Xcode 中 Archive
2. 上传到 App Store Connect
3. 填写应用信息和截图
4. 提交审核

## 版本管理

更新版本号在 `pubspec.yaml`：
```yaml
version: 1.0.0+1
```

格式：`主版本.次版本.修订号+构建号`
