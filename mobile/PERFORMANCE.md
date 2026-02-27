# Flutter 移动端性能优化指南

## 已实现的优化

### 1. 数据库优化

#### WAL 模式
- 启用 SQLite WAL (Write-Ahead Logging) 模式
- 提升并发读写性能
- 位置：`lib/data/database/app_database.dart`

#### FTS5 全文搜索
- 使用 FTS5 虚拟表进行全文搜索
- 自动维护索引（通过触发器）
- 搜索性能优于 LIKE 查询

#### 索引优化
- 主键索引（id）
- 时间戳索引（updated_at）用于增量同步
- 文件夹索引（folder_id）用于快速查询

### 2. 网络优化

#### 请求防抖
- 搜索防抖：300ms
- 自动保存防抖：500ms
- 同步防抖：2000ms

#### 增量同步
- 仅同步变更的笔记（基于时间戳）
- 减少网络传输量

#### 连接池
- Dio 自动管理 HTTP 连接池
- 复用连接，减少握手开销

#### WebSocket 心跳
- 30 秒心跳保持连接
- 自动重连（指数退避）

### 3. 图片优化

#### 压缩策略
- 最大尺寸：1920x1920px
- JPEG 质量：80%
- 最大文件：10MB
- 使用 flutter_image_compress 硬件加速

#### 延迟加载
- 图片按需加载
- 使用 CachedNetworkImage（如需要）

### 4. UI 优化

#### ListView 优化
- 使用 ListView.builder 按需构建
- 自动回收不可见项
- 避免一次性加载所有笔记

#### 状态管理优化
- 使用 Riverpod 细粒度更新
- 避免不必要的 rebuild
- StreamProvider 自动管理订阅

#### 动画优化
- 使用 Material 默认动画
- 避免复杂的自定义动画

### 5. 内存优化

#### 数据库连接
- 单例模式管理数据库连接
- 避免重复打开数据库

#### 图片内存
- 压缩后再加载到内存
- 及时释放不用的图片

#### 流订阅
- 使用 Riverpod 自动管理订阅
- 页面销毁时自动取消订阅

## 进一步优化建议

### 1. 数据库优化

```dart
// 批量插入优化
Future<void> batchInsertNotes(List<Note> notes) async {
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final note in notes) {
      batch.insert('notes', note.toMap());
    }
    await batch.commit(noResult: true);
  });
}

// 分页查询
Future<List<Note>> getNotesPage(int page, int pageSize) async {
  return await db.query(
    'notes',
    limit: pageSize,
    offset: page * pageSize,
    orderBy: 'updated_at DESC',
  );
}
```

### 2. 图片缓存

```dart
// 使用 cached_network_image
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 1920,
  memCacheHeight: 1920,
)
```

### 3. 懒加载

```dart
// 使用 lazy_load_scrollview
LazyLoadScrollView(
  onEndOfPage: () => _loadMoreNotes(),
  child: ListView.builder(...),
)
```

### 4. 后台任务优化

```dart
// 使用 Isolate 处理耗时操作
Future<String> compressImageInIsolate(String path) async {
  return await compute(_compressImage, path);
}

String _compressImage(String path) {
  // 压缩逻辑
}
```

### 5. 缓存策略

```dart
// 内存缓存
class NoteCache {
  final _cache = <String, Note>{};
  final _maxSize = 100;

  Note? get(String id) => _cache[id];

  void put(String id, Note note) {
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[id] = note;
  }
}
```

## 性能监控

### 1. 使用 Flutter DevTools
```bash
flutter run --profile
# 打开 DevTools 查看性能
```

### 2. 性能指标
- 启动时间 < 2 秒
- 列表滚动 60 FPS
- 搜索响应 < 300ms
- 同步延迟 < 1 秒

### 3. 内存监控
```dart
// 监控内存使用
import 'dart:developer' as developer;

void logMemoryUsage() {
  developer.Timeline.instantSync('Memory', arguments: {
    'rss': ProcessInfo.currentRss,
    'heap': ProcessInfo.maxRss,
  });
}
```

## 电池优化

### 1. 后台同步限制
- 使用 WorkManager 定期同步（5 分钟）
- 仅在网络连接时同步
- 避免频繁唤醒

### 2. 位置服务
- 不使用位置服务（节省电量）

### 3. 传感器
- 不使用传感器（节省电量）

## 构建优化

### 1. 代码混淆
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### 2. 减小包体积
```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  # 只包含需要的字体
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
```

### 3. 分包
```bash
flutter build apk --release --split-per-abi
```

## 测试性能

```bash
# 性能测试
flutter drive --target=test_driver/perf_test.dart --profile

# 内存泄漏检测
flutter run --profile --trace-skia
```
