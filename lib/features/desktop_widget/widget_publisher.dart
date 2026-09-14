import 'package:home_widget/home_widget.dart';
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/semester.dart';

import 'widget_projection.dart';
import 'widget_snapshot.dart';

abstract interface class WidgetStorageBridge {
  Future<void> setAppGroupId(String groupId);

  Future<void> saveSnapshot(String value);

  Future<void> updateWidget();

  Future<void> clearSnapshot();
}

class HomeWidgetStorageBridge implements WidgetStorageBridge {
  const HomeWidgetStorageBridge();

  static const String appGroupId = 'group.app.schedulr.shared';
  static const String snapshotKey = 'schedulr.widget.snapshot.v1';
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

class WidgetSnapshotPublisher {
  const WidgetSnapshotPublisher(this.bridge);

  final WidgetStorageBridge bridge;

  Future<void> publish(WidgetSnapshot snapshot) async {
    await bridge.setAppGroupId(HomeWidgetStorageBridge.appGroupId);
    await bridge.saveSnapshot(snapshot.toJson());
    await bridge.updateWidget();
  }

  Future<void> clear() async {
    await bridge.setAppGroupId(HomeWidgetStorageBridge.appGroupId);
    await bridge.clearSnapshot();
  }
}

class WidgetSnapshotCoordinator {
  const WidgetSnapshotCoordinator({
    required this.repository,
    required this.bridge,
    this.projector = const WidgetSnapshotProjector(),
  });

  final TimetableRepository repository;
  final WidgetStorageBridge bridge;
  final WidgetSnapshotProjector projector;

  Future<WidgetSnapshot> publishCurrent(DateTime now) async {
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
    final snapshot = timetable == null
        ? WidgetSnapshot.noTimetable(now)
        : projector.project(timetable, now);
    await WidgetSnapshotPublisher(bridge).publish(snapshot);
    return snapshot;
  }
}
