import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/secure_session_store.dart';
import 'package:schedulr/features/import_timetable/data/bitc_account_store.dart';
import 'package:schedulr/features/import_timetable/domain/bitc_account.dart';

void main() {
  late MemorySecureKeyValueAdapter adapter;
  late BitcAccountStore store;

  setUp(() {
    adapter = MemorySecureKeyValueAdapter();
    store = BitcAccountStore(adapter: adapter);
  });

  test(
    'isolates records by timetable and lists through the secure index',
    () async {
      final first = _account('timetable-a', 'student-a');
      final second = _account('timetable-b', 'student-b');

      await store.write(first);
      await store.write(second);

      expect(await store.read('timetable-a'), first);
      expect(await store.read('timetable-b'), second);
      expect(await store.list(), containsAll(<BitcAccount>[first, second]));
      expect(
        adapter.values.keys,
        contains('schedulr.secure.bitc.accounts.index.v1'),
      );
    },
  );

  test('rejects malformed records and reconciles the index', () async {
    await store.write(_account('timetable-a', 'student-a'));
    adapter.values['schedulr.secure.bitc.account.v1.timetable-a'] = jsonEncode({
      'version': 1,
      'accountId': 'student-a',
      'schoolProfileId': 'bitc-zf-v9',
      'timetableId': 'timetable-a',
      'password': 'must-not-be-retained',
    });

    expect(await store.read('timetable-a'), isNull);
    expect(
      adapter.values,
      isNot(contains('schedulr.secure.bitc.account.v1.timetable-a')),
    );
    expect(await store.list(), isEmpty);
    final index = jsonDecode(
      adapter.values['schedulr.secure.bitc.accounts.index.v1']!,
    ) as Map<String, dynamic>;
    expect(index['timetableIds'], isEmpty);
  });

  test('deletes one timetable without affecting another', () async {
    await store.write(_account('timetable-a', 'student-a'));
    await store.write(_account('timetable-b', 'student-b'));

    await store.delete('timetable-a');

    expect(await store.read('timetable-a'), isNull);
    expect(await store.read('timetable-b'), isNotNull);
    expect((await store.list()).map((account) => account.timetableId), [
      'timetable-b',
    ]);
  });

  test('deleteAll removes indexed records without bulk delete', () async {
    await store.write(_account('timetable-a', 'student-a'));
    await store.write(_account('timetable-b', 'student-b'));

    await store.deleteAll();

    expect(
      adapter.deletedKeys,
      containsAll(<String>[
        'schedulr.secure.bitc.account.v1.timetable-a',
        'schedulr.secure.bitc.account.v1.timetable-b',
        'schedulr.secure.bitc.accounts.index.v1',
      ]),
    );
    expect(adapter.deleteAllCalled, isFalse);
    expect(await store.list(), isEmpty);
  });

  test(
    'deleteAll removes orphaned records when the index is corrupt',
    () async {
      adapter.values['schedulr.secure.bitc.account.v1.orphan'] = jsonEncode({
        'version': 1,
        'accountId': 'student-orphan',
        'schoolProfileId': 'bitc-zf-v9',
        'timetableId': 'orphan',
      });
      adapter.values['schedulr.secure.bitc.accounts.index.v1'] = 'corrupt';
      adapter.values['unrelated-secure-key'] = 'keep';

      await store.deleteAll();

      expect(adapter.values, equals({'unrelated-secure-key': 'keep'}));
    },
  );

  test('validates identifiers and supported school profile', () async {
    expect(
      () => store.write(_account('bad/id', 'student-a')),
      throwsArgumentError,
    );
    expect(() => store.read('bad/id'), throwsArgumentError);
    expect(
      () => store.write(
        BitcAccount(
          accountId: 'student-a',
          timetableId: 'timetable-a',
          schoolProfileId: 'other-profile',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('serialized records contain only approved privacy fields', () async {
    await store.write(
      _account(
        'timetable-a',
        'student-a',
        refreshedAt: DateTime.utc(2026, 9, 13, 10),
      ),
    );

    final record = jsonDecode(
      adapter.values['schedulr.secure.bitc.account.v1.timetable-a']!,
    ) as Map<String, dynamic>;
    expect(record.keys, {
      'version',
      'accountId',
      'schoolProfileId',
      'timetableId',
      'lastSuccessfulRefreshAt',
    });
    expect(record.keys, isNot(contains('password')));
    expect(record.keys, isNot(contains('cookie')));
    expect(record.keys, isNot(contains('token')));
  });
}

BitcAccount _account(
  String timetableId,
  String accountId, {
  DateTime? refreshedAt,
}) => BitcAccount(
  accountId: accountId,
  timetableId: timetableId,
  lastSuccessfulRefreshAt: refreshedAt,
);

final class MemorySecureKeyValueAdapter implements SecureKeyValueAdapter {
  final values = <String, String>{};
  final deletedKeys = <String>[];
  bool deleteAllCalled = false;

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
