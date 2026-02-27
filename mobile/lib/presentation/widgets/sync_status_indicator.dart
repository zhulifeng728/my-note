import 'package:flutter/material.dart';

class SyncStatusIndicator extends StatelessWidget {
  final String status; // 'connected', 'waiting', 'syncing', 'error'
  final String? message;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 16,
            color: Colors.white,
          ),
          if (message != null) ...[
            const SizedBox(width: 8),
            Text(
              message!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'syncing':
        return Colors.blue;
      case 'error':
        return Colors.red;
      case 'waiting':
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (status) {
      case 'connected':
        return Icons.cloud_done;
      case 'syncing':
        return Icons.sync;
      case 'error':
        return Icons.cloud_off;
      case 'waiting':
      default:
        return Icons.cloud_queue;
    }
  }
}
