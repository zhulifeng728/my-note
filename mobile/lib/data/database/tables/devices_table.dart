import 'package:drift/drift.dart';

@DataClassName('Device')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get deviceName => text().named('device_name')();
  TextColumn get token => text()();
  IntColumn get lastSeenAt => integer().named('last_seen_at').nullable()();
  IntColumn get isTrusted => integer().named('is_trusted').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
