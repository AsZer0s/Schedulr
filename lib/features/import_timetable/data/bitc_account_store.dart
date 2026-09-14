import 'dart:convert';

import '../../../core/storage/secure_session_store.dart';
import '../domain/bitc_account.dart';

/// Stores BITC account identifiers and refresh metadata per timetable.
///
/// This class intentionally has no API for passwords, cookies, tokens, or
/// bulk deletion. The secure index is used to enumerate explicit record keys.
class BitcAccountStore {
  BitcAccountStore({
    SecureKeyValueAdapter? adapter,
    SecureSessionStore? secureStore,
  }) : _secureStore = secureStore ?? SecureSessionStore(adapter: adapter);

  static const _indexKey = 'schedulr.secure.bitc.accounts.index.v1';
  static const _recordPrefix = 'schedulr.secure.bitc.account.v1.';
  static const _maxIdLength = 256;

  final SecureSessionStore _secureStore;

  Future<BitcAccount?> read(String timetableId) async {
    final id = _validateId(timetableId, 'timetableId');
    final raw = await _secureStore.read(_recordKey(id));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Record is not an object.');
      }
      final account = BitcAccount.fromJson(decoded.cast<String, Object?>());
      if (account.timetableId != id || !_isValidId(account.accountId)) {
        throw const FormatException('Record identity is invalid.');
      }
      return account;
    } on FormatException {
      await delete(id);
      return null;
    } on TypeError {
      await delete(id);
      return null;
    }
  }

  Future<void> write(BitcAccount account) async {
    final timetableId = _validateId(account.timetableId, 'timetableId');
    final accountId = _validateId(account.accountId, 'accountId');
    if (account.schoolProfileId != BitcAccount.schoolProfileIdValue) {
      throw ArgumentError.value(
        account.schoolProfileId,
        'schoolProfileId',
        'Only BITC Zhengfang V9 is supported.',
      );
    }
    final normalized = BitcAccount(
      accountId: accountId,
      timetableId: timetableId,
      lastSuccessfulRefreshAt: account.lastSuccessfulRefreshAt?.toUtc(),
    );
    final ids = await _readIndex();
    final wasIndexed = ids.contains(timetableId);
    ids.add(timetableId);
    await _writeIndex(ids);
    try {
      await _secureStore.write(
        _recordKey(timetableId),
        jsonEncode(normalized.toJson()),
      );
    } on Object {
      if (!wasIndexed) {
        ids.remove(timetableId);
        await _writeIndex(ids);
      }
      rethrow;
    }
  }

  Future<void> delete(String timetableId) async {
    final id = _validateId(timetableId, 'timetableId');
    await _secureStore.delete(_recordKey(id));
    final ids = await _readIndex();
    if (ids.remove(id)) await _writeIndex(ids);
  }

  Future<List<BitcAccount>> list() async {
    final ids = await _readIndex();
    final accounts = <BitcAccount>[];
    final validIds = <String>{};
    for (final id in ids) {
      final account = await read(id);
      if (account != null) {
        accounts.add(account);
        validIds.add(id);
      }
    }
    if (validIds.length != ids.length) await _writeIndex(validIds);
    return List.unmodifiable(accounts);
  }

  Future<void> deleteAll() async {
    final keys = (await _secureStore.readAll()).keys.where(
      (key) => key.startsWith(_recordPrefix),
    );
    for (final key in keys) {
      await _secureStore.delete(key);
    }
    await _secureStore.delete(_indexKey);
  }

  Future<Set<String>> _readIndex() async {
    final raw = await _secureStore.read(_indexKey);
    if (raw == null) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const FormatException('Invalid account index.');
      }
      final values = decoded['timetableIds'];
      if (values is! List<dynamic> ||
          !values.every((value) => value is String && _isValidId(value))) {
        throw const FormatException('Invalid account index entries.');
      }
      return values.cast<String>().toSet();
    } on FormatException {
      await _secureStore.delete(_indexKey);
      return <String>{};
    } on TypeError {
      await _secureStore.delete(_indexKey);
      return <String>{};
    }
  }

  Future<void> _writeIndex(Set<String> ids) async {
    final sorted = ids.toList()..sort();
    await _secureStore.write(
      _indexKey,
      jsonEncode({'version': 1, 'timetableIds': sorted}),
    );
  }

  String _recordKey(String timetableId) => '$_recordPrefix$timetableId';

  static String _validateId(String value, String name) {
    final normalized = value.trim();
    if (!_isValidId(normalized)) {
      throw ArgumentError.value(value, name, 'Invalid identifier.');
    }
    return normalized;
  }

  static bool _isValidId(String value) {
    if (value.isEmpty || value.length > _maxIdLength) return false;
    return value.codeUnits.every(
      (unit) => unit >= 0x21 && unit <= 0x7e && unit != 0x2f,
    );
  }
}
