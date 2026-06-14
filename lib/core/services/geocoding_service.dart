import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoLocationResult {
  const GeoLocationResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;

  String get label {
    final area =
        admin1 == null || admin1!.isEmpty ? country : '$admin1, $country';
    return '$name - $area';
  }
}

class GeocodingService {
  const GeocodingService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const _endpoint = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<List<GeoLocationResult>> search(
    String query, {
    String language = 'en',
  }) async {
    final normalized = query.trim();
    if (normalized.length < 3) return const [];

    final client = _client ?? http.Client();
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'name': normalized,
        'count': '8',
        'language': language,
        'format': 'json',
      },
    );

    try {
      final response =
          await client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw StateError('Geocoding responded ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (json['results'] as List<dynamic>?) ?? const [];

      return [
        for (final item in results)
          GeoLocationResult(
            name: item['name'] as String,
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            country: (item['country'] as String?) ?? '',
            admin1: item['admin1'] as String?,
          ),
      ];
    } finally {
      if (_client == null) client.close();
    }
  }
}
