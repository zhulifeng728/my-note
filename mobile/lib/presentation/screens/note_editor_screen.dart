import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/content_converter.dart';
import '../../data/database/app_database.dart';
import '../providers/repository_providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late quill.QuillController _controller;
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = true;
  Note? _currentNote;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final repository = ref.read(notesRepositoryProvider);
      final note = await repository.getNoteById(widget.noteId!);

      if (note != null) {
        _currentNote = note;
        _titleController.text = note.title;

        // 转换 Tiptap JSON 到 Quill Delta
        final delta = ContentConverter.tiptapToQuill(note.content);
        _controller = quill.QuillController(
          document: quill.Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );

        setState(() {
          _isLoading = false;
        });

        // 监听内容变化，自动保存
        _controller.addListener(_onContentChanged);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _controller.addListener(_onContentChanged);
    }
  }

  void _onContentChanged() {
    // 防抖保存（500ms）
    Future.delayed(const Duration(milliseconds: 500), () {
      _saveNote();
    });
  }

  Future<void> _saveNote() async {
    final repository = ref.read(notesRepositoryProvider);
    final title = _titleController.text.trim();
    final delta = _controller.document.toDelta();
    final content = ContentConverter.quillToTiptap(delta);

    try {
      if (_currentNote == null) {
        // 创建新笔记
        final note = await repository.createNote(
          title: title.isEmpty ? '无标题' : title,
          content: content,
        );
        setState(() {
          _currentNote = note;
        });
      } else {
        // 更新现有笔记
        await repository.updateNote(
          id: _currentNote!.id,
          title: title.isEmpty ? '无标题' : title,
          content: content,
        );
      }
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑笔记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveNote();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题输入框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),

          // 工具栏
          quill.QuillSimpleToolbar(
            controller: _controller,
            config: const quill.QuillSimpleToolbarConfig(
              showAlignmentButtons: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showCodeBlock: true,
              showListBullets: true,
              showListNumbers: true,
              showListCheck: true,
              showQuote: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
            ),
          ),
          const Divider(height: 1),

          // 编辑器
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: quill.QuillEditor(
                controller: _controller,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
