import 'dart:convert';
import 'dart:io';

Never _usageError(String message) {
  stderr.writeln(message);
  exitCode = 64;
  throw FormatException(message);
}

Map<String, String?> parseOptions(
  List<String> arguments, {
  Set<String> flags = const <String>{},
}) {
  final result = <String, String?>{};
  for (var index = 0; index < arguments.length; index += 1) {
    final argument = arguments[index];
    if (!argument.startsWith('--')) {
      _usageError('Unexpected argument: $argument');
    }
    final name = argument.substring(2);
    if (flags.contains(name)) {
      result[name] = null;
      continue;
    }
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      _usageError('Missing value for --$name');
    }
    result[name] = arguments[++index];
  }
  return result;
}

Map<String, Object?> readJsonMap(File file) {
  final value = jsonDecode(file.readAsStringSync());
  if (value is! Map<Object?, Object?>) {
    throw FormatException('${file.path} must contain a JSON object.');
  }
  return value.map(
    (key, item) => MapEntry<String, Object?>(key.toString(), item),
  );
}

List<Object?> readJsonList(File file) {
  final value = jsonDecode(file.readAsStringSync());
  if (value is! List<Object?>) {
    throw FormatException('${file.path} must contain a JSON array.');
  }
  return value;
}

Map<String, Object?> objectMap(Object? value, String context) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$context must be a JSON object.');
  }
  return value.map(
    (key, item) => MapEntry<String, Object?>(key.toString(), item),
  );
}

String prettyJson(Object? value) =>
    '${const JsonEncoder.withIndent('  ').convert(value)}\n';

String? nullableText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

double? nullableNumber(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return value is String ? double.tryParse(value.trim()) : null;
}

int integer(Object? value, String context) {
  if (value is int) {
    return value;
  }
  if (value is num && value == value.roundToDouble()) {
    return value.toInt();
  }
  final parsed = value is String ? int.tryParse(value.trim()) : null;
  if (parsed == null) {
    throw FormatException('$context requires an integer.');
  }
  return parsed;
}

String text(Object? value, String context) {
  final parsed = nullableText(value);
  if (parsed == null) {
    throw FormatException('$context requires a non-empty string.');
  }
  return parsed;
}

String normalizeForSort(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String runGit(List<String> arguments, {required String workingDirectory}) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw StateError(
      'git ${arguments.join(' ')} failed: ${result.stderr.toString().trim()}',
    );
  }
  return result.stdout.toString().trim();
}
