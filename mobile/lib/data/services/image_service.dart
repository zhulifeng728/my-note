import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// 从相册选择图片
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return null;

      return await _processImage(image.path);
    } catch (e) {
      throw Exception('选择图片失败: $e');
    }
  }

  /// 从相机拍照
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) return null;

      return await _processImage(image.path);
    } catch (e) {
      throw Exception('拍照失败: $e');
    }
  }

  /// 处理图片（压缩并转换为 Base64 data URL）
  Future<String> _processImage(String imagePath) async {
    try {
      final file = File(imagePath);

      // 检查文件大小
      final fileSize = await file.length();
      if (fileSize > AppConstants.maxImageSizeBytes) {
        throw Exception('图片大小超过 ${AppConstants.maxImageSizeBytes ~/ (1024 * 1024)}MB');
      }

      // 压缩图片
      final compressedBytes = await _compressImage(imagePath);

      // 转换为 Base64
      final base64String = base64Encode(compressedBytes);

      // 返回 data URL 格式
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('处理图片失败: $e');
    }
  }

  /// 压缩图片
  Future<List<int>> _compressImage(String imagePath) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: AppConstants.maxImageWidth,
        minHeight: AppConstants.maxImageHeight,
        quality: AppConstants.imageQuality,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('压缩失败');
      }

      return result;
    } catch (e) {
      throw Exception('压缩图片失败: $e');
    }
  }

  /// 从 data URL 提取 Base64 数据
  String? extractBase64FromDataUrl(String dataUrl) {
    if (!dataUrl.startsWith('data:image/')) {
      return null;
    }

    final parts = dataUrl.split(',');
    if (parts.length != 2) {
      return null;
    }

    return parts[1];
  }

  /// 验证是否为有效的 data URL
  bool isValidDataUrl(String url) {
    return url.startsWith('data:image/') && url.contains('base64,');
  }

  /// 获取图片大小（字节）
  int getImageSize(String dataUrl) {
    final base64Data = extractBase64FromDataUrl(dataUrl);
    if (base64Data == null) return 0;

    try {
      final bytes = base64Decode(base64Data);
      return bytes.length;
    } catch (e) {
      return 0;
    }
  }
}
