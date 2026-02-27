import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/notes_dao.dart';
import '../../data/database/daos/folders_dao.dart';
import '../../data/database/daos/devices_dao.dart';
import '../../data/database/daos/sync_log_dao.dart';

// 数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Notes DAO Provider
final notesDaoProvider = Provider<NotesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return NotesDao(db);
});

// Folders DAO Provider
final foldersDaoProvider = Provider<FoldersDao>((ref) {
  final db = ref.watch(databaseProvider);
  return FoldersDao(db);
});

// Devices DAO Provider
final devicesDaoProvider = Provider<DevicesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return DevicesDao(db);
});

// Sync Logs DAO Provider
final syncLogsDaoProvider = Provider<SyncLogsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncLogsDao(db);
});
