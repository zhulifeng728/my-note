import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_providers.dart';

// 所有文件夹列表 Provider
final foldersProvider = StreamProvider<List<Folder>>((ref) {
  final dao = ref.watch(foldersDaoProvider);
  return dao.getAllFolders().asStream();
});

// 子文件夹 Provider
final childFoldersProvider = StreamProvider.family<List<Folder>, String?>((ref, parentId) {
  final dao = ref.watch(foldersDaoProvider);
  return dao.getChildFolders(parentId).asStream();
});

// 单个文件夹 Provider
final folderProvider = StreamProvider.family<Folder?, String>((ref, folderId) {
  final dao = ref.watch(foldersDaoProvider);
  return dao.getFolderById(folderId).asStream();
});

// 当前选中的文件夹 ID Provider
final selectedFolderIdProvider = StateProvider<String>((ref) => 'all');

// 文件夹树结构 Provider
final folderTreeProvider = FutureProvider<List<FolderNode>>((ref) async {
  final folders = await ref.watch(foldersProvider.future);
  return _buildFolderTree(folders, null);
});

// 文件夹树节点
class FolderNode {
  final Folder folder;
  final List<FolderNode> children;

  FolderNode({
    required this.folder,
    required this.children,
  });
}

// 构建文件夹树
List<FolderNode> _buildFolderTree(List<Folder> folders, String? parentId) {
  final children = folders.where((f) => f.parentId == parentId).toList();
  return children.map((folder) {
    return FolderNode(
      folder: folder,
      children: _buildFolderTree(folders, folder.id),
    );
  }).toList();
}
