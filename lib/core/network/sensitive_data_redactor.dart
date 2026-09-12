abstract final class SensitiveDataRedactor {
  static const _sensitiveKeys = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'password',
    'passwd',
    'token',
    'access_token',
    'refresh_token',
    'username',
    'student_id',
  };

  static Map<String, Object?> redactMap(Map<String, Object?> source) {
    return source.map((key, value) {
      final normalizedKey = key.toLowerCase();
      if (_sensitiveKeys.any(normalizedKey.contains)) {
        return MapEntry(key, '[REDACTED]');
      }
      if (value is Map<String, Object?>) {
        return MapEntry(key, redactMap(value));
      }
      return MapEntry(key, value);
    });
  }
}
