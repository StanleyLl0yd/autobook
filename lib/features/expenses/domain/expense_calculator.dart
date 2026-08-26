import 'package:autobook/features/maintenance/domain/models.dart';

class ExpenseSummary {
  const ExpenseSummary({required this.year, required this.byCategory});

  final int year;
  final Map<ServiceCategory, int> byCategory;

  int get total => byCategory.values.fold(0, (sum, value) => sum + value);
}

abstract final class ExpenseCalculator {
  static ExpenseSummary forYear(Iterable<ServiceEvent> events, int year) {
    final totals = <ServiceCategory, int>{};
    for (final event in events.where((event) => event.date.year == year)) {
      totals.update(
        event.category,
        (value) => value + event.totalCost,
        ifAbsent: () => event.totalCost,
      );
    }
    return ExpenseSummary(year: year, byCategory: totals);
  }
}
