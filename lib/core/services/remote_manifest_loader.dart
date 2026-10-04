import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteManifestLoader {
  RemoteManifestLoader({
    required this.uri,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxBytes = 1024 * 1024,
  }) : _client = client ?? http.Client();

  final Uri uri;
  final http.Client _client;
  final Duration timeout;
  final int maxBytes;

  Future<String> load() async {
    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Manifest URL must be absolute HTTPS');
    }

    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'application/json';
    final response = await _client.send(request).timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Manifest request failed (' + response.statusCode.toString() + ')',
      );
    }

    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > maxBytes) {
      throw StateError('Manifest exceeds the configured size limit');
    }

    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > maxBytes) {
        throw StateError('Manifest exceeds the configured size limit');
      }
    }

    return utf8.decode(bytes, allowMalformed: false);
  }

  void close() => _client.close();
}
