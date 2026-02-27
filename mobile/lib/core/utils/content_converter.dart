import 'dart:convert';
import 'package:flutter_quill/quill_delta.dart';

/// Tiptap JSON 和 Quill Delta 双向转换器
class ContentConverter {
  /// Tiptap JSON 转 Quill Delta
  static Delta tiptapToQuill(String tiptapJson) {
    if (tiptapJson.isEmpty) {
      return Delta()..insert('\n');
    }

    try {
      final doc = jsonDecode(tiptapJson) as Map<String, dynamic>;
      final content = doc['content'] as List<dynamic>?;

      if (content == null || content.isEmpty) {
        return Delta()..insert('\n');
      }

      final delta = Delta();
      for (final node in content) {
        _convertTiptapNode(node as Map<String, dynamic>, delta);
      }

      return delta;
    } catch (e) {
      // 如果解析失败，返回纯文本
      return Delta()..insert(tiptapJson)..insert('\n');
    }
  }

  static void _convertTiptapNode(Map<String, dynamic> node, Delta delta) {
    final type = node['type'] as String;

    switch (type) {
      case 'paragraph':
        _convertParagraph(node, delta);
        break;
      case 'heading':
        _convertHeading(node, delta);
        break;
      case 'bulletList':
        _convertBulletList(node, delta);
        break;
      case 'orderedList':
        _convertOrderedList(node, delta);
        break;
      case 'taskList':
        _convertTaskList(node, delta);
        break;
      case 'image':
        _convertImage(node, delta);
        break;
      case 'codeBlock':
        _convertCodeBlock(node, delta);
        break;
      case 'blockquote':
        _convertBlockquote(node, delta);
        break;
      default:
        // 未知类型，尝试处理内容
        final content = node['content'] as List<dynamic>?;
        if (content != null) {
          for (final child in content) {
            _convertTiptapNode(child as Map<String, dynamic>, delta);
          }
        }
    }
  }

  static void _convertParagraph(Map<String, dynamic> node, Delta delta) {
    final content = node['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      delta.insert('\n');
      return;
    }

    for (final child in content) {
      _convertInlineContent(child as Map<String, dynamic>, delta);
    }
    delta.insert('\n');
  }

  static void _convertHeading(Map<String, dynamic> node, Delta delta) {
    final level = node['attrs']?['level'] as int? ?? 1;
    final content = node['content'] as List<dynamic>?;

    if (content != null) {
      for (final child in content) {
        _convertInlineContent(child as Map<String, dynamic>, delta);
      }
    }

    delta.insert('\n', {'header': level});
  }

  static void _convertBulletList(Map<String, dynamic> node, Delta delta) {
    final items = node['content'] as List<dynamic>?;
    if (items != null) {
      for (final item in items) {
        _convertListItem(item as Map<String, dynamic>, delta, 'bullet');
      }
    }
  }

  static void _convertOrderedList(Map<String, dynamic> node, Delta delta) {
    final items = node['content'] as List<dynamic>?;
    if (items != null) {
      for (final item in items) {
        _convertListItem(item as Map<String, dynamic>, delta, 'ordered');
      }
    }
  }

  static void _convertTaskList(Map<String, dynamic> node, Delta delta) {
    final items = node['content'] as List<dynamic>?;
    if (items != null) {
      for (final item in items) {
        final checked = item['attrs']?['checked'] as bool? ?? false;
        _convertListItem(item as Map<String, dynamic>, delta, checked ? 'checked' : 'unchecked');
      }
    }
  }

  static void _convertListItem(Map<String, dynamic> item, Delta delta, String listType) {
    final content = item['content'] as List<dynamic>?;
    if (content != null) {
      for (final node in content) {
        final nodeMap = node as Map<String, dynamic>;
        if (nodeMap['type'] == 'paragraph') {
          final paragraphContent = nodeMap['content'] as List<dynamic>?;
          if (paragraphContent != null) {
            for (final child in paragraphContent) {
              _convertInlineContent(child as Map<String, dynamic>, delta);
            }
          }
        }
      }
    }

    delta.insert('\n', {'list': listType});
  }

  static void _convertImage(Map<String, dynamic> node, Delta delta) {
    final src = node['attrs']?['src'] as String?;
    if (src != null) {
      delta.insert({'image': src});
      delta.insert('\n');
    }
  }

  static void _convertCodeBlock(Map<String, dynamic> node, Delta delta) {
    final content = node['content'] as List<dynamic>?;
    if (content != null) {
      for (final child in content) {
        final text = (child as Map<String, dynamic>)['text'] as String?;
        if (text != null) {
          delta.insert(text);
        }
      }
    }
    delta.insert('\n', {'code-block': true});
  }

  static void _convertBlockquote(Map<String, dynamic> node, Delta delta) {
    final content = node['content'] as List<dynamic>?;
    if (content != null) {
      for (final child in content) {
        _convertTiptapNode(child as Map<String, dynamic>, delta);
      }
    }
  }

  static void _convertInlineContent(Map<String, dynamic> node, Delta delta) {
    final type = node['type'] as String?;

    if (type == 'text') {
      final text = node['text'] as String? ?? '';
      final marks = node['marks'] as List<dynamic>?;

      if (marks == null || marks.isEmpty) {
        delta.insert(text);
      } else {
        final attributes = <String, dynamic>{};
        for (final mark in marks) {
          final markMap = mark as Map<String, dynamic>;
          final markType = markMap['type'] as String;

          switch (markType) {
            case 'bold':
              attributes['bold'] = true;
              break;
            case 'italic':
              attributes['italic'] = true;
              break;
            case 'underline':
              attributes['underline'] = true;
              break;
            case 'strike':
              attributes['strike'] = true;
              break;
            case 'code':
              attributes['code'] = true;
              break;
            case 'link':
              attributes['link'] = markMap['attrs']?['href'];
              break;
          }
        }
        delta.insert(text, attributes);
      }
    } else if (type == 'hardBreak') {
      delta.insert('\n');
    }
  }

  /// Quill Delta 转 Tiptap JSON
  static String quillToTiptap(Delta delta) {
    final content = <Map<String, dynamic>>[];
    final ops = delta.toList();

    var currentParagraph = <Map<String, dynamic>>[];

    for (final op in ops) {
      final data = op.data;
      final attrs = op.attributes;

      if (data is String) {
        final lines = data.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];

          if (line.isNotEmpty) {
            currentParagraph.add(_createTextNode(line, attrs));
          }

          // 如果是换行符（除了最后一个字符）
          if (i < lines.length - 1) {
            // 检查是否有块级属性
            if (attrs != null) {
              if (attrs.containsKey('header')) {
                content.add(_createHeading(currentParagraph, attrs['header'] as int));
              } else if (attrs.containsKey('list')) {
                content.add(_createListItem(currentParagraph, attrs['list'] as String));
              } else if (attrs.containsKey('code-block')) {
                content.add(_createCodeBlock(currentParagraph));
              } else {
                content.add(_createParagraph(currentParagraph));
              }
            } else {
              content.add(_createParagraph(currentParagraph));
            }
            currentParagraph = [];
          }
        }
      } else if (data is Map) {
        // 嵌入内容（如图片）
        if (data.containsKey('image')) {
          if (currentParagraph.isNotEmpty) {
            content.add(_createParagraph(currentParagraph));
            currentParagraph = [];
          }
          content.add(_createImage(data['image'] as String));
        }
      }
    }

    // 处理剩余内容
    if (currentParagraph.isNotEmpty) {
      content.add(_createParagraph(currentParagraph));
    }

    // 如果没有内容，添加一个空段落
    if (content.isEmpty) {
      content.add({'type': 'paragraph'});
    }

    return jsonEncode({
      'type': 'doc',
      'content': content,
    });
  }

  static Map<String, dynamic> _createTextNode(String text, Map<String, dynamic>? attrs) {
    final node = <String, dynamic>{'type': 'text', 'text': text};

    if (attrs != null && attrs.isNotEmpty) {
      final marks = <Map<String, dynamic>>[];

      if (attrs['bold'] == true) marks.add({'type': 'bold'});
      if (attrs['italic'] == true) marks.add({'type': 'italic'});
      if (attrs['underline'] == true) marks.add({'type': 'underline'});
      if (attrs['strike'] == true) marks.add({'type': 'strike'});
      if (attrs['code'] == true) marks.add({'type': 'code'});
      if (attrs.containsKey('link')) {
        marks.add({
          'type': 'link',
          'attrs': {'href': attrs['link']}
        });
      }

      if (marks.isNotEmpty) {
        node['marks'] = marks;
      }
    }

    return node;
  }

  static Map<String, dynamic> _createParagraph(List<Map<String, dynamic>> content) {
    return {
      'type': 'paragraph',
      if (content.isNotEmpty) 'content': content,
    };
  }

  static Map<String, dynamic> _createHeading(List<Map<String, dynamic>> content, int level) {
    return {
      'type': 'heading',
      'attrs': {'level': level},
      if (content.isNotEmpty) 'content': content,
    };
  }

  static Map<String, dynamic> _createListItem(List<Map<String, dynamic>> content, String listType) {
    // 这里简化处理，实际应该构建完整的列表结构
    return {
      'type': 'paragraph',
      if (content.isNotEmpty) 'content': content,
    };
  }

  static Map<String, dynamic> _createCodeBlock(List<Map<String, dynamic>> content) {
    return {
      'type': 'codeBlock',
      if (content.isNotEmpty) 'content': content,
    };
  }

  static Map<String, dynamic> _createImage(String src) {
    return {
      'type': 'image',
      'attrs': {'src': src},
    };
  }
}
