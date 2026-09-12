import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  const SecureSessionStore({this.storage = const FlutterSecureStorage()});

  final FlutterSecureStorage storage;

  Future<String?> read(String key) => storage.read(key: key);

  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  Future<void> delete(String key) => storage.delete(key: key);

  Future<void> clear() => storage.deleteAll();
}
