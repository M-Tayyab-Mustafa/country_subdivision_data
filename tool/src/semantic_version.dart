final class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch);

  factory SemanticVersion.parse(
    String value, {
    bool enforcePackagePolicy = false,
  }) {
    final match = RegExp(r'^([0-9]+)\.([0-9]+)\.([0-9]+)$').firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid semantic version: $value');
    }
    final version = SemanticVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (enforcePackagePolicy && (version.minor > 9 || version.patch > 9)) {
      throw FormatException(
        'Package minor and patch components must be between 0 and 9.',
      );
    }
    return version;
  }

  final int major;
  final int minor;
  final int patch;

  SemanticVersion get nextPackageVersion {
    if (patch < 9) {
      return SemanticVersion(major, minor, patch + 1);
    }
    if (minor < 9) {
      return SemanticVersion(major, minor + 1, 0);
    }
    return SemanticVersion(major + 1, 0, 0);
  }

  @override
  int compareTo(SemanticVersion other) {
    final majorComparison = major.compareTo(other.major);
    if (majorComparison != 0) {
      return majorComparison;
    }
    final minorComparison = minor.compareTo(other.minor);
    return minorComparison != 0
        ? minorComparison
        : patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
