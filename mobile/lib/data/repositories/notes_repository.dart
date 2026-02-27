import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/notes_dao.dart';

class NotesRepository {
  final NotesDao _notesDao;
  final _uuid = const Uuid();

  NotesRepository(this._notesDao);

  // 获取所有笔记
  Future<List<Note>> getAllNotes() {
    return _notesDao.getAllNotes();
  }

  // 根据 ID 获取笔记
  Future<Note?> getNoteById(String id) {
    return _notesDao.getNoteById(id);
  }

  // 创建笔记
  Future<Note> createNote({
    required String title,
    required String content,
    String folderId = 'all',
  }) {
    return _notesDao.createNote(
      id: _uuid.v4(),
      title: title,
      content: content,
      folderId: folderId,
    );
  }

  // 更新笔记
  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
  }) {
    return _notesDao.updateNote(
      id: id,
      title: title,
      content: content,
    );
  }

  // 删除笔记（软删除）
  Future<void> deleteNote(String id) {
    return _notesDao.deleteNote(id);
  }

  // 移动笔记到文件夹
  Future<void> moveNoteToFolder(String noteId, String folderId) {
    return _notesDao.moveNoteToFolder(noteId, folderId);
  }

  // 根据文件夹获取笔记
  Future<List<Note>> getNotesByFolder(String folderId) {
    return _notesDao.getNotesByFolder(folderId);
  }

  // 搜索笔记
  Future<List<Note>> searchNotes(String keyword) {
    return _notesDao.searchNotes(keyword);
  }

  // ===== 同步专用方法 =====

  // 获取所有笔记（含已删除）
  Future<List<Note>> getAllNotesForSync() {
    return _notesDao.getAllNotesForSync();
  }

  // 获取指定时间戳之后的笔记
  Future<List<Note>> getNotesSince(int timestamp) {
    return _notesDao.getNotesSince(timestamp);
  }

  // 从同步端写入笔记
  Future<Note?> upsertNoteFromSync(Note remoteNote) {
    return _notesDao.upsertNoteFromSync(remoteNote);
  }
}
