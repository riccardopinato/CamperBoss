class CamperPlace {
  const CamperPlace({
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
    this.services = const [],
    this.source,
  });

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
  final List<String> services;
  final String? source;

  Map<String, Object?> toMap() {
    return {
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
      'services': services,
      'source': source,
    };
  }

  factory CamperPlace.fromMap(Map<String, Object?> map) {
    return CamperPlace(
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
      services: (map['services'] as List<dynamic>? ?? const []).cast<String>(),
      source: map['source'] as String?,
    );
  }
}
