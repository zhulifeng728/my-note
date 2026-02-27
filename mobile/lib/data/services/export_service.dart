import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class ExportService {
  /// 导出为 Markdown
  Future<String> exportToMarkdown(Note note) async {
    try {
      final buffer = StringBuffer();

      // 标题
      buffer.writeln('# ${note.title}');
      buffer.writeln();

      // 内容（简化处理，实际应该从 Tiptap JSON 转换）
      buffer.writeln(note.content);
      buffer.writeln();

      // 元数据
      final createdDate = DateTime.fromMillisecondsSinceEpoch(note.createdAt);
      final updatedDate = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
      buffer.writeln('---');
      buffer.writeln('创建时间: ${_formatDate(createdDate)}');
      buffer.writeln('修改时间: ${_formatDate(updatedDate)}');

      return buffer.toString();
    } catch (e) {
      throw Exception('导出 Markdown 失败: $e');
    }
  }

  /// 导出为纯文本
  Future<String> exportToText(Note note) async {
    try {
      final buffer = StringBuffer();

      // 标题
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      buffer.writeln();

      // 内容（移除 JSON 标记）
      final plainText = _extractPlainText(note.content);
      buffer.writeln(plainText);
      buffer.writeln();

      // 元数据
      final createdDate = DateTime.fromMillisecondsSinceEpoch(note.createdAt);
      final updatedDate = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
      buffer.writeln('---');
      buffer.writeln('创建时间: ${_formatDate(createdDate)}');
      buffer.writeln('修改时间: ${_formatDate(updatedDate)}');

      return buffer.toString();
    } catch (e) {
      throw Exception('导出文本失败: $e');
    }
  }

  /// 导出为 PDF
  Future<File> exportToPdf(Note note) async {
    try {
      final pdf = pw.Document();

      // 提取纯文本
      final plainText = _extractPlainText(note.content);
      final createdDate = DateTime.fromMillisecondsSinceEpoch(note.createdAt);
      final updatedDate = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 标题
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // 内容
                pw.Text(
                  plainText,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // 元数据
                pw.Divider(),
                pw.Text(
                  '创建时间: ${_formatDate(createdDate)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
                pw.Text(
                  '修改时间: ${_formatDate(updatedDate)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName = '${_sanitizeFileName(note.title)}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      throw Exception('导出 PDF 失败: $e');
    }
  }

  /// 分享笔记
  Future<void> shareNote(Note note, String format) async {
    try {
      if (format == 'md') {
        final content = await exportToMarkdown(note);
        final tempDir = await getTemporaryDirectory();
        final fileName = '${_sanitizeFileName(note.title)}.md';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(content);
        await Share.shareXFiles([XFile(file.path)], text: note.title);
      } else if (format == 'txt') {
        final content = await exportToText(note);
        final tempDir = await getTemporaryDirectory();
        final fileName = '${_sanitizeFileName(note.title)}.txt';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(content);
        await Share.shareXFiles([XFile(file.path)], text: note.title);
      } else if (format == 'pdf') {
        final file = await exportToPdf(note);
        await Share.shareXFiles([XFile(file.path)], text: note.title);
      } else {
        throw Exception('不支持的格式: $format');
      }
    } catch (e) {
      throw Exception('分享失败: $e');
    }
  }

  /// 批量导出笔记
  Future<void> exportMultipleNotes(List<Note> notes, String format) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = <XFile>[];

      for (final note in notes) {
        if (format == 'md') {
          final content = await exportToMarkdown(note);
          final fileName = '${_sanitizeFileName(note.title)}.md';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsString(content);
          files.add(XFile(file.path));
        } else if (format == 'txt') {
          final content = await exportToText(note);
          final fileName = '${_sanitizeFileName(note.title)}.txt';
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsString(content);
          files.add(XFile(file.path));
        } else if (format == 'pdf') {
          final file = await exportToPdf(note);
          files.add(XFile(file.path));
        }
      }

      await Share.shareXFiles(files, text: '导出的笔记');
    } catch (e) {
      throw Exception('批量导出失败: $e');
    }
  }

  /// 提取纯文本
  String _extractPlainText(String content) {
    // 简化处理：移除 JSON 标记
    return content
        .replaceAll(RegExp(r'[{}\[\]":,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 清理文件名（移除非法字符）
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, fileName.length > 50 ? 50 : fileName.length);
  }
}
