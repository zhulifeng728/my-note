import 'package:drift/drift.dart';

@DataClassName('Folder')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().named('parent_id').nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
