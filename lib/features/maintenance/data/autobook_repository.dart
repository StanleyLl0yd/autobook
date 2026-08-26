import 'dart:async';

import 'package:autobook/core/database/app_database.dart';
import 'package:autobook/features/maintenance/domain/maintenance_calculator.dart';
import 'package:autobook/features/maintenance/domain/models.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class AutoBookRepository {
  AutoBookRepository(this._database, {this.uuid = const Uuid()});

  final AppDatabase _database;
  final Uuid uuid;
  final _changes = StreamController<void>.broadcast();

  Stream<Vehicle?> watchActiveVehicle() => _watch(getActiveVehicle);

  Stream<List<ServiceEvent>> watchServiceEvents(String vehicleId) =>
      _watch(() => getServiceEvents(vehicleId));

  Stream<List<MaintenanceSchedule>> watchMaintenanceSchedules(
    String vehicleId,
  ) => _watch(() => getMaintenanceSchedules(vehicleId));

  Stream<T> _watch<T>(Future<T> Function() query) async* {
    yield await query();
    await for (final _ in _changes.stream) {
      yield await query();
    }
  }

  Future<Vehicle?> getActiveVehicle() async {
    final rows = await _database.customSelect('''
      SELECT * FROM vehicles
      ORDER BY created_at ASC
      LIMIT 1
    ''').get();
    return rows.isEmpty ? null : _vehicleFromRow(rows.single);
  }

  Future<Vehicle> addVehicle(NewVehicle input) async {
    final id = uuid.v4();
    final mileageId = uuid.v4();
    final now = DateTime.now();
    await _database.transaction(() async {
      await _database.customInsert(
        '''
          INSERT INTO vehicles (
            id, brand, model, year, current_mileage, nickname,
            created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(id),
          Variable.withString(input.brand.trim()),
          Variable.withString(input.model.trim()),
          Variable.withInt(input.year),
          Variable.withInt(input.currentMileage),
          Variable<String>(input.nickname?.trim()),
          Variable.withInt(now.millisecondsSinceEpoch),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
      );
      await _database.customInsert(
        '''
          INSERT INTO mileage_records (id, vehicle_id, mileage, recorded_at)
          VALUES (?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(mileageId),
          Variable.withString(id),
          Variable.withInt(input.currentMileage),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
      );
    });
    _notify();
    return Vehicle(
      id: id,
      brand: input.brand.trim(),
      model: input.model.trim(),
      year: input.year,
      currentMileage: input.currentMileage,
      nickname: input.nickname?.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateMileage({
    required String vehicleId,
    required int mileage,
  }) async {
    final now = DateTime.now();
    await _database.transaction(() async {
      await _database.customUpdate(
        'UPDATE vehicles SET current_mileage = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(mileage),
          Variable.withInt(now.millisecondsSinceEpoch),
          Variable.withString(vehicleId),
        ],
      );
      await _database.customInsert(
        '''
          INSERT INTO mileage_records (id, vehicle_id, mileage, recorded_at)
          VALUES (?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(uuid.v4()),
          Variable.withString(vehicleId),
          Variable.withInt(mileage),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
      );
    });
    _notify();
  }

  Future<String> addServiceEvent(NewServiceEvent input) async {
    if (input.types.isEmpty) {
      throw ArgumentError.value(input.types, 'types', 'Must not be empty');
    }
    final eventId = uuid.v4();
    final now = DateTime.now();
    await _database.transaction(() async {
      await _database.customInsert(
        '''
          INSERT INTO service_events (
            id, vehicle_id, category, service_date, mileage,
            service_location, total_cost, currency, comment,
            created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 'RUB', ?, ?, ?)
        ''',
        variables: [
          Variable.withString(eventId),
          Variable.withString(input.vehicleId),
          Variable.withString(input.category.name),
          Variable.withInt(input.date.millisecondsSinceEpoch),
          Variable.withInt(input.mileage),
          Variable<String>(_emptyToNull(input.serviceLocation)),
          Variable.withInt(input.totalCost),
          Variable<String>(_emptyToNull(input.comment)),
          Variable.withInt(now.millisecondsSinceEpoch),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
      );

      for (final type in input.types) {
        await _database.customInsert(
          '''
            INSERT INTO service_items (
              id, service_event_id, maintenance_type, title, comment
            ) VALUES (?, ?, ?, ?, NULL)
          ''',
          variables: [
            Variable.withString(uuid.v4()),
            Variable.withString(eventId),
            Variable.withString(type.storageKey),
            Variable.withString(type.storageKey),
          ],
        );

        if (input.intervalKm != null || input.intervalMonths != null) {
          final schedule = MaintenanceCalculator.scheduleFrom(
            id: uuid.v4(),
            vehicleId: input.vehicleId,
            type: type,
            serviceDate: input.date,
            serviceMileage: input.mileage,
            intervalKm: input.intervalKm,
            intervalMonths: input.intervalMonths,
          );
          await _upsertSchedule(schedule);
        }
      }

      final current = await _database
          .customSelect(
            'SELECT current_mileage FROM vehicles WHERE id = ?',
            variables: [Variable.withString(input.vehicleId)],
          )
          .getSingle();
      if (input.mileage > current.read<int>('current_mileage')) {
        await _database.customUpdate(
          'UPDATE vehicles SET current_mileage = ?, updated_at = ? WHERE id = ?',
          variables: [
            Variable.withInt(input.mileage),
            Variable.withInt(now.millisecondsSinceEpoch),
            Variable.withString(input.vehicleId),
          ],
        );
        await _database.customInsert(
          '''
            INSERT INTO mileage_records (id, vehicle_id, mileage, recorded_at)
            VALUES (?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(uuid.v4()),
            Variable.withString(input.vehicleId),
            Variable.withInt(input.mileage),
            Variable.withInt(now.millisecondsSinceEpoch),
          ],
        );
      }
    });
    _notify();
    return eventId;
  }

  Future<void> _upsertSchedule(MaintenanceSchedule schedule) async {
    await _database.customInsert(
      '''
        INSERT INTO maintenance_schedules (
          id, vehicle_id, maintenance_type, interval_km, interval_months,
          last_service_date, last_service_mileage, next_date, next_mileage,
          enabled
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(vehicle_id, maintenance_type) DO UPDATE SET
          interval_km = excluded.interval_km,
          interval_months = excluded.interval_months,
          last_service_date = excluded.last_service_date,
          last_service_mileage = excluded.last_service_mileage,
          next_date = excluded.next_date,
          next_mileage = excluded.next_mileage,
          enabled = excluded.enabled
      ''',
      variables: [
        Variable.withString(schedule.id),
        Variable.withString(schedule.vehicleId),
        Variable.withString(schedule.type.storageKey),
        Variable<int>(schedule.intervalKm),
        Variable<int>(schedule.intervalMonths),
        Variable.withInt(schedule.lastServiceDate.millisecondsSinceEpoch),
        Variable.withInt(schedule.lastServiceMileage),
        Variable<int>(schedule.nextDate?.millisecondsSinceEpoch),
        Variable<int>(schedule.nextMileage),
        Variable.withInt(schedule.enabled ? 1 : 0),
      ],
    );
  }

  Future<List<ServiceEvent>> getServiceEvents(String vehicleId) async {
    final eventRows = await _database
        .customSelect(
          '''
        SELECT * FROM service_events
        WHERE vehicle_id = ?
        ORDER BY service_date DESC, created_at DESC
      ''',
          variables: [Variable.withString(vehicleId)],
        )
        .get();
    final result = <ServiceEvent>[];
    for (final row in eventRows) {
      final eventId = row.read<String>('id');
      final itemRows = await _database
          .customSelect(
            '''
          SELECT * FROM service_items
          WHERE service_event_id = ?
          ORDER BY rowid ASC
        ''',
            variables: [Variable.withString(eventId)],
          )
          .get();
      result.add(_serviceEventFromRow(row, itemRows));
    }
    return result;
  }

  Future<List<MaintenanceSchedule>> getMaintenanceSchedules(
    String vehicleId,
  ) async {
    final rows = await _database
        .customSelect(
          '''
        SELECT * FROM maintenance_schedules
        WHERE vehicle_id = ? AND enabled = 1
      ''',
          variables: [Variable.withString(vehicleId)],
        )
        .get();
    return rows.map(_scheduleFromRow).toList();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() => _changes.close();

  Vehicle _vehicleFromRow(QueryRow row) => Vehicle(
    id: row.read<String>('id'),
    brand: row.read<String>('brand'),
    model: row.read<String>('model'),
    year: row.read<int>('year'),
    currentMileage: row.read<int>('current_mileage'),
    nickname: row.readNullable<String>('nickname'),
    createdAt: _date(row.read<int>('created_at')),
    updatedAt: _date(row.read<int>('updated_at')),
  );

  ServiceEvent _serviceEventFromRow(QueryRow row, List<QueryRow> itemRows) =>
      ServiceEvent(
        id: row.read<String>('id'),
        vehicleId: row.read<String>('vehicle_id'),
        category: ServiceCategory.values.firstWhere(
          (category) => category.name == row.read<String>('category'),
          orElse: () => ServiceCategory.maintenance,
        ),
        date: _date(row.read<int>('service_date')),
        mileage: row.read<int>('mileage'),
        serviceLocation: row.readNullable<String>('service_location'),
        totalCost: row.read<int>('total_cost'),
        currency: row.read<String>('currency'),
        comment: row.readNullable<String>('comment'),
        createdAt: _date(row.read<int>('created_at')),
        items: itemRows
            .map(
              (item) => ServiceItem(
                id: item.read<String>('id'),
                serviceEventId: item.read<String>('service_event_id'),
                type: MaintenanceTypeDetails.fromStorageKey(
                  item.read<String>('maintenance_type'),
                ),
                title: item.read<String>('title'),
                comment: item.readNullable<String>('comment'),
              ),
            )
            .toList(),
      );

  MaintenanceSchedule _scheduleFromRow(QueryRow row) => MaintenanceSchedule(
    id: row.read<String>('id'),
    vehicleId: row.read<String>('vehicle_id'),
    type: MaintenanceTypeDetails.fromStorageKey(
      row.read<String>('maintenance_type'),
    ),
    intervalKm: row.readNullable<int>('interval_km'),
    intervalMonths: row.readNullable<int>('interval_months'),
    lastServiceDate: _date(row.read<int>('last_service_date')),
    lastServiceMileage: row.read<int>('last_service_mileage'),
    nextDate: _nullableDate(row.readNullable<int>('next_date')),
    nextMileage: row.readNullable<int>('next_mileage'),
    enabled: row.read<int>('enabled') == 1,
  );

  DateTime _date(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);

  DateTime? _nullableDate(int? milliseconds) =>
      milliseconds == null ? null : _date(milliseconds);

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
