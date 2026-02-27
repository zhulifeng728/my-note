import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_providers.dart';
import 'pairing_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSyncSection(context, ref),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSyncSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '同步设置',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        FutureBuilder<bool>(
          future: ref.read(pairingServiceProvider).isPaired(),
          builder: (context, snapshot) {
            final isPaired = snapshot.data ?? false;

            return ListTile(
              leading: Icon(
                isPaired ? Icons.cloud_done : Icons.cloud_off,
                color: isPaired ? Colors.green : Colors.grey,
              ),
              title: Text(isPaired ? '已配对' : '未配对'),
              subtitle: Text(isPaired ? '点击取消配对' : '点击配对设备'),
              onTap: () async {
                if (isPaired) {
                  // 取消配对
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('取消配对'),
                      content: const Text('确定要取消配对吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('取消'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(pairingServiceProvider).unpair();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已取消配对')),
                      );
                    }
                  }
                } else {
                  // 配对设备
                  if (context.mounted) {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PairingScreen(),
                      ),
                    );

                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('配对成功')),
                      );
                    }
                  }
                }
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('手动同步'),
          subtitle: const Text('立即同步所有笔记'),
          onTap: () async {
            try {
              final autoSyncManager = ref.read(autoSyncManagerProvider);
              await autoSyncManager.manualSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('同步成功')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('同步失败: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '关于',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('版本'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('开源许可'),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: '我的笔记',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 My Notes',
            );
          },
        ),
      ],
    );
  }
}
