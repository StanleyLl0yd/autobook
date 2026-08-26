import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/features/maintenance/data/autobook_repository.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late AutoBookRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = AutoBookRepository(database);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
  });

  test('persists vehicle, service items, and maintenance schedule', () async {
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
        types: const [
          MaintenanceType.engineOil,
          MaintenanceType.oilFilter,
        ],
        intervalKm: 10000,
        intervalMonths: 12,
      ),
    );

    final activeVehicle = await repository.getActiveVehicle();
    final events = await repository.getServiceEvents(vehicle.id);
    final schedules = await repository.getMaintenanceSchedules(vehicle.id);

    expect(activeVehicle?.brand, 'Kia');
    expect(events, hasLength(1));
    expect(events.single.items, hasLength(2));
    expect(events.single.totalCost, 10550);
    expect(schedules, hasLength(2));
    expect(schedules.first.nextMileage, 107420);
    expect(schedules.first.nextDate, DateTime(2027, 8, 25));
  });

  test('service mileage advances vehicle mileage but never lowers it', () async {
    final vehicle = await repository.addVehicle(
      const NewVehicle(
        brand: 'Kia',
        model: 'Sportage',
        year: 2021,
        currentMileage: 100000,
      ),
    );

    await repository.addServiceEvent(
      NewServiceEvent(
        vehicleId: vehicle.id,
        category: ServiceCategory.repair,
        date: DateTime(2026, 8, 1),
        mileage: 90000,
        totalCost: 1000,
        types: const [MaintenanceType.other],
      ),
    );

    expect((await repository.getActiveVehicle())?.currentMileage, 100000);
  });
}

