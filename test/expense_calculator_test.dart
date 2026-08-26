import 'package:autobook/features/expenses/domain/expense_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totals source service events once and groups by category', () {
    final events = [
      _event('oil', ServiceCategory.maintenance, DateTime(2026, 8, 25), 10550),
      _event('brakes', ServiceCategory.repair, DateTime(2026, 6, 3), 14200),
      _event('old', ServiceCategory.repair, DateTime(2025, 12, 1), 5000),
    ];

    final summary = ExpenseCalculator.forYear(events, 2026);

    expect(summary.byCategory[ServiceCategory.maintenance], 10550);
    expect(summary.byCategory[ServiceCategory.repair], 14200);
    expect(summary.total, 24750);
  });
}

ServiceEvent _event(
  String id,
  ServiceCategory category,
  DateTime date,
  int cost,
) => ServiceEvent(
  id: id,
  vehicleId: 'vehicle-1',
  category: category,
  date: date,
  mileage: 100000,
  totalCost: cost,
  currency: 'RUB',
  createdAt: date,
  items: const [],
);
