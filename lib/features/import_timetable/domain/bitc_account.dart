import 'package:flutter/foundation.dart';

/// The only BITC account data retained by the app.
@immutable
final class BitcAccount {
  const BitcAccount({
    required this.accountId,
    required this.timetableId,
    this.schoolProfileId = schoolProfileIdValue,
    this.lastSuccessfulRefreshAt,
  });

  factory BitcAccount.fromJson(Map<String, Object?> json) {
    const allowedKeys = {
      'version',
      'accountId',
      'schoolProfileId',
      'timetableId',
      'lastSuccessfulRefreshAt',
    };
    if (!json.keys.every(allowedKeys.contains)) {
      throw const FormatException(
        'BITC account record contains unsupported data.',
      );
    }
    final version = json['version'];
    final accountId = json['accountId'];
    final schoolProfileId = json['schoolProfileId'];
    final timetableId = json['timetableId'];
    final refreshValue = json['lastSuccessfulRefreshAt'];
    if (version != 1 ||
        accountId is! String ||
        timetableId is! String ||
        schoolProfileId != schoolProfileIdValue ||
        (refreshValue != null && refreshValue is! String)) {
      throw const FormatException('Invalid BITC account record.');
    }
    DateTime? refreshedAt;
    if (refreshValue is String) {
      refreshedAt = DateTime.tryParse(refreshValue);
      if (refreshedAt == null) {
        throw const FormatException('Invalid BITC refresh timestamp.');
      }
    }
    return BitcAccount(
      accountId: accountId,
      timetableId: timetableId,
      schoolProfileId: schoolProfileIdValue,
      lastSuccessfulRefreshAt: refreshedAt?.toUtc(),
    );
  }

  static const schoolProfileIdValue = 'bitc-zf-v9';

  final String accountId;
  final String timetableId;
  final String schoolProfileId;
  final DateTime? lastSuccessfulRefreshAt;

  Map<String, Object?> toJson() => {
    'version': 1,
    'accountId': accountId,
    'schoolProfileId': schoolProfileId,
    'timetableId': timetableId,
    if (lastSuccessfulRefreshAt != null)
      'lastSuccessfulRefreshAt': lastSuccessfulRefreshAt!
          .toUtc()
          .toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is BitcAccount &&
      other.accountId == accountId &&
      other.timetableId == timetableId &&
      other.schoolProfileId == schoolProfileId &&
      other.lastSuccessfulRefreshAt == lastSuccessfulRefreshAt;

  @override
  int get hashCode => Object.hash(
    accountId,
    timetableId,
    schoolProfileId,
    lastSuccessfulRefreshAt,
  );
}
