import 'dart:io';

import 'package:mid_auth/src/persistence/sqlite/migrations.dart';
import 'package:mid_auth/src/persistence/sqlite/tables.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:path/path.dart' as p;

final migrations = <SqliteMigration>[
  SqliteMigration(id: 0, description: 'table1', statement: "create table test1 (id integer primary key);"),
  SqliteMigration(id: 1, description: 'table2', statement: "create table test2 (id integer primary key);"),
  SqliteMigration(id: 2, description: 'table3', statement: "create table test3 (id integer primary key);"),
  SqliteMigration(id: 3, description: 'table4', statement: "create table test4 (id integer primary key);"),
];

final migrationsDuplicate = <SqliteMigration>[
  ...migrations,
  SqliteMigration(id: 0, description: 'table1', statement: "create table test1 (id integer primary key);"),
];

void main() {
  final timeNow = DateTime.now().toUtc();
  final dbName = 'auth_${timeNow.millisecondsSinceEpoch}';
  final tempFolder = Directory.systemTemp.path;
  final dbPath = p.join(tempFolder, dbName);

  late Database database;
  setUp(() {
    database = sqlite3.open(dbPath);
  });

  tearDown(() {
    database.dispose();
    File(dbPath).deleteSync();
  });

  bool tableExists(String tableName) {
    final res = database.select("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [tableName]);
    if (res.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  group('sqlite3 migrations', () {
    test('- calling applyMigrations for the first time creates a migration table', () {
      expect(tableExists(migrationsTable), false);
      applyMigrations(database, []);
      expect(tableExists(migrationsTable), true);
    });

    test('- all given migrations are applied', () {
      expect(tableExists('test1'), false);
      expect(tableExists('test2'), false);
      expect(tableExists('test3'), false);
      expect(tableExists('test4'), false);

      applyMigrations(database, migrations);

      expect(tableExists('test1'), true);
      expect(tableExists('test2'), true);
      expect(tableExists('test3'), true);
      expect(tableExists('test4'), true);
    });

    test('- applying the migrations multiple times has no effect', () {
      applyMigrations(database, migrations);
      applyMigrations(database, migrations);
    });

    test('- migrations containing duplicate ids throws an Exception', () {
      expect(() => applyMigrations(database, migrationsDuplicate), throwsException);
    });

    test('- logger is called for each migration', () {
      final loggedStrings = <String>[];
      applyMigrations(database, migrations, logger: (string) {
        loggedStrings.add(string);
      });
      expect(loggedStrings.length, 4);
    });

    test('- logger is called for new migration(s) only', () {
      // apply some migrations (total 4)
      applyMigrations(database, migrations);
      final newMigration = SqliteMigration(
        id: 42,
        description: 'test42',
        statement: 'create table test42 (id integer primary key);',
      );
      final loggedStrings = <String>[];
      applyMigrations(database, [...migrations, newMigration], logger: (string) {
        loggedStrings.add(string);
      });

      expect(loggedStrings.length, 1);
    });

    test('- migration table should contain all applied migrations', () {
      applyMigrations(database, migrations);

      final res = database.select('select id from $migrationsTable');
      final ids = res.rows.map((row) => row.first as int);

      expect(ids, containsAll(migrations.map((m) => m.id)));
    });
  });
}
