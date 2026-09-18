import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/secure_session_store.dart';

abstract interface class BitcCookiePlatformBridge {
  Future<List<Map<String, Object?>>> readCookies();

  Future<void> writeCookies(List<Map<String, Object?>> cookies);

  Future<void> clearCookies();
}

final class MethodChannelBitcCookiePlatformBridge
    implements BitcCookiePlatformBridge {
  const MethodChannelBitcCookiePlatformBridge({this.channel = _channel});

  static const MethodChannel _channel = MethodChannel('schedulr/bitc_cookie');

  final MethodChannel channel;

  @override
  Future<List<Map<String, Object?>>> readCookies() async {
    final raw = await channel.invokeMethod<List<dynamic>>('readCookies');
    if (raw == null) return const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((value) => Map<String, Object?>.from(value))
        .toList(growable: false);
  }

  @override
  Future<void> writeCookies(List<Map<String, Object?>> cookies) async {
    await channel.invokeMethod<void>('writeCookies', {'cookies': cookies});
  }

  @override
  Future<void> clearCookies() async {
    await channel.invokeMethod<void>('clearCookies');
  }
}

/// Persists BITC WebView cookies per account in encrypted device storage.
///
/// Cookie values never cross into App Group storage, widget snapshots, logs,
/// or JavaScript. The native bridge only exposes cookies for BITC domains.
final class BitcCookieStore {
  BitcCookieStore({
    SecureKeyValueAdapter? adapter,
    BitcCookiePlatformBridge? platform,
  }) : _secureStore = SecureSessionStore(adapter: adapter),
       _platform = platform ?? const MethodChannelBitcCookiePlatformBridge();

  static const _recordPrefix = 'schedulr.secure.bitc.cookie.v1.';
  static const _maxSnapshotLength = 256 * 1024;
  static const _maxCookies = 128;

  final SecureSessionStore _secureStore;
  final BitcCookiePlatformBridge _platform;

  Future<bool> restore(String accountId) async {
    final raw = await _secureStore.read(_recordKey(accountId));
    if (raw == null) return false;
    try {
      if (raw.length > _maxSnapshotLength) {
        throw const FormatException('cookie snapshot is too large');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const FormatException('invalid cookie record');
      }
      final cookies = _decodeCookies(decoded['cookies']);
      if (cookies.isEmpty) {
        await delete(accountId);
        return false;
      }
      await _platform.clearCookies();
      await _platform.writeCookies(cookies);
      return true;
    } on FormatException {
      await delete(accountId);
      return false;
    } on TypeError {
      await delete(accountId);
      return false;
    }
  }

  Future<void> capture(String accountId) async {
    final cookies = _sanitize(await _platform.readCookies());
    if (cookies.isEmpty) return;
    await _secureStore.write(
      _recordKey(accountId),
      jsonEncode(<String, Object?>{'version': 1, 'cookies': cookies}),
    );
  }

  Future<void> delete(String accountId) =>
      _secureStore.delete(_recordKey(accountId));

  Future<void> deleteAll() async {
    final keys = (await _secureStore.readAll()).keys.where(
      (key) => key.startsWith(_recordPrefix),
    );
    for (final key in keys) {
      await _secureStore.delete(key);
    }
  }

  Future<void> clearBrowserSession() async {
    try {
      await _platform.clearCookies().timeout(const Duration(milliseconds: 250));
    } on Object {
      // Desktop/widget tests and hosts without the native bridge can continue.
    }
  }

  String _recordKey(String accountId) {
    final normalized = _validateAccountId(accountId);
    final digest = sha256.convert(utf8.encode(normalized)).toString();
    return '$_recordPrefix$digest';
  }

  List<Map<String, Object?>> _decodeCookies(Object? raw) {
    if (raw is! List || raw.length > _maxCookies) {
      throw const FormatException('invalid cookie list');
    }
    return raw
        .map((value) {
          if (value is! Map) throw const FormatException('invalid cookie');
          return _sanitizeCookie(Map<String, Object?>.from(value));
        })
        .toList(growable: false);
  }

  List<Map<String, Object?>> _sanitize(List<Map<String, Object?>> cookies) {
    if (cookies.length > _maxCookies) {
      throw const FormatException('too many cookies');
    }
    return cookies.map(_sanitizeCookie).toList(growable: false);
  }

  Map<String, Object?> _sanitizeCookie(Map<String, Object?> cookie) {
    final name = cookie['name'];
    final value = cookie['value'];
    final domain = cookie['domain'];
    final origin = cookie['origin'];
    final path = cookie['path'];
    if (name is! String ||
        name.isEmpty ||
        name.length > 256 ||
        value is! String ||
        value.length > 8192 ||
        (domain is! String && origin is! String) ||
        path is! String ||
        path.isEmpty ||
        path.length > 1024) {
      throw const FormatException('invalid cookie fields');
    }
    final normalizedDomain = domain is String ? _validateDomain(domain) : null;
    final normalizedOrigin = origin is String ? _validateOrigin(origin) : null;
    final result = <String, Object?>{
      'name': name,
      'value': value,
      'path': path,
    };
    if (normalizedDomain case final value?) result['domain'] = value;
    if (normalizedOrigin case final value?) result['origin'] = value;
    for (final key in ['expiresAt', 'secure', 'httpOnly']) {
      final candidate = cookie[key];
      if (candidate != null) result[key] = candidate;
    }
    return result;
  }

  String _validateAccountId(String accountId) {
    final value = accountId.trim();
    if (value.isEmpty ||
        value.length > 256 ||
        value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
      throw ArgumentError.value(accountId, 'accountId', 'Invalid account ID.');
    }
    return value;
  }

  String _validateDomain(String domain) {
    final value = domain.trim().toLowerCase();
    final host = value.startsWith('.') ? value.substring(1) : value;
    if (host != 'bitc.edu.cn' && !host.endsWith('.bitc.edu.cn')) {
      throw const FormatException('cookie domain is not allowed');
    }
    return value;
  }

  String _validateOrigin(String origin) {
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'bitc.edu.cn' && !uri.host.endsWith('.bitc.edu.cn'))) {
      throw const FormatException('cookie origin is not allowed');
    }
    return origin;
  }
}
