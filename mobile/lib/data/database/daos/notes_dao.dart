import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(AppDatabase db) : super(db);

  // 获取所有笔记（不含已删除）
  Future<List<Note>> getAllNotes() {
    return (select(notes)
          ..where((t) => t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // 根据 ID 获取笔记
  Future<Note?> getNoteById(String id) {
    return (select(notes)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(0)))
        .getSingleOrNull();
  }

  // 创建笔记
  Future<Note> createNote({
    required String id,
    required String title,
    required String content,
    String folderId = 'all',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = NotesCompanion.insert(
      id: id,
      title: Value(title),
      content: Value(content),
      folderId: Value(folderId),
      createdAt: now,
      updatedAt: now,
    );
    await into(notes).insert(note);
    return (await getNoteById(id))!;
  }

  // 更新笔记
  Future<Note> updateNote({
    required String id,
    String? title,
    String? content,
  }) async {
    final existing = await getNoteById(id);
    if (existing == null) throw Exception('Note not found: $id');

    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: title != null ? Value(title) : Value(existing.title),
        content: content != null ? Value(content) : Value(existing.content),
        updatedAt: Value(now),
      ),
    );
    return (await getNoteById(id))!;
  }

  // 软删除笔记
  Future<void> deleteNote(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(1),
        updatedAt: Value(now),
      ),
    );
  }

  // 移动笔记到文件夹
  Future<void> moveNoteToFolder(String noteId, String folderId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(notes)..where((t) => t.id.equals(noteId))).write(
      NotesCompanion(
        folderId: Value(folderId),
        updatedAt: Value(now),
      ),
    );
  }

  // 根据文件夹获取笔记
  Future<List<Note>> getNotesByFolder(String folderId) {
    if (folderId == 'all') {
      return getAllNotes();
    }
    return (select(notes)
          ..where((t) => t.folderId.equals(folderId) & t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // 全文搜索
  Future<List<Note>> searchNotes(String keyword) async {
    if (keyword.trim().isEmpty) return getAllNotes();

    final result = await customSelect(
      '''
      SELECT n.*
      FROM notes n
      JOIN notes_fts f ON n.id = f.id
      WHERE notes_fts MATCH ?
        AND n.is_deleted = 0
      ORDER BY n.updated_at DESC
      ''',
      variables: [Variable.withString('$keyword*')],
      readsFrom: {notes},
    ).get();

    return result.map((row) => notes.map(row.data)).toList();
  }

  // ===== 同步专用方法 =====

  // 获取所有笔记（含已删除）
  Future<List<Note>> getAllNotesForSync() {
    return (select(notes)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // 获取指定时间戳之后的笔记
  Future<List<Note>> getNotesSince(int timestamp) {
    return (select(notes)
          ..where((t) => t.updatedAt.isBiggerThanValue(timestamp))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
  }

  // 从同步端写入笔记
  Future<Note?> upsertNoteFromSync(Note remoteNote) async {
    final existing = await (select(notes)
          ..where((t) => t.id.equals(remoteNote.id)))
        .getSingleOrNull();

    if (existing == null) {
      // 新笔记，直接插入
      await into(notes).insert(remoteNote);
      return remoteNote;
    }

    if (remoteNote.updatedAt > existing.updatedAt) {
      // 远端更新，覆盖
      await (update(notes)..where((t) => t.id.equals(remoteNote.id)))
          .write(remoteNote);
      return remoteNote;
    }

    // 本地更新，跳过
    return null;
  }
}
