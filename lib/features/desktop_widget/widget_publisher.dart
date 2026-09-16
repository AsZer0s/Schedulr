import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/semester.dart';

import 'widget_projection.dart';
import 'widget_snapshot.dart';

abstract interface class WidgetStorageBridge {
  Future<void> setAppGroupId(String groupId);

  Future<void> saveSnapshot(String value);

  Future<String?> readSnapshot();

  Future<void> updateWidget();

  Future<void> clearSnapshot();
}

abstract interface class WidgetCatalogStorageBridge {
  Future<void> saveCatalog(String value);

  Future<String?> readCatalog();

  Future<void> clearCatalog();
}

enum WidgetPublishStage {
  idle,
  loadingTimetable,
  projectingSnapshot,
  configuringStorage,
  savingSnapshot,
  updatingWidget,
  clearingSnapshot,
  completed,
  failed,
}

/// Safe, user-facing publishing state. It deliberately contains no identity,
/// authentication, or platform payload values.
class WidgetPublishDiagnostics {
  const WidgetPublishDiagnostics({
    required this.stage,
    required this.attempt,
    required this.occurredAt,
    this.errorCode,
    this.retryable = false,
  });

  const WidgetPublishDiagnostics.idle()
    : stage = WidgetPublishStage.idle,
      attempt = 0,
      occurredAt = null,
      errorCode = null,
      retryable = false;

  final WidgetPublishStage stage;
  final int attempt;
  final DateTime? occurredAt;
  final String? errorCode;
  final bool retryable;

  bool get isTerminal =>
      stage == WidgetPublishStage.completed ||
      stage == WidgetPublishStage.failed;

  @override
  String toString() =>
      'WidgetPublishDiagnostics(stage: $stage, attempt: $attempt, '
      'errorCode: $errorCode, retryable: $retryable)';
}

class HomeWidgetStorageBridge
    implements WidgetStorageBridge, WidgetCatalogStorageBridge {
  const HomeWidgetStorageBridge();

  static const String appGroupId = 'group.app.schedulr.shared';
  static const String snapshotKey = 'schedulr.widget.snapshot.v1';
  static const String catalogKey = 'schedulr.widget.snapshot.v2';

  static const String qualifiedAndroidWidgetName =
      'app.schedulr.schedulr.widget.SchedulrWidgetReceiver';
  static const String iOSWidgetName = 'SchedulrWidget';

  @override
  Future<void> setAppGroupId(String groupId) async {
    await HomeWidget.setAppGroupId(groupId);
  }

  @override
  Future<void> saveSnapshot(String value) async {
    await HomeWidget.saveWidgetData<String>(snapshotKey, value);
  }

  @override
  Future<String?> readSnapshot() async {
    return HomeWidget.getWidgetData<String>(snapshotKey);
  }

  @override
  Future<void> saveCatalog(String value) async {
    await HomeWidget.saveWidgetData<String>(catalogKey, value);
  }

  @override
  Future<String?> readCatalog() async {
    return HomeWidget.getWidgetData<String>(catalogKey);
  }

  @override
  Future<void> clearCatalog() async {
    await HomeWidget.saveWidgetData<String>(catalogKey, null);
    await HomeWidget.saveWidgetData<String>(snapshotKey, null);
  }

  @override
  Future<void> updateWidget() async {
    await HomeWidget.updateWidget(
      qualifiedAndroidName: qualifiedAndroidWidgetName,
      iOSName: iOSWidgetName,
    );
  }

  @override
  Future<void> clearSnapshot() async {
    await HomeWidget.saveWidgetData<String>(snapshotKey, null);
    await updateWidget();
  }
}

class WidgetStorageReadBackException implements Exception {
  const WidgetStorageReadBackException(this.reason);

  final String reason;

  @override
  String toString() => 'Widget storage read-back failed: $reason';
}

class WidgetSnapshotPublisher {
  const WidgetSnapshotPublisher(
    this.bridge, {
    this.onDiagnostics,
    this.updateRetryDelay = const Duration(milliseconds: 150),
  });

  final WidgetStorageBridge bridge;
  final void Function(WidgetPublishDiagnostics diagnostics)? onDiagnostics;
  final Duration updateRetryDelay;

  Future<void> publish(WidgetSnapshot snapshot, {int attempt = 1}) async {
    _report(
      WidgetPublishDiagnostics(
        stage: WidgetPublishStage.configuringStorage,
        attempt: attempt,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    try {
      await bridge.setAppGroupId(HomeWidgetStorageBridge.appGroupId);
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.savingSnapshot,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      await bridge.saveSnapshot(snapshot.toJson());
      final readBack = await bridge.readSnapshot();
      _validateReadBack(readBack, snapshot.schemaVersion);
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.updatingWidget,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      Object? updateError;
      for (var updateAttempt = 0; updateAttempt < 2; updateAttempt++) {
        try {
          await bridge.updateWidget();
          updateError = null;
          break;
        } on Object catch (error) {
          updateError = error;
          if (updateAttempt == 0) {
            _report(
              WidgetPublishDiagnostics(
                stage: WidgetPublishStage.failed,
                attempt: attempt,
                occurredAt: DateTime.now().toUtc(),
                errorCode: 'widget-update-retry',
                retryable: true,
              ),
            );
          }
          if (updateAttempt == 0 && updateRetryDelay > Duration.zero) {
            await Future<void>.delayed(updateRetryDelay);
          }
        }
      }
      if (updateError != null) throw updateError;
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.completed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    } on Object catch (error) {
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.failed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
          errorCode: _errorCode(error),
          retryable: _isRetryable(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> clear({int attempt = 1}) async {
    _report(
      WidgetPublishDiagnostics(
        stage: WidgetPublishStage.configuringStorage,
        attempt: attempt,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    try {
      await bridge.setAppGroupId(HomeWidgetStorageBridge.appGroupId);
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.clearingSnapshot,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      await bridge.clearSnapshot();
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.completed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    } on Object catch (error) {
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.failed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
          errorCode: _errorCode(error),
          retryable: _isRetryable(error),
        ),
      );
      rethrow;
    }
  }

  void _validateReadBack(String? value, int schemaVersion) {
    if (value == null || value.isEmpty) {
      throw const WidgetStorageReadBackException('empty');
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded['schemaVersion'] != schemaVersion) {
      throw const WidgetStorageReadBackException('schema');
    }
  }

  void _report(WidgetPublishDiagnostics diagnostics) {
    onDiagnostics?.call(diagnostics);
  }

  String _errorCode(Object error) {
    if (error is WidgetStorageReadBackException) {
      return 'shared-storage-readback-failure';
    }
    if (error is FormatException) return 'invalid-snapshot';
    if (error is ArgumentError) return 'invalid-configuration';
    return 'platform-bridge-failure';
  }

  bool _isRetryable(Object error) =>
      error is! FormatException && error is! ArgumentError;
}

class WidgetSnapshotCoordinator {
  const WidgetSnapshotCoordinator({
    required this.repository,
    required this.bridge,
    this.projector = const WidgetSnapshotProjector(),
    this.onDiagnostics,
    this.noTimetableProjectionDays = WidgetSnapshot.defaultProjectionDays,
  });

  final TimetableRepository repository;
  final WidgetStorageBridge bridge;
  final WidgetSnapshotProjector projector;
  final void Function(WidgetPublishDiagnostics diagnostics)? onDiagnostics;
  final int noTimetableProjectionDays;

  Future<WidgetSnapshot> publishCurrent(DateTime now, {int attempt = 1}) async {
    _report(
      WidgetPublishDiagnostics(
        stage: WidgetPublishStage.loadingTimetable,
        attempt: attempt,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    var publisherStarted = false;
    try {
      final semesters = await repository.getSemesters();
      Semester? semester;
      for (final candidate in semesters) {
        if (candidate.isCurrent) {
          semester = candidate;
          break;
        }
      }
      semester ??= semesters.isEmpty ? null : semesters.first;
      final timetable = semester == null
          ? null
          : await repository.getSemesterTimetable(semester.id);
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.projectingSnapshot,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      final snapshot = timetable == null
          ? WidgetSnapshot.noTimetable(
              now,
              projectionDays: noTimetableProjectionDays,
            )
          : projector.project(timetable, now);
      publisherStarted = true;
      await WidgetSnapshotPublisher(
        bridge,
        onDiagnostics: onDiagnostics,
      ).publish(snapshot, attempt: attempt);
      return snapshot;
    } on Object catch (error) {
      if (!publisherStarted) {
        _report(
          WidgetPublishDiagnostics(
            stage: WidgetPublishStage.failed,
            attempt: attempt,
            occurredAt: DateTime.now().toUtc(),
            errorCode: _errorCode(error),
            retryable: _isRetryable(error),
          ),
        );
      }
      rethrow;
    }
  }

  Future<WidgetCatalog> publishAll(DateTime now, {int attempt = 1}) async {
    final catalogBridge = bridge is WidgetCatalogStorageBridge
        ? bridge as WidgetCatalogStorageBridge
        : (throw StateError('Catalog storage bridge is unavailable.'));
    _report(
      WidgetPublishDiagnostics(
        stage: WidgetPublishStage.loadingTimetable,
        attempt: attempt,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    try {
      final timetables = await repository.getAllSemesterTimetables();
      final current =
          timetables
              .where((timetable) => timetable.semester.isCurrent)
              .firstOrNull ??
          (timetables.isEmpty ? null : timetables.first);
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.projectingSnapshot,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      final catalog = WidgetCatalog(
        schemaVersion: WidgetCatalog.currentSchemaVersion,
        generatedAt: now.toLocal(),
        defaultTimetableId: current?.semester.id,
        entries: timetables
            .map(
              (timetable) => WidgetCatalogEntry(
                timetableId: timetable.semester.id,
                timetableName: timetable.semester.timetableName,
                semesterName: timetable.semester.name,
                snapshot: projector.project(timetable, now),
              ),
            )
            .toList(growable: false),
      );
      await bridge.setAppGroupId(HomeWidgetStorageBridge.appGroupId);
      await catalogBridge.saveCatalog(catalog.toJson());
      final readBack = await catalogBridge.readCatalog();
      if (readBack == null) {
        throw const WidgetStorageReadBackException('empty-catalog');
      }
      final decoded = WidgetCatalog.fromJson(readBack);
      if (decoded.schemaVersion != WidgetCatalog.currentSchemaVersion ||
          decoded.entries.length != catalog.entries.length ||
          decoded.entries.any(
            (entry) => catalog.entryFor(entry.timetableId) == null,
          )) {
        throw const WidgetStorageReadBackException('catalog-schema');
      }
      await bridge.updateWidget();
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.completed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
      return catalog;
    } on Object catch (error) {
      _report(
        WidgetPublishDiagnostics(
          stage: WidgetPublishStage.failed,
          attempt: attempt,
          occurredAt: DateTime.now().toUtc(),
          errorCode: _errorCode(error),
          retryable: _isRetryable(error),
        ),
      );
      rethrow;
    }
  }

  void _report(WidgetPublishDiagnostics diagnostics) {
    onDiagnostics?.call(diagnostics);
  }

  String _errorCode(Object error) {
    if (error is WidgetStorageReadBackException) {
      return 'shared-storage-readback-failure';
    }
    if (error is FormatException) return 'invalid-snapshot';
    if (error is ArgumentError) return 'invalid-configuration';
    return 'timetable-load-failure';
  }

  bool _isRetryable(Object error) =>
      error is! FormatException && error is! ArgumentError;
}
