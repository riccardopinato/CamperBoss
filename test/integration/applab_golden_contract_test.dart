import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLab Golden integration stays immutable and fail-closed', () {
    final workflow = File('.github/workflows/applab.yml').readAsStringSync();
    final config = jsonDecode(
      File('applab.project.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(
      workflow,
      contains(
        'external-project-runner.yml@'
        '931c124dbb1a36d43842db5b60bd5f04843e5330',
      ),
    );
    expect(workflow, contains('analysis_mode: full'));
    expect(workflow, contains('flutter_version: "3.47.6"'));
    expect(workflow, contains('java_version: "21"'));
    expect(
      workflow,
      contains(
        'apk_path: '
        'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
      ),
    );
    expect(workflow, contains('package_id: com.camperboss.camperboss'));
    expect(
      workflow,
      contains('maestro_flow: .maestro/applab-release-core-final.yaml'),
    );
    expect(workflow, contains('cache_verification: false'));
    expect(workflow, contains('publish_release_artifact: false'));

    expect(config['schema_version'], 1);
    expect(config['project_type'], 'flutter');
    expect(config['working_directory'], '.');
    expect(config['package_id'], 'com.camperboss.camperboss');

    final toolchain = config['toolchain'] as Map<String, dynamic>;
    expect(toolchain['flutter_version'], '3.47.6');
    expect(toolchain['java_version'], '21');

    expect(
      config['release_artifact_pattern'],
      'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
    );

    final journeys = config['journeys'] as Map<String, dynamic>;
    expect(
      journeys['primary'],
      '.maestro/applab-release-core-final.yaml',
    );

    final physical = config['physical_validation'] as Map<String, dynamic>;
    expect(physical['required'], isTrue);
    expect(
      physical['capabilities'],
      containsAll(<String>[
        'gps',
        'background',
        'camera',
        'scanner',
        'notifications',
        'storage',
        'file_picker',
        'play_delivery',
      ]),
    );
  });
}
