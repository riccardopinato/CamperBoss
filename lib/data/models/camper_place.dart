class CamperPlace {
  const CamperPlace({
    this.id,
    this.packageId,
    required this.name,
    required this.category,
    required this.type,
    required this.distance,
    required this.rating,
    required this.tags,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.description,
    this.services = const [],
    this.source,
    this.updatedAt,
  });

  final String? id;
  final String? packageId;
  final String name;
  final String category;
  final String type;
  final String distance;
  final String rating;
  final List<String> tags;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? description;
  final List<String> services;
  final String? source;
  final DateTime? updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'package_id': packageId,
      'name': name,
      'category': category,
      'type': type,
      'distance': distance,
      'rating': rating,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'description': description,
      'services': services,
      'source': source,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CamperPlace.fromMap(Map<String, Object?> map) {
    return CamperPlace(
      id: map['id']?.toString(),
      packageId: map['package_id'] as String?,
      name: map['name'] as String,
      category: map['category'] as String,
      type: map['type'] as String,
      distance: map['distance'] as String? ?? '',
      rating: map['rating'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>? ?? const []).cast<String>(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      city: map['city'] as String?,
      description: map['description'] as String?,
      services: (map['services'] as List<dynamic>? ?? const []).cast<String>(),
      source: map['source'] as String?,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? ''),
    );
  }
}

class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  bool contains(double latitude, double longitude) {
    return latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
  }
}
