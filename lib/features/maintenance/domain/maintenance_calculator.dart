import 'package:autobook/features/maintenance/domain/models.dart';

enum MaintenanceUrgency { normal, soon, overdue }

class MaintenanceDue {
  const MaintenanceDue({
    required this.schedule,
    required this.urgency,
    this.remainingKm,
    this.remainingDays,
  });

  final MaintenanceSchedule schedule;
  final MaintenanceUrgency urgency;
  final int? remainingKm;
  final int? remainingDays;
}

abstract final class MaintenanceCalculator {
  static DateTime addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final firstOfTarget = DateTime(date.year, targetMonth, 1);
    final lastDay = DateTime(
      firstOfTarget.year,
      firstOfTarget.month + 1,
      0,
    ).day;
    return DateTime(
      firstOfTarget.year,
      firstOfTarget.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  static MaintenanceSchedule scheduleFrom({
    required String id,
    required String vehicleId,
    required MaintenanceType type,
    required DateTime serviceDate,
    required int serviceMileage,
    required int? intervalKm,
    required int? intervalMonths,
  }) {
    return MaintenanceSchedule(
      id: id,
      vehicleId: vehicleId,
      type: type,
      intervalKm: intervalKm,
      intervalMonths: intervalMonths,
      lastServiceDate: serviceDate,
      lastServiceMileage: serviceMileage,
      nextMileage: intervalKm == null ? null : serviceMileage + intervalKm,
      nextDate: intervalMonths == null
          ? null
          : addMonths(serviceDate, intervalMonths),
      enabled: intervalKm != null || intervalMonths != null,
    );
  }

  static MaintenanceDue dueFor({
    required MaintenanceSchedule schedule,
    required int currentMileage,
    required DateTime today,
    int soonKm = 1500,
    int soonDays = 45,
  }) {
    final remainingKm = schedule.nextMileage == null
        ? null
        : schedule.nextMileage! - currentMileage;
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final remainingDays = schedule.nextDate == null
        ? null
        : schedule.nextDate!.difference(normalizedToday).inDays;

    final isOverdue = (remainingKm != null && remainingKm <= 0) ||
        (remainingDays != null && remainingDays <= 0);
    final isSoon = (remainingKm != null && remainingKm <= soonKm) ||
        (remainingDays != null && remainingDays <= soonDays);

    return MaintenanceDue(
      schedule: schedule,
      remainingKm: remainingKm,
      remainingDays: remainingDays,
      urgency: isOverdue
          ? MaintenanceUrgency.overdue
          : isSoon
              ? MaintenanceUrgency.soon
              : MaintenanceUrgency.normal,
    );
  }

  static List<MaintenanceDue> sortDue(
    Iterable<MaintenanceDue> values,
  ) {
    final result = values.toList();
    result.sort((left, right) {
      final urgency = right.urgency.index.compareTo(left.urgency.index);
      if (urgency != 0) return urgency;
      final leftKm = left.remainingKm ?? 1 << 30;
      final rightKm = right.remainingKm ?? 1 << 30;
      final km = leftKm.compareTo(rightKm);
      if (km != 0) return km;
      return (left.remainingDays ?? 1 << 30).compareTo(
        right.remainingDays ?? 1 << 30,
      );
    });
    return result;
  }
}

