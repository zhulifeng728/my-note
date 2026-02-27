import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/services/conflict_resolver.dart';
import 'package:mobile/data/models/note_model.dart';

void main() {
  group('ConflictResolver', () {
    test('detects conflict when both sides modified within 5 seconds', () {
      final resolver = ConflictResolver(null as dynamic);

      final local = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Local content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final remote = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Remote content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1002000, // 1 second difference
        isDeleted: 0,
      );

      expect(resolver.detectConflict(local, remote), isTrue);
    });

    test('does not detect conflict when time difference is large', () {
      final resolver = ConflictResolver(null as dynamic);

      final local = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Local content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final remote = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Remote content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1010000, // 9 seconds difference
        isDeleted: 0,
      );

      expect(resolver.detectConflict(local, remote), isFalse);
    });

    test('does not detect conflict when content is same', () {
      final resolver = ConflictResolver(null as dynamic);

      final local = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Same content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final remote = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Same content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1002000,
        isDeleted: 0,
      );

      expect(resolver.detectConflict(local, remote), isFalse);
    });

    test('creates conflict info correctly', () {
      final resolver = ConflictResolver(null as dynamic);

      final local = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Local content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final remote = NoteModel(
        id: '1',
        title: 'Test',
        content: 'Remote content',
        folderId: 'all',
        createdAt: 1000000,
        updatedAt: 1002000,
        isDeleted: 0,
      );

      final conflict = resolver.createConflictInfo(local, remote);

      expect(conflict.noteId, equals('1'));
      expect(conflict.local.content, equals('Local content'));
      expect(conflict.remote.content, equals('Remote content'));
    });
  });
}
