import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/folders_repository.dart';
import 'database_providers.dart';

// Notes Repository Provider
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final dao = ref.watch(notesDaoProvider);
  return NotesRepository(dao);
});

// Folders Repository Provider
final foldersRepositoryProvider = Provider<FoldersRepository>((ref) {
  final dao = ref.watch(foldersDaoProvider);
  return FoldersRepository(dao);
});
