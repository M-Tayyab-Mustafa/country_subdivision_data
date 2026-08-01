import 'semantic_version.dart';

enum MaintenanceTrigger { none, flutter, data, combined }

MaintenanceTrigger decideMaintenance({
  required SemanticVersion pinnedFlutter,
  required SemanticVersion latestFlutter,
  required bool upstreamCommitChanged,
  required bool publishableDataChanged,
  required bool upstreamValid,
}) {
  final flutter = latestFlutter.compareTo(pinnedFlutter) > 0;
  final data = upstreamCommitChanged && publishableDataChanged && upstreamValid;
  if (flutter && data) {
    return MaintenanceTrigger.combined;
  }
  if (flutter) {
    return MaintenanceTrigger.flutter;
  }
  if (data) {
    return MaintenanceTrigger.data;
  }
  return MaintenanceTrigger.none;
}
