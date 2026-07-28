/// Thrown when the package cannot initialize its snapshot repository.
class CountrySubdivisionInitializationException implements Exception {
  /// Creates an initialization exception.
  const CountrySubdivisionInitializationException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Human-readable failure description.
  final String message;

  /// Underlying failure, when available.
  final Object? cause;

  /// Underlying stack trace, when available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'CountrySubdivisionInitializationException: $message'
      '${cause == null ? '' : ' (cause: $cause)'}';
}
