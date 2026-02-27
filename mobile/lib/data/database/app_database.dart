import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/notes_table.dart';
import 'tables/folders_table.dart';
import 'tables/devices_table.dart';
import 'tables/sync_log_table.dart';
import 'daos/notes_dao.dart';
import 'daos/folders_dao.dart';
import 'daos/devices_dao.dart';
import 'daos/sync_log_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Notes, Folders, Devices, SyncLogs],
  daos: [NotesDao, FoldersDao, DevicesDao, SyncLogsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // 创建 FTS5 虚拟表
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
            id UNINDEXED,
            title,
            content,
            content=notes,
            content_rowid=rowid
          )
        ''');

        // 创建触发器：同步 FTS 索引
        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS notes_fts_insert AFTER INSERT ON notes BEGIN
            INSERT INTO notes_fts(rowid, id, title, content)
              VALUES (new.rowid, new.id, new.title, new.content);
          END
        ''');

        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS notes_fts_update AFTER UPDATE ON notes BEGIN
            INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
              VALUES ('delete', old.rowid, old.id, old.title, old.content);
            INSERT INTO notes_fts(rowid, id, title, content)
              VALUES (new.rowid, new.id, new.title, new.content);
          END
        ''');

        await customStatement('''
          CREATE TRIGGER IF NOT EXISTS notes_fts_delete AFTER DELETE ON notes BEGIN
            INSERT INTO notes_fts(notes_fts, rowid, id, title, content)
              VALUES ('delete', old.rowid, old.id, old.title, old.content);
          END
        ''');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本的迁移逻辑
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notes.db'));
    return NativeDatabase(file);
  });
}
