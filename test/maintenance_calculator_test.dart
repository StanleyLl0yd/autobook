import 'package:autobook/features/maintenance/domain/maintenance_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaintenanceCalculator', () {
    test('calculates next mileage and next date', () {
      final schedule = MaintenanceCalculator.scheduleFrom(
        id: 'schedule-1',
        vehicleId: 'vehicle-1',
        type: MaintenanceType.engineOil,
        serviceDate: DateTime(2026),
        serviceMileage: 100000,
        intervalKm: 10000,
        intervalMonths: 12,
      );

      expect(schedule.nextMileage, 110000);
      expect(schedule.nextDate, DateTime(2027));
    });

    test('clamps a monthly interval to the final day of target month', () {
      final result = MaintenanceCalculator.addMonths(DateTime(2026, 1, 31), 1);

      expect(result, DateTime(2026, 2, 28));
    });

    test('recalculates remaining mileage from current vehicle mileage', () {
      final schedule = MaintenanceCalculator.scheduleFrom(
        id: 'schedule-1',
        vehicleId: 'vehicle-1',
        type: MaintenanceType.engineOil,
        serviceDate: DateTime(2026, 8, 25),
        serviceMileage: 97420,
        intervalKm: 10000,
        intervalMonths: 12,
      );

      final due = MaintenanceCalculator.dueFor(
        schedule: schedule,
        currentMileage: 104420,
        today: DateTime(2026, 8, 26),
      );

      expect(due.remainingKm, 3000);
      expect(due.urgency, MaintenanceUrgency.normal);
    });

    test('is overdue when either date or mileage threshold is reached', () {
      final schedule = MaintenanceCalculator.scheduleFrom(
        id: 'schedule-1',
        vehicleId: 'vehicle-1',
        type: MaintenanceType.brakeFluid,
        serviceDate: DateTime(2024, 1, 1),
        serviceMileage: 50000,
        intervalKm: 50000,
        intervalMonths: 24,
      );

      final due = MaintenanceCalculator.dueFor(
        schedule: schedule,
        currentMileage: 70000,
        today: DateTime(2026, 1, 1),
      );

      expect(due.remainingKm, 30000);
      expect(due.remainingDays, 0);
      expect(due.urgency, MaintenanceUrgency.overdue);
    });
  });
}
