import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_service.dart';
import 'websocket_service.dart';
import 'pairing_service.dart';

class AutoSyncManager {
  final SyncService _syncService;
  final WebSocketService _webSocketService;
  final PairingService _pairingService;
  final Connectivity _connectivity = Connectivity();

  Timer? _debounceTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = false;
  bool _isSyncing = false;

  // 回调函数
  Function(bool)? onSyncStatusChanged;
  Function(String)? onError;

  AutoSyncManager(
    this._syncService,
    this._webSocketService,
    this._pairingService,
  );

  /// 初始化自动同步
  Future<void> initialize() async {
    // 检查是否已配对
    final isPaired = await _pairingService.isPaired();
    if (!isPaired) {
      return;
    }

    // 检查网络状态
    await _checkConnectivity();

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // 如果在线，执行初始同步
    if (_isOnline) {
      await _performInitialSync();
    }
  }

  /// 检查网络连接
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  /// 网络状态变化处理
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (!wasOnline && _isOnline) {
      // 从离线变为在线，执行同步
      _performSync();
    } else if (wasOnline && !_isOnline) {
      // 从在线变为离线，断开 WebSocket
      _webSocketService.disconnect();
    }
  }

  /// 执行初始同步
  Future<void> _performInitialSync() async {
    try {
      onSyncStatusChanged?.call(true);
      _isSyncing = true;

      // 1. 执行完整同步
      await _syncService.fullSync();

      // 2. 连接 WebSocket
      await _webSocketService.connect();

      onSyncStatusChanged?.call(false);
      _isSyncing = false;
    } catch (e) {
      onError?.call('初始同步失败: $e');
      onSyncStatusChanged?.call(false);
      _isSyncing = false;
    }
  }

  /// 执行同步
  Future<void> _performSync() async {
    if (_isSyncing || !_isOnline) return;

    try {
      onSyncStatusChanged?.call(true);
      _isSyncing = true;

      // 获取最后同步时间
      final status = await _syncService.getSyncStatus();
      final lastSyncTime = status['lastSyncTime'] as int?;

      if (lastSyncTime == null) {
        // 首次同步，执行完整同步
        await _syncService.fullSync();
      } else {
        // 增量同步
        await _syncService.incrementalSync(lastSyncTime);
      }

      // 推送本地修改
      await _syncService.pushAllChanges();

      // 确保 WebSocket 已连接
      if (!_webSocketService.isConnected) {
        await _webSocketService.connect();
      }

      onSyncStatusChanged?.call(false);
      _isSyncing = false;
    } catch (e) {
      onError?.call('同步失败: $e');
      onSyncStatusChanged?.call(false);
      _isSyncing = false;
    }
  }

  /// 触发本地修改后的同步（防抖 2 秒）
  void triggerSyncAfterLocalChange() {
    if (!_isOnline) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _performSync();
    });
  }

  /// 手动触发同步
  Future<void> manualSync() async {
    _debounceTimer?.cancel();
    await _performSync();
  }

  /// 停止自动同步
  Future<void> stop() async {
    _debounceTimer?.cancel();
    await _connectivitySubscription?.cancel();
    await _webSocketService.disconnect();
  }

  /// 清理资源
  void dispose() {
    stop();
  }
}
