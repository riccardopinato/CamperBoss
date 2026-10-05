import 'dart:convert';
import 'dart:io';

import 'package:camperboss/core/services/gpx_service.dart';
import 'package:camperboss/core/services/local_search_service.dart';
import 'package:camperboss/data/database/local_key_value_store_base.dart';
import 'package:camperboss/data/models/camper_place.dart';
import 'package:camperboss/data/models/search_models.dart';
import 'package:camperboss/features/map/domain/maplibre_poi_clusterer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final metrics = <String, Object?>{};

  tearDownAll(() async {
    final dir = Directory('build/evidence');
    await dir.create(recursive: true);
    await File('${dir.path}/performance-baseline.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'profile': 'CI regression smoke',
        'note':
            'Wall-clock thresholds are intentionally broad and detect severe regressions, not device certification.',
        ...metrics,
      }),
    );
  });

  test('clusters 10k POIs within broad CI regression budget', () {
    final places = List.generate(
      10000,
      (i) => CamperPlace(
        id: 'poi-$i',
        name: 'POI $i',
        category: i.isEven ? 'sosta' : 'camping',
        type: 'test',
        distance: '',
        rating: '',
        tags: const [],
        latitude: 44.0 + (i % 200) * 0.002,
        longitude: 10.0 + (i ~/ 200) * 0.002,
      ),
      growable: false,
    );

    final sw = Stopwatch()..start();
    final clusters =
        const MapLibrePoiClusterer().cluster(places: places, zoom: 11);
    sw.stop();

    metrics['poiCluster10kMs'] = sw.elapsedMilliseconds;
    expect(clusters, isNotEmpty);
    expect(
      clusters.fold<int>(0, (sum, cluster) => sum + cluster.count),
      places.length,
    );
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('parses and simplifies a 5k point GPX within regression budget', () async {
    final buffer = StringBuffer(
      '<?xml version="1.0"?><gpx version="1.1"><trk><name>Stress</name><trkseg>',
    );
    for (var i = 0; i < 5000; i++) {
      final lat = 45.0 + i * 0.00001;
      final lon = 11.0 + i * 0.00001;
      buffer.write('<trkpt lat="$lat" lon="$lon"><ele>${100 + i % 20}</ele></trkpt>');
    }
    buffer.write('</trkseg></trk></gpx>');

    final sw = Stopwatch()..start();
    final parsed = await const GpxService().parse(buffer.toString());
    sw.stop();

    final track = parsed.tracks.single;
    metrics['gpxParse5kMs'] = sw.elapsedMilliseconds;
    metrics['gpxOriginalPoints'] = track.originalPointCount;
    metrics['gpxSimplifiedPoints'] = track.points.length;
    expect(track.originalPointCount, 5000);
    expect(track.points.length, lessThanOrEqualTo(5000));
    expect(sw.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('rebuilds and queries 5k local search documents within budget', () async {
    final store = _MemoryStore();
    final docs = List.generate(
      5000,
      (i) => SearchDocument(
        id: 'doc-$i',
        type: SearchDocumentType.journal,
        sourceId: '$i',
        title: 'Camper destination $i',
        body: i % 50 == 0
            ? 'special needle campsite mountains water service'
            : 'ordinary local-first travel note $i',
        metadata: const {},
        updatedAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
      ),
      growable: false,
    );
    final index = PersistentLocalSearchIndex(
      store: store,
      documentLoader: () async => docs,
    );

    final rebuild = Stopwatch()..start();
    await index.rebuild();
    rebuild.stop();

    final query = Stopwatch()..start();
    final hits = await index.search('special campsite', limit: 50);
    query.stop();

    metrics['searchRebuild5kMs'] = rebuild.elapsedMilliseconds;
    metrics['searchQuery5kMs'] = query.elapsedMilliseconds;
    expect((await index.snapshot()).documentCount, 5000);
    expect(hits, isNotEmpty);
    expect(rebuild.elapsed, lessThan(const Duration(seconds: 10)));
    expect(query.elapsed, lessThan(const Duration(seconds: 5)));
  });
}

class _MemoryStore implements LocalKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
