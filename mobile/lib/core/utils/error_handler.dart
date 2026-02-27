import 'package:flutter/material.dart';
import 'exceptions.dart';

class ErrorHandler {
  /// 处理错误并显示用户友好的消息
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is NetworkException) {
      return '网络连接失败，请检查网络设置';
    }

    if (error is AuthException) {
      return '认证失败，请重新登录';
    }

    if (error is DatabaseException) {
      return '数据库操作失败';
    }

    if (error is SyncException) {
      return '同步失败，请稍后重试';
    }

    if (error is ValidationException) {
      return error.message;
    }

    // 默认错误消息
    return '操作失败，请稍后重试';
  }

  /// 显示错误 SnackBar
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final message = getUserFriendlyMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 显示成功 SnackBar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示信息 SnackBar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
  }) {
    final message = getUserFriendlyMessage(error);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示加载对话框
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? '加载中...'),
          ],
        ),
      ),
    );
  }

  /// 隐藏加载对话框
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 显示确认对话框
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
