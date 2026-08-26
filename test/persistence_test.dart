import 'dart:io';

import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/features/maintenance/data/autobook_repository.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('vehicle data survives closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp('autobook-test-');
    final file = File(path.join(directory.path, 'autobook.sqlite'));

    try {
      final firstDatabase = AppDatabase.forExecutor(NativeDatabase(file));
      final firstRepository = AutoBookRepository(firstDatabase);
      await firstRepository.addVehicle(
        const NewVehicle(
          brand: 'Kia',
          model: 'Sportage',
          year: 2021,
          currentMileage: 97420,
        ),
      );
      await firstRepository.dispose();
      await firstDatabase.close();

      final reopenedDatabase = AppDatabase.forExecutor(NativeDatabase(file));
      final reopenedRepository = AutoBookRepository(reopenedDatabase);
      final vehicle = await reopenedRepository.getActiveVehicle();

      expect(vehicle?.brand, 'Kia');
      expect(vehicle?.model, 'Sportage');
      expect(vehicle?.currentMileage, 97420);

      await reopenedRepository.dispose();
      await reopenedDatabase.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

