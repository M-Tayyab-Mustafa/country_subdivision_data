/// Thrown when a bundled snapshot asset cannot be loaded or decoded.
class CountrySubdivisionAssetException implements Exception {
  /// Creates an asset exception.
  const CountrySubdivisionAssetException(
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

  /// Country being loaded, when relevant.
  final String? countryCode;

  /// Underlying failure, when available.
  final Object? cause;

  /// Underlying stack trace, when available.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'CountrySubdivisionAssetException: $message'
      '${asset == null ? '' : ' [asset: $asset]'}'
      '${countryCode == null ? '' : ' [country: $countryCode]'}'
      '${cause == null ? '' : ' (cause: $cause)'}';
}
