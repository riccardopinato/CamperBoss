import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/provider_trust_config.dart';

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
    final area = [
      if (admin1 != null && admin1!.isNotEmpty) admin1,
      if (country.isNotEmpty) country,
    ].join(', ');
    if (area.isEmpty) return name;
    return '$name - $area';
  }
}

class GeocodingService {
  const GeocodingService({http.Client? client, Uri? endpoint})
      : _client = client,
        _endpoint = endpoint;

  final http.Client? _client;
  final Uri? _endpoint;

  Future<List<GeoLocationResult>> search(
    String query, {
    String language = 'en',
  }) async {
    final normalized = query.trim();
    if (normalized.length < 3) return const [];

    final endpoint = _endpoint ?? ProviderTrustConfig.geocodingEndpoint;
    if (endpoint == null) {
      throw StateError(
        'Geocoding provider is not configured for commercial distribution.',
      );
    }

    final client = _client ?? http.Client();
    final uri = endpoint.replace(
      queryParameters: {
        ...endpoint.queryParameters,
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
        throw StateError('Geocoding provider responded ${response.statusCode}');
      }
      if (response.bodyBytes.length > 1024 * 1024) {
        throw StateError('Geocoding response exceeded safety limit');
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
