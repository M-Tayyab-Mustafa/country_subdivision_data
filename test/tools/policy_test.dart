import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/maintenance_policy.dart';
import '../../tool/src/semantic_version.dart';

void main() {
  group('custom package version policy', () {
    const cases = <String, String>{
      '0.0.1': '0.0.2',
      '0.0.8': '0.0.9',
      '0.0.9': '0.1.0',
      '0.1.9': '0.2.0',
      '0.9.9': '1.0.0',
      '1.9.9': '2.0.0',
      '9.9.9': '10.0.0',
    };
    for (final entry in cases.entries) {
      test('${entry.key} rolls to ${entry.value}', () {
        expect(
          SemanticVersion.parse(
            entry.key,
            enforcePackagePolicy: true,
          ).nextPackageVersion.toString(),
          entry.value,
        );
      });
    }

    test('rejects invalid, prerelease, metadata, and out-of-policy values', () {
      for (final value in <String>[
        'v1.2.3',
        '1.2.3-beta',
        '1.2.3+4',
        '0.0.10',
        '0.10.0',
      ]) {
        expect(
          () => SemanticVersion.parse(value, enforcePackagePolicy: true),
          throwsFormatException,
        );
      }
    });
  });

  group('monthly decision matrix', () {
    final pinned = SemanticVersion.parse('3.38.0');

    test('same, minor, patch, and downgrade releases are ignored', () {
      for (final remote in <String>[
        '3.38.0',
        '3.39.0',
        '3.38.1',
        '2.99.0',
      ]) {
        expect(
          decideMaintenance(
            pinnedFlutter: pinned,
            latestFlutter: SemanticVersion.parse(remote),
            upstreamCommitChanged: false,
            publishableDataChanged: false,
            upstreamValid: true,
          ),
          MaintenanceTrigger.none,
        );
      }
    });

    test('new major creates a Flutter-only release', () {
      expect(
        decideMaintenance(
          pinnedFlutter: pinned,
          latestFlutter: SemanticVersion.parse('4.2.1'),
          upstreamCommitChanged: false,
          publishableDataChanged: false,
          upstreamValid: true,
        ),
        MaintenanceTrigger.flutter,
      );
    });

    test('meaningful verified upstream data creates a data release', () {
      expect(
        decideMaintenance(
          pinnedFlutter: pinned,
          latestFlutter: SemanticVersion.parse('3.41.0'),
          upstreamCommitChanged: true,
          publishableDataChanged: true,
          upstreamValid: true,
        ),
        MaintenanceTrigger.data,
      );
    });

    test('combined changes create exactly one combined release', () {
      expect(
        decideMaintenance(
          pinnedFlutter: pinned,
          latestFlutter: SemanticVersion.parse('4.2.1'),
          upstreamCommitChanged: true,
          publishableDataChanged: true,
          upstreamValid: true,
        ),
        MaintenanceTrigger.combined,
      );
    });

    test('invalid or identical generated upstream data is ignored', () {
      for (final valid in <bool>[true, false]) {
        expect(
          decideMaintenance(
            pinnedFlutter: pinned,
            latestFlutter: SemanticVersion.parse('3.41.0'),
            upstreamCommitChanged: true,
            publishableDataChanged: false,
            upstreamValid: valid,
          ),
          MaintenanceTrigger.none,
        );
      }
    });

    test('major components compare numerically', () {
      const cases = <(String, String, bool)>[
        ('3.41.0', '4.0.0', true),
        ('9.9.9', '10.0.0', true),
        ('10.1.0', '10.9.0', false),
        ('10.1.0', '11.0.0', true),
      ];
      for (final value in cases) {
        expect(
          SemanticVersion.parse(value.$2).major >
              SemanticVersion.parse(value.$1).major,
          value.$3,
        );
      }
    });
  });
}
