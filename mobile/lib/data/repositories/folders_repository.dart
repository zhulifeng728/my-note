import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/folders_dao.dart';

class FoldersRepository {
  final FoldersDao _foldersDao;
  final _uuid = const Uuid();

  FoldersRepository(this._foldersDao);

  // 获取所有文件夹
  Future<List<Folder>> getAllFolders() {
    return _foldersDao.getAllFolders();
  }

  // 根据 ID 获取文件夹
  Future<Folder?> getFolderById(String id) {
    return _foldersDao.getFolderById(id);
  }

  // 创建文件夹
  Future<Folder> createFolder({
    required String name,
    String? parentId,
    String? icon,
    int sortOrder = 0,
  }) {
    return _foldersDao.createFolder(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      icon: icon,
      sortOrder: sortOrder,
    );
  }

  // 更新文件夹
  Future<void> updateFolder({
    required String id,
    String? name,
    String? icon,
  }) {
    return _foldersDao.updateFolder(
      id: id,
      name: name,
      icon: icon,
    );
  }

  // 删除文件夹
  Future<void> deleteFolder(String id) {
    return _foldersDao.deleteFolder(id);
  }

  // 移动文件夹
  Future<void> moveFolder(String folderId, String? newParentId) {
    return _foldersDao.moveFolder(folderId, newParentId);
  }

  // 获取子文件夹
  Future<List<Folder>> getChildFolders(String? parentId) {
    return _foldersDao.getChildFolders(parentId);
  }

  // 构建文件夹树
  Future<List<FolderTreeNode>> buildFolderTree() async {
    final folders = await getAllFolders();
    return _buildTree(folders, null);
  }

  List<FolderTreeNode> _buildTree(List<Folder> folders, String? parentId) {
    final children = folders.where((f) => f.parentId == parentId).toList();
    return children.map((folder) {
      return FolderTreeNode(
        folder: folder,
        children: _buildTree(folders, folder.id),
      );
    }).toList();
  }

  // 获取所有子文件夹 ID（递归）
  Future<List<String>> getDescendantFolderIds(String folderId) async {
    final folders = await getAllFolders();
    final result = <String>[];
    _collectDescendants(folders, folderId, result);
    return result;
  }

  void _collectDescendants(
    List<Folder> folders,
    String parentId,
    List<String> result,
  ) {
    final children = folders.where((f) => f.parentId == parentId);
    for (final child in children) {
      result.add(child.id);
      _collectDescendants(folders, child.id, result);
    }
  }
}

class FolderTreeNode {
  final Folder folder;
  final List<FolderTreeNode> children;

  FolderTreeNode({
    required this.folder,
    required this.children,
  });
}
