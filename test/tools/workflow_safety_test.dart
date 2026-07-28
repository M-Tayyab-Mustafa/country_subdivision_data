import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String monthly;
  late String publish;

  setUpAll(() {
    monthly = File(
      '.github/workflows/monthly_maintenance.yml',
    ).readAsStringSync();
    publish = File('.github/workflows/publish.yml').readAsStringSync();
  });

  test('monthly release uses GitHub App authentication and race checks', () {
    expect(monthly, contains('actions/create-github-app-token@v2'));
    expect(monthly, contains('RELEASE_APP_PRIVATE_KEY'));
    expect(monthly, contains(r'origin/$DEFAULT_BRANCH'));
    expect(monthly, contains('START_SHA'));
    expect(monthly, isNot(contains('--force')));
  });

  test('monthly release exits before versioning when no change exists', () {
    final decision = monthly.indexOf('No eligible update');
    final bump = monthly.indexOf('tool/version_manager.dart bump');
    expect(decision, greaterThan(0));
    expect(bump, greaterThan(decision));
    expect(monthly, contains('eligible=false'));
  });

  test('publication is tag-only and uses OIDC without credentials', () {
    expect(publish, contains("'v[0-9]+.[0-9]+.[0-9]+'"));
    expect(publish, isNot(contains('workflow_dispatch')));
    expect(publish, isNot(contains('schedule:')));
    expect(publish, contains('id-token: write'));
    expect(
      publish,
      contains('dart-lang/setup-dart/.github/workflows/publish.yml@v1'),
    );
    expect(publish, isNot(contains('pub-credentials.json')));
    expect(publish, isNot(contains('--skip-validation')));
  });

  test('publication verifies identity and reports failures', () {
    expect(publish, contains('tool/version_manager.dart verify --tag'));
    expect(publish, contains('git merge-base --is-ancestor'));
    expect(publish, contains('Refuse an already-published version'));
    expect(publish, contains('always() && failure()'));
    expect(publish, contains('gh issue create'));
    expect(publish, contains('gh release create'));
  });
}
