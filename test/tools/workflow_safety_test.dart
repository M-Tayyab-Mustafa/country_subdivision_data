import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String ci;
  late String monthly;
  late String refreshMonthly;
  late String tagMergedRelease;
  late String publish;
  late String setupFlutter;
  late String verify;
  late String publishDryRun;
  late Map<String, Object?> mainRules;
  late Map<String, Object?> immutableTagRules;

  setUpAll(() {
    ci = File('.github/workflows/ci.yml').readAsStringSync();
    monthly = File(
      '.github/workflows/monthly_maintenance.yml',
    ).readAsStringSync();
    refreshMonthly = File(
      '.github/workflows/update_monthly_maintenance.yml',
    ).readAsStringSync();
    tagMergedRelease = File(
      '.github/workflows/tag_merged_release.yml',
    ).readAsStringSync();
    publish = File('.github/workflows/publish.yml').readAsStringSync();
    setupFlutter = File(
      '.github/actions/setup-flutter/action.yml',
    ).readAsStringSync();
    verify = File('.github/scripts/verify.sh').readAsStringSync();
    publishDryRun = File(
      '.github/scripts/check_publish_dry_run.sh',
    ).readAsStringSync();
    mainRules = _json('.github/rulesets/main.json');
    immutableTagRules = _json('.github/rulesets/release-tags-immutable.json');
  });

  test('CI exposes every required check without merge queue events', () {
    const checks = <String>[
      'Formatting',
      'Static analysis',
      'Unit and integration tests',
      'Snapshot validation',
      'Nigeria regression validation',
      'Deterministic-generation validation',
      'Flutter SDK verification',
      'Upstream metadata verification',
      'Version-policy verification',
      'Release-review verification',
      'pub.dev publication dry-run',
    ];
    expect(ci, isNot(contains('merge_group:')));
    for (final check in checks) {
      expect(ci, contains('name: $check'), reason: check);
    }
  });

  test('workflows install the exact repository Flutter pin', () {
    for (final workflow in <String>[
      ci,
      monthly,
      publish,
      tagMergedRelease,
    ]) {
      expect(workflow, contains('uses: ./.github/actions/setup-flutter'));
      expect(workflow, isNot(contains('subosito/flutter-action')));
      expect(workflow, isNot(contains('flutter-version-file:')));
    }
    expect(setupFlutter, contains("< .flutter-version"));
    expect(
      setupFlutter,
      contains(r'flutter-version: ${{ steps.pin.outputs.version }}'),
    );
    expect(setupFlutter, contains('channel: stable'));
  });

  test('monthly maintenance pushes only its PR branch', () {
    expect(monthly, contains('actions/create-github-app-token@v3'));
    expect(monthly, contains('flutter_sdk_manager.dart check 2>&1'));
    expect(monthly, isNot(contains('check-major')));
    expect(monthly, contains('RELEASE_APP_PRIVATE_KEY'));
    expect(monthly, contains('automation/monthly-maintenance'));
    expect(monthly, contains('gh pr create'));
    expect(monthly, contains('--auto --squash'));
    expect(monthly, contains('--force-with-lease='));
    expect(monthly, isNot(contains('HEAD:main')));
    expect(monthly, isNot(contains(r'HEAD:$DEFAULT_BRANCH')));
    expect(monthly, isNot(contains('refs/tags/v')));
  });

  test('main updates refresh the monthly branch and preserve auto-merge', () {
    expect(refreshMonthly, contains('push:'));
    expect(refreshMonthly, contains('- main'));
    expect(refreshMonthly, contains('--head automation/monthly-maintenance'));
    expect(refreshMonthly, contains('gh pr update-branch'));
    expect(refreshMonthly, contains('--auto --squash'));
    expect(refreshMonthly, isNot(contains('HEAD:main')));
  });

  test('monthly maintenance performs exactly one version bump', () {
    expect(
      RegExp(r'tool/version_manager\.dart bump').allMatches(monthly).length,
      1,
    );
    final decision = monthly.indexOf('No eligible update');
    final bump = monthly.indexOf('tool/version_manager.dart bump');
    expect(decision, greaterThan(0));
    expect(bump, greaterThan(decision));
    expect(monthly, contains('eligible=false'));
  });

  test('unchanged upstream data keeps deterministic validation aligned', () {
    expect(
      monthly,
      contains(
        'git -C .tool_work/upstream fetch --depth=1 origin '
        r'"$current_commit"',
      ),
    );
    expect(
      monthly,
      contains(
        'git -C .tool_work/upstream checkout --detach FETCH_HEAD',
      ),
    );
  });

  test('Flutter maintenance formats with the selected SDK before validation',
      () {
    final install = monthly.indexOf('Install selected Flutter pin');
    final format = monthly.indexOf(
      'Format sources with the selected Flutter SDK',
    );
    final validation = monthly.indexOf('Pre-version verification');
    expect(install, greaterThan(0));
    expect(format, greaterThan(install));
    expect(validation, greaterThan(format));
    expect(monthly, contains("outputs.trigger == 'flutter'"));
    expect(monthly, contains("outputs.trigger == 'combined'"));
    expect(monthly, contains('run: dart format .'));
  });

  test('maintenance validates a clean copy of the uncommitted candidate', () {
    expect(verify, contains('check_publish_dry_run.sh'));
    expect(verify, isNot(contains('dart pub publish --dry-run')));
    expect(publishDryRun, contains('git rev-parse --show-toplevel'));
    expect(publishDryRun, contains(r'git -C "$repository" ls-files'));
    expect(publishDryRun, contains('--cached'));
    expect(publishDryRun, contains('--others'));
    expect(publishDryRun, contains('--exclude-standard'));
    expect(publishDryRun, contains(r'git -C "$candidate" add --all'));
    expect(publishDryRun, contains('commit --quiet --allow-empty'));
    expect(
      publishDryRun,
      contains('dart pub publish --dry-run'),
    );
    expect(publishDryRun, isNot(contains('--ignore-warnings')));
    expect(publishDryRun, isNot(contains('--skip-validation')));
  });

  test('release tag is created only after the maintenance PR is merged', () {
    expect(tagMergedRelease, contains('branches:'));
    expect(tagMergedRelease, contains('- main'));
    expect(tagMergedRelease, contains('.merged_at != null'));
    expect(
      tagMergedRelease,
      contains('.head.ref == "automation/monthly-maintenance"'),
    );
    expect(tagMergedRelease, contains('git merge-base --is-ancestor'));
    expect(
      tagMergedRelease,
      contains(r'git push origin "refs/tags/v$VERSION"'),
    );
    expect(tagMergedRelease, isNot(contains('HEAD:main')));
  });

  test('main ruleset has no bypass and requires policy checks', () {
    expect(mainRules['enforcement'], 'active');
    expect(mainRules['target'], 'branch');
    expect(mainRules['bypass_actors'], isEmpty);
    final rules = mainRules['rules']! as List<Object?>;
    final types =
        rules.cast<Map<String, Object?>>().map((rule) => rule['type']).toSet();
    expect(
      types,
      containsAll(<String>{
        'deletion',
        'non_fast_forward',
        'required_linear_history',
        'pull_request',
        'required_status_checks',
      }),
    );
    expect(types, isNot(contains('merge_queue')));
    final pullRequest = rules.cast<Map<String, Object?>>().singleWhere(
          (rule) => rule['type'] == 'pull_request',
        );
    final parameters = pullRequest['parameters']! as Map<String, Object?>;
    expect(parameters['allowed_merge_methods'], <String>['squash']);
    expect(parameters['required_approving_review_count'], 0);
    expect(parameters['required_review_thread_resolution'], true);
    final requiredChecks = rules.cast<Map<String, Object?>>().singleWhere(
          (rule) => rule['type'] == 'required_status_checks',
        );
    final checkParameters =
        requiredChecks['parameters']! as Map<String, Object?>;
    expect(checkParameters['strict_required_status_checks_policy'], true);
  });

  test('immutable release tags have no update or deletion bypass', () {
    expect(immutableTagRules['enforcement'], 'active');
    expect(immutableTagRules['target'], 'tag');
    expect(immutableTagRules['bypass_actors'], isEmpty);
    final rules = immutableTagRules['rules']! as List<Object?>;
    final types =
        rules.cast<Map<String, Object?>>().map((rule) => rule['type']).toSet();
    expect(
      types,
      containsAll(<String>{'update', 'deletion', 'non_fast_forward'}),
    );
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
    expect(publish, contains('grep -Fx'));
    expect(publish, isNot(contains(r'rg "^# country_subdivision_data')));
    expect(publish, contains('Refuse an already-published version'));
    expect(publish, contains('always() && failure()'));
    expect(publish, contains('gh label create automated-release-failure'));
    expect(publish, contains('gh label create pub-dev'));
    expect(publish, contains('gh label create maintenance'));
    expect(publish, contains('gh issue create'));
    expect(publish, contains('gh release create'));
  });
}

Map<String, Object?> _json(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}
