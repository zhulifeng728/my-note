import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_log_table.dart';

part 'sync_log_dao.g.dart';

@DriftAccessor(tables: [SyncLogs])
class SyncLogsDao extends DatabaseAccessor<AppDatabase>
    with _$SyncLogsDaoMixin {
  SyncLogsDao(AppDatabase db) : super(db);

  // 添加同步日志
  Future<void> addSyncLog({
    required String id,
    required String noteId,
    required String deviceId,
    String status = 'success',
    String? conflictData,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(syncLogs).insert(
      SyncLogsCompanion.insert(
        id: id,
        noteId: noteId,
        deviceId: deviceId,
        syncedAt: now,
        status: Value(status),
        conflictData: Value(conflictData),
      ),
    );
  }

  // 获取待处理的同步数量
  Future<int> getPendingCount() async {
    final result = await (selectOnly(syncLogs)
          ..addColumns([syncLogs.id.count()])
          ..where(syncLogs.status.equals('pending')))
        .getSingle();
    return result.read(syncLogs.id.count()) ?? 0;
  }

  // 获取最后成功同步时间
  Future<int?> getLastSyncTime() async {
    final result = await (selectOnly(syncLogs)
          ..addColumns([syncLogs.syncedAt.max()])
          ..where(syncLogs.status.equals('success')))
        .getSingleOrNull();
    return result?.read(syncLogs.syncedAt.max());
  }

  // 清理旧日志（保留最近 1000 条）
  Future<void> cleanOldLogs() async {
    await customStatement('''
      DELETE FROM sync_logs
      WHERE id NOT IN (
        SELECT id FROM sync_logs
        ORDER BY synced_at DESC
        LIMIT 1000
      )
    ''');
  }
}
