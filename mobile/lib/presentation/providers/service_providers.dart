import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/pairing_service.dart';
import '../../data/services/websocket_service.dart';
import '../../data/services/auto_sync_manager.dart';
import 'database_providers.dart';

// Dio Provider
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

// Pairing Service Provider
final pairingServiceProvider = Provider<PairingService>((ref) {
  final dio = ref.watch(dioProvider);
  final devicesDao = ref.watch(devicesDaoProvider);
  return PairingService(dio, devicesDao);
});

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final dio = ref.watch(dioProvider);
  final notesDao = ref.watch(notesDaoProvider);
  final syncLogsDao = ref.watch(syncLogsDaoProvider);
  final pairingService = ref.watch(pairingServiceProvider);
  return SyncService(dio, notesDao, syncLogsDao, pairingService);
});

// WebSocket Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final notesDao = ref.watch(notesDaoProvider);
  final pairingService = ref.watch(pairingServiceProvider);
  return WebSocketService(notesDao, pairingService);
});

// Auto Sync Manager Provider
final autoSyncManagerProvider = Provider<AutoSyncManager>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  final pairingService = ref.watch(pairingServiceProvider);
  return AutoSyncManager(syncService, webSocketService, pairingService);
});
