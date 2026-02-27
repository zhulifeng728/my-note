import 'package:drift/drift.dart';

@DataClassName('Note')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get folderId => text().named('folder_id').withDefault(const Constant('all'))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get isDeleted => integer().named('is_deleted').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
