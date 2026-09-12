enum ZfFailureKind {
  invalidCredentials,
  verificationRequired,
  authenticationExpired,
  networkUnavailable,
  endpointRejected,
  malformedResponse,
  unsupportedLayout,
  parseFailed,
  unsupportedProfile,
  unknown,
}

/// Typed integration error. Convert this to TimetableImportException at the
/// importer boundary so UI never needs Zhengfang-specific conditions.
final class ZfException implements Exception {
  const ZfException({
    required this.kind,
    required this.message,
    this.cause,
    this.statusCode,
  });

  final ZfFailureKind kind;
  final String message;
  final Object? cause;
  final int? statusCode;

  @override
  String toString() => 'ZfException($kind, $message)';
}
