import 'package:uuid/uuid.dart';
import '../database/daos/notes_dao.dart';
import '../models/conflict_model.dart';
import '../models/note_model.dart';

class ConflictResolver {
  final NotesDao _notesDao;
  final _uuid = const Uuid();

  ConflictResolver(this._notesDao);

  /// 解决冲突
  Future<void> resolveConflict(
    ConflictInfoModel conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.local:
        await _keepLocal(conflict);
        break;
      case ConflictResolution.remote:
        await _keepRemote(conflict);
        break;
      case ConflictResolution.both:
        await _keepBoth(conflict);
        break;
    }
  }

  /// 保留本地版本
  Future<void> _keepLocal(ConflictInfoModel conflict) async {
    // 本地版本已经存在，不需要做任何操作
    // 只需要更新时间戳，确保下次同步时本地版本会覆盖远程
    await _notesDao.updateNote(
      id: conflict.local.id,
      title: conflict.local.title,
      content: conflict.local.content,
    );
  }

  /// 保留远程版本
  Future<void> _keepRemote(ConflictInfoModel conflict) async {
    // 用远程版本覆盖本地，并更新时间戳
    await _notesDao.updateNote(
      id: conflict.remote.id,
      title: conflict.remote.title,
      content: conflict.remote.content,
    );
  }

  /// 保留两者
  Future<void> _keepBoth(ConflictInfoModel conflict) async {
    // 保留本地版本不变
    // 将远程版本创建为新笔记（添加"冲突副本"标记）
    await _notesDao.createNote(
      id: _uuid.v4(),
      title: '${conflict.remote.title} (冲突副本)',
      content: conflict.remote.content,
      folderId: conflict.remote.folderId,
    );
  }

  /// 检测是否存在冲突
  bool detectConflict(NoteModel local, NoteModel remote) {
    // 冲突条件：
    // 1. 两端都修改了（时间戳不同）
    // 2. 修改时间在 5 秒内
    // 3. 内容不同
    if (local.updatedAt == remote.updatedAt) {
      return false;
    }

    final timeDiff = (local.updatedAt - remote.updatedAt).abs();
    if (timeDiff >= 5000) {
      return false;
    }

    if (local.content == remote.content) {
      return false;
    }

    return true;
  }

  /// 创建冲突信息
  ConflictInfoModel createConflictInfo(NoteModel local, NoteModel remote) {
    return ConflictInfoModel(
      noteId: local.id,
      local: local,
      remote: remote,
    );
  }
}
