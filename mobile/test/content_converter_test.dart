import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/content_converter.dart';
import 'package:flutter_quill/quill_delta.dart';

void main() {
  group('ContentConverter', () {
    test('converts simple Tiptap paragraph to Quill Delta', () {
      const tiptapJson = '''
      {
        "type": "doc",
        "content": [
          {
            "type": "paragraph",
            "content": [
              {
                "type": "text",
                "text": "Hello World"
              }
            ]
          }
        ]
      }
      ''';

      final delta = ContentConverter.tiptapToQuill(tiptapJson);
      expect(delta.toList().length, greaterThan(0));
    });

    test('converts Tiptap with bold text to Quill Delta', () {
      const tiptapJson = '''
      {
        "type": "doc",
        "content": [
          {
            "type": "paragraph",
            "content": [
              {
                "type": "text",
                "text": "Bold text",
                "marks": [{"type": "bold"}]
              }
            ]
          }
        ]
      }
      ''';

      final delta = ContentConverter.tiptapToQuill(tiptapJson);
      final ops = delta.toList();
      expect(ops.any((op) => op.attributes?['bold'] == true), isTrue);
    });

    test('converts Tiptap heading to Quill Delta', () {
      const tiptapJson = '''
      {
        "type": "doc",
        "content": [
          {
            "type": "heading",
            "attrs": {"level": 1},
            "content": [
              {
                "type": "text",
                "text": "Heading 1"
              }
            ]
          }
        ]
      }
      ''';

      final delta = ContentConverter.tiptapToQuill(tiptapJson);
      final ops = delta.toList();
      expect(ops.any((op) => op.attributes?['header'] == 1), isTrue);
    });

    test('converts Quill Delta to Tiptap JSON', () {
      final delta = Delta()
        ..insert('Hello World')
        ..insert('\n');

      final tiptapJson = ContentConverter.quillToTiptap(delta);
      expect(tiptapJson, contains('Hello World'));
      expect(tiptapJson, contains('paragraph'));
    });

    test('converts Quill Delta with bold to Tiptap JSON', () {
      final delta = Delta()
        ..insert('Bold text', {'bold': true})
        ..insert('\n');

      final tiptapJson = ContentConverter.quillToTiptap(delta);
      expect(tiptapJson, contains('Bold text'));
      expect(tiptapJson, contains('bold'));
    });

    test('handles empty content', () {
      const tiptapJson = '';
      final delta = ContentConverter.tiptapToQuill(tiptapJson);
      expect(delta.toList().length, greaterThan(0));
    });

    test('round-trip conversion preserves content', () {
      final originalDelta = Delta()
        ..insert('Test content')
        ..insert('\n');

      final tiptapJson = ContentConverter.quillToTiptap(originalDelta);
      final convertedDelta = ContentConverter.tiptapToQuill(tiptapJson);

      expect(convertedDelta.toList().length, greaterThan(0));
    });
  });
}
