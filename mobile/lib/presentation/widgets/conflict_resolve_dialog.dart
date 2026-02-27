import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/conflict_model.dart';
import '../../data/models/note_model.dart';

class ConflictResolveDialog extends ConsumerStatefulWidget {
  final ConflictInfoModel conflict;

  const ConflictResolveDialog({
    super.key,
    required this.conflict,
  });

  @override
  ConsumerState<ConflictResolveDialog> createState() =>
      _ConflictResolveDialogState();
}

class _ConflictResolveDialogState
    extends ConsumerState<ConflictResolveDialog> {
  ConflictResolution? _selectedResolution;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('同步冲突'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '笔记在本地和远程都被修改了，请选择如何处理：',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildVersionCard(
              '本地版本',
              widget.conflict.local,
              ConflictResolution.local,
            ),
            const SizedBox(height: 12),
            _buildVersionCard(
              '远程版本',
              widget.conflict.remote,
              ConflictResolution.remote,
            ),
            const SizedBox(height: 12),
            _buildKeepBothOption(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedResolution == null
              ? null
              : () => Navigator.of(context).pop(_selectedResolution),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildVersionCard(
    String title,
    NoteModel note,
    ConflictResolution resolution,
  ) {
    final isSelected = _selectedResolution == resolution;
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedResolution = resolution;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                if (isSelected) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getContentPreview(note.content),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '修改时间: ${_formatDate(date)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeepBothOption() {
    final isSelected = _selectedResolution == ConflictResolution.both;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedResolution = ConflictResolution.both;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : null,
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue, size: 20),
            if (isSelected) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保留两者',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '将远程版本保存为新笔记（标题添加"冲突副本"）',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    try {
      // 尝试从 Tiptap JSON 提取文本
      final text = content
          .replaceAll(RegExp(r'[{}\[\]":,]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    } catch (e) {
      return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
