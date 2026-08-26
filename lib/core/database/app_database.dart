import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppDatabase extends GeneratedDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  AppDatabase.forExecutor(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('''
            CREATE TABLE vehicles (
              id TEXT PRIMARY KEY NOT NULL,
              brand TEXT NOT NULL,
              model TEXT NOT NULL,
              year INTEGER NOT NULL,
              current_mileage INTEGER NOT NULL CHECK(current_mileage >= 0),
              nickname TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await customStatement('''
            CREATE TABLE mileage_records (
              id TEXT PRIMARY KEY NOT NULL,
              vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
              mileage INTEGER NOT NULL CHECK(mileage >= 0),
              recorded_at INTEGER NOT NULL
            )
          ''');
          await customStatement('''
            CREATE TABLE service_events (
              id TEXT PRIMARY KEY NOT NULL,
              vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
              category TEXT NOT NULL,
              service_date INTEGER NOT NULL,
              mileage INTEGER NOT NULL CHECK(mileage >= 0),
              service_location TEXT,
              total_cost INTEGER NOT NULL DEFAULT 0 CHECK(total_cost >= 0),
              currency TEXT NOT NULL DEFAULT 'RUB',
              comment TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await customStatement('''
            CREATE TABLE service_items (
              id TEXT PRIMARY KEY NOT NULL,
              service_event_id TEXT NOT NULL REFERENCES service_events(id) ON DELETE CASCADE,
              maintenance_type TEXT NOT NULL,
              title TEXT NOT NULL,
              comment TEXT
            )
          ''');
          await customStatement('''
            CREATE TABLE maintenance_schedules (
              id TEXT PRIMARY KEY NOT NULL,
              vehicle_id TEXT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
              maintenance_type TEXT NOT NULL,
              interval_km INTEGER,
              interval_months INTEGER,
              last_service_date INTEGER NOT NULL,
              last_service_mileage INTEGER NOT NULL,
              next_date INTEGER,
              next_mileage INTEGER,
              enabled INTEGER NOT NULL DEFAULT 1,
              UNIQUE(vehicle_id, maintenance_type)
            )
          ''');
          await customStatement(
            'CREATE INDEX idx_events_vehicle_date '
            'ON service_events(vehicle_id, service_date DESC)',
          );
          await customStatement(
            'CREATE INDEX idx_mileage_vehicle_date '
            'ON mileage_records(vehicle_id, recorded_at DESC)',
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'autobook.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
