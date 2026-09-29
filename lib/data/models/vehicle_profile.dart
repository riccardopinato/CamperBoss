class VehicleProfile {
  const VehicleProfile({
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    required this.maxMass,
    required this.seats,
    required this.fuelType,
    required this.mileage,
    this.id,
    this.plate,
    this.fuelCapacity,
    this.waterCapacity,
    this.gasCapacity,
    this.electricRange,
    this.notes,
    this.updatedAt,
  });

  final int? id;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String? plate;
  final double length;
  final double width;
  final double height;
  final double weight;
  final double maxMass;
  final int seats;
  final String fuelType;
  final double mileage;
  final double? fuelCapacity;
  final double? waterCapacity;
  final double? gasCapacity;
  final double? electricRange;
  final String? notes;
  final DateTime? updatedAt;

  List<String> validationErrors({DateTime? now}) {
    final errors = <String>[];
    final currentYear = (now ?? DateTime.now()).year;

    if (vehicleType.trim().isEmpty) errors.add('vehicleType');
    if (brand.trim().isEmpty) errors.add('brand');
    if (model.trim().isEmpty) errors.add('model');
    if (year < 1900 || year > currentYear + 1) errors.add('year');
    if (!length.isFinite || length <= 0) errors.add('length');
    if (!width.isFinite || width <= 0) errors.add('width');
    if (!height.isFinite || height <= 0) errors.add('height');
    if (!weight.isFinite || weight <= 0) errors.add('weight');
    if (!maxMass.isFinite || maxMass <= 0 || maxMass < weight) {
      errors.add('maxMass');
    }
    if (seats <= 0) errors.add('seats');
    if (fuelType.trim().isEmpty) errors.add('fuelType');
    if (!mileage.isFinite || mileage < 0) errors.add('mileage');

    for (final entry in <String, double?>{
      'fuelCapacity': fuelCapacity,
      'waterCapacity': waterCapacity,
      'gasCapacity': gasCapacity,
      'electricRange': electricRange,
    }.entries) {
      final value = entry.value;
      if (value != null && (!value.isFinite || value <= 0)) {
        errors.add(entry.key);
      }
    }
    return errors;
  }

  bool get isValid => validationErrors().isEmpty;

  VehicleProfile copyWith({
    int? id,
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? plate,
    double? length,
    double? width,
    double? height,
    double? weight,
    double? maxMass,
    int? seats,
    String? fuelType,
    double? mileage,
    double? fuelCapacity,
    double? waterCapacity,
    double? gasCapacity,
    double? electricRange,
    String? notes,
    DateTime? updatedAt,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      maxMass: maxMass ?? this.maxMass,
      seats: seats ?? this.seats,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      fuelCapacity: fuelCapacity ?? this.fuelCapacity,
      waterCapacity: waterCapacity ?? this.waterCapacity,
      gasCapacity: gasCapacity ?? this.gasCapacity,
      electricRange: electricRange ?? this.electricRange,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'plate': plate,
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
      'max_mass': maxMass,
      'seats': seats,
      'fuel_type': fuelType,
      'mileage': mileage,
      'fuel_capacity': fuelCapacity,
      'water_capacity': waterCapacity,
      'gas_capacity': gasCapacity,
      'electric_range': electricRange,
      'notes': notes,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory VehicleProfile.fromMap(Map<String, Object?> map) {
    return VehicleProfile(
      id: map['id'] as int? ?? map['profile_id'] as int?,
      vehicleType: map['vehicle_type'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      year: (map['year'] as num).toInt(),
      plate: map['plate'] as String?,
      length: (map['length'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      maxMass: (map['max_mass'] as num).toDouble(),
      seats: (map['seats'] as num).toInt(),
      fuelType: map['fuel_type'] as String,
      mileage: (map['mileage'] as num).toDouble(),
      fuelCapacity: (map['fuel_capacity'] as num?)?.toDouble(),
      waterCapacity: (map['water_capacity'] as num?)?.toDouble(),
      gasCapacity: (map['gas_capacity'] as num?)?.toDouble(),
      electricRange: (map['electric_range'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}
