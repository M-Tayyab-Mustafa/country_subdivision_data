/// Thrown when bundled JSON does not match the normalized snapshot schema.
class CountrySubdivisionDataFormatException implements Exception {
  /// Creates a data-format exception.
  const CountrySubdivisionDataFormatException(
    this.message, {
    this.asset,
    this.countryCode,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable failure description.
  final String message;

  /// Asset identifier, when relevant.
  final String? asset;

  /// Country being decoded, when relevant.
  final String? countryCode;

  /// Underlying failure, when available.
  final Object? cause;

  /// Underlying stack trace, when available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'CountrySubdivisionDataFormatException: $message'
      '${asset == null ? '' : ' [asset: $asset]'}'
      '${countryCode == null ? '' : ' [country: $countryCode]'}'
      '${cause == null ? '' : ' (cause: $cause)'}';
}
