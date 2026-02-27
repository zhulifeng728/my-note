import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/folders_table.dart';

part 'folders_dao.g.dart';

@DriftAccessor(tables: [Folders])
class FoldersDao extends DatabaseAccessor<AppDatabase> with _$FoldersDaoMixin {
  FoldersDao(AppDatabase db) : super(db);

  // 获取所有文件夹
  Future<List<Folder>> getAllFolders() {
    return (select(folders)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  // 根据 ID 获取文件夹
  Future<Folder?> getFolderById(String id) {
    return (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // 创建文件夹
  Future<Folder> createFolder({
    required String id,
    required String name,
    String? parentId,
    String? icon,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final folder = FoldersCompanion.insert(
      id: id,
      name: name,
      parentId: Value(parentId),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
    await into(folders).insert(folder);
    return (await getFolderById(id))!;
  }

  // 更新文件夹
  Future<void> updateFolder({
    required String id,
    String? name,
    String? icon,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        icon: icon != null ? Value(icon) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  // 删除文件夹
  Future<void> deleteFolder(String id) async {
    await (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  // 移动文件夹
  Future<void> moveFolder(String folderId, String? newParentId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(folders)..where((t) => t.id.equals(folderId))).write(
      FoldersCompanion(
        parentId: Value(newParentId),
        updatedAt: Value(now),
      ),
    );
  }

  // 获取子文件夹
  Future<List<Folder>> getChildFolders(String? parentId) {
    if (parentId == null) {
      return (select(folders)
            ..where((t) => t.parentId.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
    }
    return (select(folders)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }
}
