import 'dart:io';

import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/features/maintenance/data/autobook_repository.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('enables foreign keys and creates the expected schema', () async {
    final database = AppDatabase.inMemory();

    try {
      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();

      expect(foreignKeys.read<int>('foreign_keys'), 1);
      expect(
        version.read<int>('user_version'),
        AppDatabase.currentSchemaVersion,
      );
      expect(tables.map((row) => row.read<String>('name')), [
        'maintenance_schedules',
        'mileage_records',
        'service_events',
        'service_items',
        'vehicles',
      ]);
    } finally {
      await database.close();
    }
  });

  test('deleting a vehicle cascades through its local history', () async {
    final database = AppDatabase.inMemory();
    final repository = AutoBookRepository(database);

    try {
      final vehicle = await repository.addVehicle(
        const NewVehicle(
          brand: 'Kia',
          model: 'Sportage',
          year: 2021,
          currentMileage: 97420,
        ),
      );
      await repository.addServiceEvent(
        NewServiceEvent(
          vehicleId: vehicle.id,
          category: ServiceCategory.maintenance,
          date: DateTime(2026, 8, 25),
          mileage: 97420,
          totalCost: 10550,
          types: const [MaintenanceType.engineOil, MaintenanceType.oilFilter],
          intervalKm: 10000,
          intervalMonths: 12,
        ),
      );

      await database.customDelete(
        'DELETE FROM vehicles WHERE id = ?',
        variables: [Variable.withString(vehicle.id)],
      );

      for (final table in [
        'vehicles',
        'mileage_records',
        'service_events',
        'service_items',
        'maintenance_schedules',
      ]) {
        final row = await database
            .customSelect('SELECT COUNT(*) AS count FROM $table')
            .getSingle();
        expect(row.read<int>('count'), 0, reason: table);
      }
    } finally {
      await repository.dispose();
      await database.close();
    }
  });

  test('an unimplemented schema upgrade fails without deleting data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'autobook-migration-test-',
    );
    final file = File(path.join(directory.path, 'autobook.sqlite'));

    try {
      final originalDatabase = AppDatabase.forExecutor(NativeDatabase(file));
      final repository = AutoBookRepository(originalDatabase);
      await repository.addVehicle(
        const NewVehicle(
          brand: 'Kia',
          model: 'Sportage',
          year: 2021,
          currentMileage: 97420,
        ),
      );
      await repository.dispose();
      await originalDatabase.close();

      final futureDatabase = _FutureSchemaDatabase(NativeDatabase(file));
      await expectLater(
        futureDatabase.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await futureDatabase.close();

      final reopenedDatabase = AppDatabase.forExecutor(NativeDatabase(file));
      final reopenedRepository = AutoBookRepository(reopenedDatabase);
      expect((await reopenedRepository.getActiveVehicle())?.brand, 'Kia');
      await reopenedRepository.dispose();
      await reopenedDatabase.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

class _FutureSchemaDatabase extends AppDatabase {
  _FutureSchemaDatabase(QueryExecutor executor) : super.forExecutor(executor);

  @override
  int get schemaVersion => AppDatabase.currentSchemaVersion + 1;
}
