import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/secure_session_store.dart';
import 'package:schedulr/features/import_timetable/data/bitc_cookie_store.dart';

void main() {
  late _MemorySecureAdapter adapter;
  late _FakeCookieBridge bridge;
  late BitcCookieStore store;

  setUp(() {
    adapter = _MemorySecureAdapter();
    bridge = _FakeCookieBridge();
    store = BitcCookieStore(adapter: adapter, platform: bridge);
  });

  test('captures and restores cookies independently per account', () async {
    bridge.cookies = [_cookie('session-a', 'a')];
    await store.capture('student-a');
    bridge.cookies = [_cookie('session-b', 'b')];
    await store.capture('student-b');

    bridge.cookies = [];
    expect(await store.restore('student-a'), isTrue);
    expect(bridge.cookies.single['value'], 'a');
    expect(await store.restore('student-b'), isTrue);
    expect(bridge.cookies.single['value'], 'b');
  });

  test(
    'rejects non-BITC cookies and never stores password-shaped fields',
    () async {
      bridge.cookies = [
        _cookie('session', 'safe'),
        {'name': 'other', 'value': 'x', 'domain': 'example.com', 'path': '/'},
      ];
      expect(() => store.capture('student-a'), throwsFormatException);
      expect(adapter.values, isEmpty);
    },
  );

  test('corrupt records are removed without affecting other accounts', () async {
    bridge.cookies = [_cookie('session-a', 'a')];
    await store.capture('student-a');
    final studentBKey =
        'schedulr.secure.bitc.cookie.v1.${sha256.convert('student-b'.codeUnits)}';
    adapter.values[studentBKey] = 'bad';

    expect(await store.restore('student-b'), isFalse);
    final studentAKey =
        'schedulr.secure.bitc.cookie.v1.${sha256.convert('student-a'.codeUnits)}';
    expect(adapter.values.keys, contains(studentAKey));
    await store.deleteAll();
    expect(adapter.values, isEmpty);
  });
}

Map<String, Object?> _cookie(String name, String value) => {
  'name': name,
  'value': value,
  'domain': 'jwxt.vpn.bitc.edu.cn',
  'path': '/',
  'secure': true,
};

final class _FakeCookieBridge implements BitcCookiePlatformBridge {
  List<Map<String, Object?>> cookies = [];

  @override
  Future<void> clearCookies() async => cookies = [];

  @override
  Future<List<Map<String, Object?>>> readCookies() async => cookies;

  @override
  Future<void> writeCookies(List<Map<String, Object?>> value) async {
    cookies = value;
  }
}

final class _MemorySecureAdapter implements SecureKeyValueAdapter {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(values);

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
