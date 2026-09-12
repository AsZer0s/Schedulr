sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message, {super.cause});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

final class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure(super.message, {super.cause});
}

final class UnsupportedIntegrationFailure extends AppFailure {
  const UnsupportedIntegrationFailure(super.message, {super.cause});
}
