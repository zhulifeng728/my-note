import 'package:drift/drift.dart';

@DataClassName('SyncLog')
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().named('note_id')();
  TextColumn get deviceId => text().named('device_id')();
  IntColumn get syncedAt => integer().named('synced_at')();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get conflictData => text().named('conflict_data').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
