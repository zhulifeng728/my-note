import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_status_model.dart';
import '../../data/models/conflict_model.dart';

// 同步状态 Provider
final syncStatusProvider = StateProvider<SyncStatusModel>((ref) {
  return SyncStatusModel(
    connection: SyncConnectionStatus.waiting,
    pendingCount: 0,
    lastSyncAt: null,
    connectedDevice: null,
  );
});

// 是否正在同步 Provider
final isSyncingProvider = StateProvider<bool>((ref) => false);

// 待处理冲突列表 Provider
final pendingConflictsProvider = StateProvider<List<ConflictInfoModel>>((ref) => []);

// WebSocket 连接状态 Provider
final wsConnectedProvider = StateProvider<bool>((ref) => false);

// 最后同步错误 Provider
final lastSyncErrorProvider = StateProvider<String?>((ref) => null);
