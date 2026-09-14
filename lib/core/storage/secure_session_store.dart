import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _deviceSecureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  ),
);

/// Minimal secure key/value API used by storage services.
///
/// Keeping this boundary abstract allows storage code to be tested without
/// invoking platform channels.
abstract interface class SecureKeyValueAdapter {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<Map<String, String>> readAll();
}

final class FlutterSecureStorageAdapter implements SecureKeyValueAdapter {
  const FlutterSecureStorageAdapter([this.storage = _deviceSecureStorage]);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);

  @override
  Future<Map<String, String>> readAll() => storage.readAll();
}

/// Secure storage for small, non-secret session metadata.
class SecureSessionStore {
  const SecureSessionStore({this.storage = _deviceSecureStorage, this.adapter});

  final FlutterSecureStorage storage;
  final SecureKeyValueAdapter? adapter;

  SecureKeyValueAdapter get _keyValueStore =>
      adapter ?? FlutterSecureStorageAdapter(storage);

  Future<String?> read(String key) => _keyValueStore.read(key);

  Future<void> write(String key, String value) =>
      _keyValueStore.write(key, value);

  Future<void> delete(String key) => _keyValueStore.delete(key);

  Future<Map<String, String>> readAll() => _keyValueStore.readAll();

  /// Legacy global clear. Account storage deliberately does not use this API.
  Future<void> clear() => storage.deleteAll();

  static const currentWebSessionAccountKey =
      'schedulr.secure.bitc.web-session-account.v1';

  /// Records the account identifier currently authenticated in the WebView.
  /// No cookie, token, password, or other credential is accepted or stored.
  Future<void> markCurrentWebSessionAccount(String accountId) async {
    final normalized = _validateAccountId(accountId);
    await write(currentWebSessionAccountKey, normalized);
  }

  Future<String?> readCurrentWebSessionAccount() async {
    final value = await read(currentWebSessionAccountKey);
    if (value == null) return null;
    try {
      return _validateAccountId(value);
    } on ArgumentError {
      await clearCurrentWebSessionAccount();
      return null;
    }
  }

  Future<void> clearCurrentWebSessionAccount() =>
      delete(currentWebSessionAccountKey);

  static String _validateAccountId(String accountId) {
    final value = accountId.trim();
    if (value.isEmpty || value.length > 256) {
      throw ArgumentError.value(accountId, 'accountId', 'Invalid account ID.');
    }
    if (value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
      throw ArgumentError.value(accountId, 'accountId', 'Invalid account ID.');
    }
    return value;
  }
}
