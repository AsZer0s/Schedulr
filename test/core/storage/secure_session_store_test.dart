import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/secure_session_store.dart';

void main() {
  test('platform manifests keep saved accounts device-local', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final entitlements = File('ios/Runner/Runner.entitlements')
        .readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(entitlements, contains('keychain-access-groups'));
    expect(
      entitlements,
      contains(r'$(AppIdentifierPrefix)app.schedulr.schedulr'),
    );
  });

  test(
    'stores and clears only the current web-session account marker',
    () async {
      final adapter = MemorySecureKeyValueAdapter();
      final store = SecureSessionStore(adapter: adapter);

      await store.markCurrentWebSessionAccount(' student-001 ');

      expect(await store.readCurrentWebSessionAccount(), 'student-001');
      expect(adapter.values, {
        SecureSessionStore.currentWebSessionAccountKey: 'student-001',
      });

      await store.clearCurrentWebSessionAccount();

      expect(adapter.values, isEmpty);
      expect(adapter.deletedKeys, [
        SecureSessionStore.currentWebSessionAccountKey,
      ]);
    },
  );

  test('clears malformed marker and rejects invalid account IDs', () async {
    final adapter = MemorySecureKeyValueAdapter()
      ..values[SecureSessionStore.currentWebSessionAccountKey] = 'bad\naccount';
    final store = SecureSessionStore(adapter: adapter);

    expect(await store.readCurrentWebSessionAccount(), isNull);
    expect(adapter.values, isEmpty);
    expect(() => store.markCurrentWebSessionAccount(''), throwsArgumentError);
  });
}

final class MemorySecureKeyValueAdapter implements SecureKeyValueAdapter {
  final values = <String, String>{};
  final deletedKeys = <String>[];

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    values.remove(key);
  }
}
