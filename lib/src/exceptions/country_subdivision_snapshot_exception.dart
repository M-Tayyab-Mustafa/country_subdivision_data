/// Thrown when snapshot integrity or provenance validation fails.
class CountrySubdivisionSnapshotException implements Exception {
  /// Creates a snapshot exception.
  const CountrySubdivisionSnapshotException(
    this.message, {
    this.countryCode,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable failure description.
  final String message;

  /// Country associated with the failure, when relevant.
  final String? countryCode;

  /// Underlying failure, when available.
  final Object? cause;

  /// Underlying stack trace, when available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'CountrySubdivisionSnapshotException: $message'
      '${countryCode == null ? '' : ' [country: $countryCode]'}'
      '${cause == null ? '' : ' (cause: $cause)'}';
}
