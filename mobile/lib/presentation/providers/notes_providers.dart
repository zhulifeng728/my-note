import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import 'database_providers.dart';

// 所有笔记列表 Provider
final notesProvider = StreamProvider<List<Note>>((ref) {
  final dao = ref.watch(notesDaoProvider);
  return dao.getAllNotes().asStream();
});

// 根据文件夹获取笔记 Provider
final notesByFolderProvider = StreamProvider.family<List<Note>, String>((ref, folderId) {
  final dao = ref.watch(notesDaoProvider);
  return dao.getNotesByFolder(folderId).asStream();
});

// 单个笔记 Provider
final noteProvider = StreamProvider.family<Note?, String>((ref, noteId) {
  final dao = ref.watch(notesDaoProvider);
  return dao.getNoteById(noteId).asStream();
});

// 搜索笔记 Provider
final searchNotesProvider = StreamProvider.family<List<Note>, String>((ref, keyword) {
  final dao = ref.watch(notesDaoProvider);
  return dao.searchNotes(keyword).asStream();
});

// 当前选中的笔记 ID Provider
final selectedNoteIdProvider = StateProvider<String?>((ref) => null);

// 当前编辑的笔记内容 Provider
final editingNoteProvider = StateProvider<Note?>((ref) => null);
