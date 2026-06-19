import 'package:camperboss/core/services/gpx_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = GpxService();

  test('parses tracks, routes, and waypoints from GPX', () async {
    const gpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="test">
  <trk>
    <name>Alps track</name>
    <trkseg>
      <trkpt lat="45.0000" lon="10.0000"><ele>100</ele><time>2026-06-01T10:00:00Z</time></trkpt>
      <trkpt lat="45.0100" lon="10.0100"><ele>125</ele><time>2026-06-01T10:10:00Z</time></trkpt>
    </trkseg>
  </trk>
  <rte>
    <name>Lake route</name>
    <rtept lat="45.0200" lon="10.0200" />
    <rtept lat="45.0300" lon="10.0300" />
  </rte>
  <wpt lat="45.0400" lon="10.0400">
    <name>Photo stop</name>
    <desc>Nice view</desc>
    <time>2026-06-01T11:00:00Z</time>
  </wpt>
</gpx>
''';

    final bundle = await service.parse(gpx, tripId: 7);

    expect(bundle.tracks, hasLength(2));
    expect(bundle.tracks.first.tripId, 7);
    expect(bundle.tracks.first.name, 'Alps track');
    expect(bundle.tracks.first.distanceMeters, greaterThan(0));
    expect(bundle.tracks.first.duration, const Duration(minutes: 10));
    expect(bundle.memories, hasLength(1));
    expect(bundle.memories.single.title, 'Photo stop');
    expect(bundle.memories.single.description, 'Nice view');
  });

  test('rejects malformed xml', () async {
    await expectLater(
      () => service.parse('<gpx><trk></gpx>'),
      throwsA(isA<GpxValidationException>()),
    );
  });

  test('rejects invalid coordinates', () async {
    const gpx = '''
<gpx version="1.1" creator="test">
  <trk><trkseg><trkpt lat="145.0" lon="10.0" /></trkseg></trk>
</gpx>
''';

    await expectLater(
      () => service.parse(gpx),
      throwsA(isA<GpxValidationException>()),
    );
  });

  test('exports track and can reimport it', () async {
    const source = '''
<gpx version="1.1" creator="test">
  <trk>
    <name>Roundtrip</name>
    <trkseg>
      <trkpt lat="45.0" lon="10.0"><time>2026-06-01T10:00:00Z</time></trkpt>
      <trkpt lat="45.1" lon="10.1"><time>2026-06-01T11:00:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

    final parsed = await service.parse(source, tripId: 3);
    final exported = service.exportTrack(parsed.tracks.single);
    final reparsed = await service.parse(exported, tripId: 3);

    expect(reparsed.tracks, hasLength(1));
    expect(reparsed.tracks.single.name, 'Roundtrip');
    expect(reparsed.tracks.single.points, hasLength(2));
  });
}
