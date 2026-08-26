enum ServiceCategory { maintenance, repair }

enum MaintenanceType {
  engineOil,
  oilFilter,
  airFilter,
  cabinFilter,
  sparkPlugs,
  brakeFluid,
  coolant,
  frontBrakePads,
  rearBrakePads,
  timingBelt,
  timingChain,
  battery,
  transmissionOil,
  tires,
  wipers,
  other,
}

extension MaintenanceTypeDetails on MaintenanceType {
  String get storageKey => switch (this) {
        MaintenanceType.engineOil => 'engine_oil',
        MaintenanceType.oilFilter => 'oil_filter',
        MaintenanceType.airFilter => 'air_filter',
        MaintenanceType.cabinFilter => 'cabin_filter',
        MaintenanceType.sparkPlugs => 'spark_plugs',
        MaintenanceType.brakeFluid => 'brake_fluid',
        MaintenanceType.coolant => 'coolant',
        MaintenanceType.frontBrakePads => 'front_brake_pads',
        MaintenanceType.rearBrakePads => 'rear_brake_pads',
        MaintenanceType.timingBelt => 'timing_belt',
        MaintenanceType.timingChain => 'timing_chain',
        MaintenanceType.battery => 'battery',
        MaintenanceType.transmissionOil => 'transmission_oil',
        MaintenanceType.tires => 'tires',
        MaintenanceType.wipers => 'wipers',
        MaintenanceType.other => 'other',
      };

  String get localizationKey => switch (this) {
        MaintenanceType.engineOil => 'engineOil',
        MaintenanceType.oilFilter => 'oilFilter',
        MaintenanceType.airFilter => 'airFilter',
        MaintenanceType.cabinFilter => 'cabinFilter',
        MaintenanceType.sparkPlugs => 'sparkPlugs',
        MaintenanceType.brakeFluid => 'brakeFluid',
        MaintenanceType.coolant => 'coolant',
        MaintenanceType.frontBrakePads => 'frontBrakePads',
        MaintenanceType.rearBrakePads => 'rearBrakePads',
        MaintenanceType.timingBelt => 'timingBelt',
        MaintenanceType.timingChain => 'timingChain',
        MaintenanceType.battery => 'battery',
        MaintenanceType.transmissionOil => 'transmissionOil',
        MaintenanceType.tires => 'tires',
        MaintenanceType.wipers => 'wipers',
        MaintenanceType.other => 'other',
      };

  static MaintenanceType fromStorageKey(String key) {
    return MaintenanceType.values.firstWhere(
      (type) => type.storageKey == key,
      orElse: () => MaintenanceType.other,
    );
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.currentMileage,
    required this.createdAt,
    required this.updatedAt,
    this.nickname,
  });

  final String id;
  final String brand;
  final String model;
  final int year;
  final int currentMileage;
  final String? nickname;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final value = nickname?.trim();
    return value == null || value.isEmpty ? '$brand $model' : value;
  }

  Vehicle copyWith({int? currentMileage, DateTime? updatedAt}) => Vehicle(
        id: id,
        brand: brand,
        model: model,
        year: year,
        currentMileage: currentMileage ?? this.currentMileage,
        nickname: nickname,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class MileageRecord {
  const MileageRecord({
    required this.id,
    required this.vehicleId,
    required this.mileage,
    required this.recordedAt,
  });

  final String id;
  final String vehicleId;
  final int mileage;
  final DateTime recordedAt;
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.serviceEventId,
    required this.type,
    required this.title,
    this.comment,
  });

  final String id;
  final String serviceEventId;
  final MaintenanceType type;
  final String title;
  final String? comment;
}

class ServiceEvent {
  const ServiceEvent({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.mileage,
    required this.totalCost,
    required this.currency,
    required this.createdAt,
    required this.items,
    this.serviceLocation,
    this.comment,
  });

  final String id;
  final String vehicleId;
  final ServiceCategory category;
  final DateTime date;
  final int mileage;
  final int totalCost;
  final String currency;
  final String? serviceLocation;
  final String? comment;
  final DateTime createdAt;
  final List<ServiceItem> items;

  String get fallbackTitle => category == ServiceCategory.maintenance
      ? 'maintenance'
      : 'repair';
}

class MaintenanceSchedule {
  const MaintenanceSchedule({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.lastServiceDate,
    required this.lastServiceMileage,
    required this.enabled,
    this.intervalKm,
    this.intervalMonths,
    this.nextDate,
    this.nextMileage,
  });

  final String id;
  final String vehicleId;
  final MaintenanceType type;
  final int? intervalKm;
  final int? intervalMonths;
  final DateTime lastServiceDate;
  final int lastServiceMileage;
  final DateTime? nextDate;
  final int? nextMileage;
  final bool enabled;
}

class NewVehicle {
  const NewVehicle({
    required this.brand,
    required this.model,
    required this.year,
    required this.currentMileage,
    this.nickname,
  });

  final String brand;
  final String model;
  final int year;
  final int currentMileage;
  final String? nickname;
}

class NewServiceEvent {
  const NewServiceEvent({
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.mileage,
    required this.totalCost,
    required this.types,
    this.serviceLocation,
    this.comment,
    this.intervalKm,
    this.intervalMonths,
  });

  final String vehicleId;
  final ServiceCategory category;
  final DateTime date;
  final int mileage;
  final int totalCost;
  final List<MaintenanceType> types;
  final String? serviceLocation;
  final String? comment;
  final int? intervalKm;
  final int? intervalMonths;
}

