import 'package:dio/dio.dart';
import '../models/note_model.dart';
import '../database/daos/notes_dao.dart';
import '../database/daos/sync_log_dao.dart';
import 'pairing_service.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  final Dio _dio;
  final NotesDao _notesDao;
  final SyncLogsDao _syncLogsDao;
  final PairingService _pairingService;
  final _uuid = const Uuid();

  SyncService(
    this._dio,
    this._notesDao,
    this._syncLogsDao,
    this._pairingService,
  );

  /// 完整同步（获取所有笔记）
  Future<void> fullSync() async {
    final serverUrl = await _pairingService.getServerUrl();
    final token = await _pairingService.getToken();
    final deviceId = await _pairingService.getDeviceId();

    if (serverUrl == null || token == null || deviceId == null) {
      throw Exception('未配对设备');
    }

    try {
      final response = await _dio.get(
        '$serverUrl/api/notes',
        options: Options(
          headers: {'x-device-token': token},
        ),
      );

      final notes = (response.data as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();

      // 写入本地数据库
      for (final noteModel in notes) {
        final note = await _notesDao.getNoteById(noteModel.id);
        if (note == null) {
          // 新笔记，插入
          await _notesDao.createNote(
            id: noteModel.id,
            title: noteModel.title,
            content: noteModel.content,
            folderId: noteModel.folderId,
          );
        } else if (noteModel.updatedAt > note.updatedAt) {
          // 远端更新，覆盖
          await _notesDao.updateNote(
            id: noteModel.id,
            title: noteModel.title,
            content: noteModel.content,
          );
        }

        // 记录同步日志
        await _syncLogsDao.addSyncLog(
          id: _uuid.v4(),
          noteId: noteModel.id,
          deviceId: deviceId,
          status: 'success',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('认证失败，请重新配对');
      }
      throw Exception('同步失败: ${e.message}');
    }
  }

  /// 增量同步（获取指定时间戳之后的笔记）
  Future<void> incrementalSync(int sinceTimestamp) async {
    final serverUrl = await _pairingService.getServerUrl();
    final token = await _pairingService.getToken();
    final deviceId = await _pairingService.getDeviceId();

    if (serverUrl == null || token == null || deviceId == null) {
      throw Exception('未配对设备');
    }

    try {
      final response = await _dio.get(
        '$serverUrl/api/notes/since/$sinceTimestamp',
        options: Options(
          headers: {'x-device-token': token},
        ),
      );

      final notes = (response.data as List)
          .map((json) => NoteModel.fromJson(json))
          .toList();

      // 写入本地数据库
      for (final noteModel in notes) {
        await _notesDao.upsertNoteFromSync(
          await _convertToNote(noteModel),
        );

        // 记录同步日志
        await _syncLogsDao.addSyncLog(
          id: _uuid.v4(),
          noteId: noteModel.id,
          deviceId: deviceId,
          status: 'success',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('认证失败，请重新配对');
      }
      throw Exception('增量同步失败: ${e.message}');
    }
  }

  /// 推送单条笔记到服务器
  Future<void> pushNote(String noteId) async {
    final serverUrl = await _pairingService.getServerUrl();
    final token = await _pairingService.getToken();
    final deviceId = await _pairingService.getDeviceId();

    if (serverUrl == null || token == null || deviceId == null) {
      throw Exception('未配对设备');
    }

    final note = await _notesDao.getNoteById(noteId);
    if (note == null) {
      throw Exception('笔记不存在');
    }

    try {
      final response = await _dio.post(
        '$serverUrl/api/notes/sync',
        data: {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'folder_id': note.folderId,
          'created_at': note.createdAt,
          'updated_at': note.updatedAt,
          'is_deleted': note.isDeleted,
        },
        options: Options(
          headers: {'x-device-token': token},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 409) {
        // 冲突，需要处理
        throw ConflictException(noteId);
      }

      // 记录同步日志
      await _syncLogsDao.addSyncLog(
        id: _uuid.v4(),
        noteId: noteId,
        deviceId: deviceId,
        status: 'success',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('认证失败，请重新配对');
      }
      throw Exception('推送失败: ${e.message}');
    }
  }

  /// 推送所有本地修改的笔记
  Future<void> pushAllChanges() async {
    final lastSyncTime = await _syncLogsDao.getLastSyncTime();
    final changedNotes = await _notesDao.getNotesSince(lastSyncTime ?? 0);

    for (final note in changedNotes) {
      try {
        await pushNote(note.id);
      } catch (e) {
        if (e is ConflictException) {
          // 冲突，跳过，等待用户处理
          continue;
        }
        rethrow;
      }
    }
  }

  /// 获取同步状态
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingCount = await _syncLogsDao.getPendingCount();
    final lastSyncTime = await _syncLogsDao.getLastSyncTime();

    return {
      'pendingCount': pendingCount,
      'lastSyncTime': lastSyncTime,
    };
  }

  Future<dynamic> _convertToNote(NoteModel model) async {
    // 这里需要转换 NoteModel 到 Drift Note 对象
    // 由于 Drift 生成的类型，我们直接使用 DAO 方法
    final existing = await _notesDao.getNoteById(model.id);
    if (existing == null) {
      return await _notesDao.createNote(
        id: model.id,
        title: model.title,
        content: model.content,
        folderId: model.folderId,
      );
    } else {
      return existing;
    }
  }
}

class ConflictException implements Exception {
  final String noteId;
  ConflictException(this.noteId);

  @override
  String toString() => 'ConflictException: Note $noteId has conflict';
}
