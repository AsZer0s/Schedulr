import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_session_store.dart';
import '../domain/bitc_account.dart';
import 'bitc_account_store.dart';

/// Override this provider in tests with an in-memory adapter.
final secureKeyValueAdapterProvider = Provider<SecureKeyValueAdapter>((ref) {
  return const FlutterSecureStorageAdapter();
});

final secureSessionStoreProvider = Provider<SecureSessionStore>((ref) {
  return SecureSessionStore(adapter: ref.watch(secureKeyValueAdapterProvider));
});

final bitcAccountStoreProvider = Provider<BitcAccountStore>((ref) {
  return BitcAccountStore(adapter: ref.watch(secureKeyValueAdapterProvider));
});

final bitcAccountProvider = FutureProvider.family<BitcAccount?, String>((
  ref,
  timetableId,
) {
  return ref.watch(bitcAccountStoreProvider).read(timetableId);
});

final bitcAccountsProvider = FutureProvider<List<BitcAccount>>((ref) {
  return ref.watch(bitcAccountStoreProvider).list();
});
