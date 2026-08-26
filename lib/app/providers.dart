import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/features/maintenance/data/autobook_repository.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final repositoryProvider = Provider<AutoBookRepository>((ref) {
  final repository = AutoBookRepository(ref.watch(databaseProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

final activeVehicleProvider = StreamProvider<Vehicle?>((ref) {
  return ref.watch(repositoryProvider).watchActiveVehicle();
});

final serviceEventsProvider = StreamProvider.family<List<ServiceEvent>, String>(
  (ref, vehicleId) =>
      ref.watch(repositoryProvider).watchServiceEvents(vehicleId),
);

final maintenanceSchedulesProvider =
    StreamProvider.family<List<MaintenanceSchedule>, String>(
      (ref, vehicleId) =>
          ref.watch(repositoryProvider).watchMaintenanceSchedules(vehicleId),
    );
