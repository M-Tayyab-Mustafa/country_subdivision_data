import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final executable =
      flutterRoot == null ? 'dart' : '$flutterRoot/bin/cache/dart-sdk/bin/dart';
  final fixture = 'test/fixtures/flutter/releases.json';

  Future<ProcessResult> run(
    String command, {
    String metadata = 'test/fixtures/flutter/releases.json',
  }) =>
      Process.run(
          executable,
          <String>[
            'run',
            'tool/flutter_sdk_manager.dart',
            command,
            '--metadata',
            metadata,
          ],
          workingDirectory: Directory.current.path);

  test('parses official metadata and selects only current stable', () async {
    final result = await run('latest');
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Latest stable Flutter: 4.2.1'));
    expect(result.stdout, isNot(contains('5.0.0-0.1.pre')));
  });

  test('check compares the complete semantic version', () async {
    final pinned = File('.flutter-version').readAsStringSync().trim();
    final components = pinned.split('.').map(int.parse).toList();
    final newerPatch = '${components[0]}.${components[1]}.${components[2] + 1}';
    final temporary =
        File('${Directory.systemTemp.path}/flutter-release-patch-$pid.json')
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'current_release': <String, Object?>{'stable': 'stable-hash'},
              'releases': <Object?>[
                <String, Object?>{
                  'hash': 'stable-hash',
                  'channel': 'stable',
                  'version': newerPatch,
                  'release_date': '2026-07-01T00:00:00Z',
                },
              ],
            }),
          );
    try {
      final result = await run('check', metadata: temporary.path);
      expect(result.exitCode, 10);
      expect(result.stdout, contains('Pinned: $pinned'));
      expect(result.stdout, contains('Latest: $newerPatch'));
      expect(result.stdout, contains('Action: update'));
    } finally {
      temporary.deleteSync();
    }
  });

  test('malformed metadata fails closed without network access', () async {
    final temporary = File(
      '${Directory.systemTemp.path}/flutter-release-malformed.json',
    )..writeAsStringSync('{}');
    try {
      final result = await run('latest', metadata: temporary.path);
      expect(result.exitCode, 20);
      expect(result.stderr, contains('Stable Flutter release metadata'));
    } finally {
      temporary.deleteSync();
    }
  });

  test('update dry run does not alter the pin', () async {
    final before = File('.flutter-version').readAsStringSync();
    final result = await Process.run(
        executable,
        <String>[
          'run',
          'tool/flutter_sdk_manager.dart',
          'update',
          '--metadata',
          fixture,
          '--dry-run',
        ],
        workingDirectory: Directory.current.path);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Dry run'));
    expect(File('.flutter-version').readAsStringSync(), before);
  });
}
