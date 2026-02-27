import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/note_model.dart';

void main() {
  group('NoteModel', () {
    test('creates note from JSON', () {
      final json = {
        'id': '1',
        'title': 'Test Note',
        'content': 'Test content',
        'folder_id': 'folder1',
        'created_at': 1000000,
        'updated_at': 1001000,
        'is_deleted': 0,
      };

      final note = NoteModel.fromJson(json);

      expect(note.id, equals('1'));
      expect(note.title, equals('Test Note'));
      expect(note.content, equals('Test content'));
      expect(note.folderId, equals('folder1'));
      expect(note.createdAt, equals(1000000));
      expect(note.updatedAt, equals(1001000));
      expect(note.isDeleted, equals(0));
    });

    test('converts note to JSON', () {
      final note = NoteModel(
        id: '1',
        title: 'Test Note',
        content: 'Test content',
        folderId: 'folder1',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final json = note.toJson();

      expect(json['id'], equals('1'));
      expect(json['title'], equals('Test Note'));
      expect(json['content'], equals('Test content'));
      expect(json['folder_id'], equals('folder1'));
      expect(json['created_at'], equals(1000000));
      expect(json['updated_at'], equals(1001000));
      expect(json['is_deleted'], equals(0));
    });

    test('copyWith creates new instance with updated fields', () {
      final note = NoteModel(
        id: '1',
        title: 'Test Note',
        content: 'Test content',
        folderId: 'folder1',
        createdAt: 1000000,
        updatedAt: 1001000,
        isDeleted: 0,
      );

      final updated = note.copyWith(
        title: 'Updated Title',
        content: 'Updated content',
      );

      expect(updated.id, equals('1'));
      expect(updated.title, equals('Updated Title'));
      expect(updated.content, equals('Updated content'));
      expect(updated.folderId, equals('folder1'));
    });

    test('handles missing folder_id in JSON', () {
      final json = {
        'id': '1',
        'title': 'Test Note',
        'content': 'Test content',
        'created_at': 1000000,
        'updated_at': 1001000,
      };

      final note = NoteModel.fromJson(json);

      expect(note.folderId, equals('all'));
    });
  });
}
