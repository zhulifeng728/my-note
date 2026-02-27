import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_providers.dart';
import '../providers/folders_providers.dart';
import '../providers/sync_providers.dart';
import '../providers/service_providers.dart';
import 'note_editor_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    final pairingService = ref.read(pairingServiceProvider);
    final isPaired = await pairingService.isPaired();

    if (isPaired) {
      final autoSyncManager = ref.read(autoSyncManagerProvider);
      await autoSyncManager.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final notesAsync = ref.watch(notesByFolderProvider(selectedFolderId));
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的笔记'),
        actions: [
          // 同步状态指示器
          if (syncStatus.connection.name == 'connected')
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.cloud_done, color: Colors.green),
            )
          else if (syncStatus.connection.name == 'waiting')
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.cloud_off, color: Colors.grey),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '还没有笔记',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final autoSyncManager = ref.read(autoSyncManagerProvider);
              await autoSyncManager.manualSync();
            },
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteItem(note);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('加载失败: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    final foldersAsync = ref.watch(foldersProvider);
    final selectedFolderId = ref.watch(selectedFolderIdProvider);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.note, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  '我的笔记',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('全部笔记'),
            selected: selectedFolderId == 'all',
            onTap: () {
              ref.read(selectedFolderIdProvider.notifier).state = 'all';
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          Expanded(
            child: foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return const Center(
                    child: Text(
                      '还没有文件夹',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: Icon(
                        folder.icon != null
                            ? IconData(
                                int.parse(folder.icon!),
                                fontFamily: 'MaterialIcons',
                              )
                            : Icons.folder,
                      ),
                      title: Text(folder.name),
                      selected: selectedFolderId == folder.id,
                      onTap: () {
                        ref.read(selectedFolderIdProvider.notifier).state =
                            folder.id;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('加载失败: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(note) {
    final preview = _getContentPreview(note.content);
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);

    return ListTile(
      title: Text(
        note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.isNotEmpty)
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(noteId: note.id),
          ),
        );
      },
    );
  }

  String _getContentPreview(String content) {
    try {
      final text = content
          .replaceAll(RegExp(r'[{}\[\]":,]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return text.length > 100 ? '${text.substring(0, 100)}...' : text;
    } catch (e) {
      return '';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
}
