import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/time/week_set.dart';
import 'package:schedulr/features/desktop_widget/widget_projection.dart';
import 'package:schedulr/features/desktop_widget/widget_publisher.dart';
import 'package:schedulr/features/desktop_widget/widget_snapshot.dart';
import 'package:schedulr/features/timetable/domain/course.dart';
import 'package:schedulr/features/timetable/domain/course_session.dart';
import 'package:schedulr/features/timetable/domain/course_with_sessions.dart';
import 'package:schedulr/features/timetable/domain/period_definition.dart';
import 'package:schedulr/features/timetable/domain/semester.dart';
import 'package:schedulr/features/timetable/domain/semester_timetable.dart';

void main() {
  group('WidgetSnapshotProjector', () {
    test('projects fourteen days by default, filters parity and preserves full names', () {
      final timetable = _timetable(
        startDate: DateTime(2026, 9, 7),
        teachingWeeks: 4,
        courses: [
          _course(
            id: 'even',
            name: '单双周课程名称必须完整保留，不得截断',
            weekday: DateTime.monday,
            weeks: evenWeeks(1, 4),
          ),
          _course(
            id: 'odd',
            name: 'Odd',
            weekday: DateTime.monday,
            weeks: oddWeeks(1, 4),
          ),
          _course(
            id: 'gap',
            name: 'Gap',
            weekday: DateTime.tuesday,
            weeks: {1, 3},
          ),
        ],
      );

      final snapshot = const WidgetSnapshotProjector().project(
        timetable,
        DateTime(2026, 9, 14, 8),
      );

      expect(snapshot.state, WidgetSnapshotState.ready);
      expect(snapshot.days, hasLength(WidgetSnapshot.defaultProjectionDays));
      expect(snapshot.today.teachingWeek, 2);
      expect(snapshot.today.courses.single.courseName, contains('完整保留'));
      expect(snapshot.days[1].courses, isEmpty);
      expect(snapshot.days[1].teachingWeek, 2);
      expect(snapshot.tomorrow.date, '2026-09-15');
      expect(
        snapshot.futureDays,
        hasLength(WidgetSnapshot.defaultProjectionDays - 2),
      );
    });

    test('supports a shorter explicit projection window', () {
      final timetable = _timetable(
        startDate: DateTime(2026, 9, 7),
        teachingWeeks: 4,
      );
      final snapshot = const WidgetSnapshotProjector(projectionDays: 7)
          .project(timetable, DateTime(2026, 9, 7, 8));

      expect(snapshot.days, hasLength(7));
      expect(snapshot.futureDays, hasLength(5));
    });

    test('uses active course first and handles exact start/end boundaries', () {
      final timetable = _timetable(
        courses: [
          _course(
            id: 'first',
            name: 'First',
            weekday: DateTime.monday,
            startPeriod: 1,
          ),
          _course(
            id: 'second',
            name: 'Second',
            weekday: DateTime.monday,
            startPeriod: 2,
          ),
        ],
      );
      final projector = const WidgetSnapshotProjector();

      final active = projector
          .project(timetable, DateTime(2026, 9, 7, 8, 30))
          .next!;
      expect(active.courseId, 'first');
      expect(active.ongoing, isTrue);
      expect(
        projector.project(timetable, DateTime(2026, 9, 7, 9)).next!.courseId,
        'second',
      );
      expect(
        projector.project(timetable, DateTime(2026, 9, 7, 9, 45)).next,
        isNull,
      );
    });

    test('uses tomorrow after today has ended', () {
      final timetable = _timetable(
        courses: [
          _course(id: 'today', name: 'Today', weekday: DateTime.monday),
          _course(
            id: 'tomorrow',
            name: 'Tomorrow',
            weekday: DateTime.tuesday,
            startPeriod: 2,
          ),
        ],
      );
      final snapshot = const WidgetSnapshotProjector().project(
        timetable,
        DateTime(2026, 9, 7, 10),
      );

      expect(snapshot.next?.courseId, 'tomorrow');
      expect(snapshot.nextDate, '2026-09-08');
      expect(snapshot.next?.ongoing, isFalse);
    });

    test('uses tomorrow when today has no courses', () {
      final timetable = _timetable(
        courses: [
          _course(id: 'tomorrow', name: 'Tomorrow', weekday: DateTime.tuesday),
        ],
      );
      final snapshot = const WidgetSnapshotProjector().project(
        timetable,
        DateTime(2026, 9, 7, 10),
      );

      expect(snapshot.today.courses, isEmpty);
      expect(snapshot.next?.courseId, 'tomorrow');
      expect(snapshot.nextDate, snapshot.tomorrow.date);
    });

    test('does not skip to future days when tomorrow is empty', () {
      final timetable = _timetable(
        courses: [
          _course(id: 'future', name: 'Future', weekday: DateTime.wednesday),
        ],
      );
      final snapshot = const WidgetSnapshotProjector().project(
        timetable,
        DateTime(2026, 9, 7, 10),
      );

      expect(snapshot.tomorrow.courses, isEmpty);
      expect(snapshot.next, isNull);
      expect(snapshot.nextDate, isNull);
      expect(snapshot.futureDays.first.courses.single.courseId, 'future');
    });

    test('does not carry courses across a teaching-week boundary', () {
      final timetable = _timetable(
        courses: [
          _course(
            id: 'week-two',
            name: 'Week Two',
            weekday: DateTime.tuesday,
            weeks: {2},
          ),
        ],
      );
      final snapshot = const WidgetSnapshotProjector().project(
        timetable,
        DateTime(2026, 9, 13, 10),
      );
      expect(snapshot.today.teachingWeek, 1);
      expect(snapshot.today.courses, isEmpty);
      expect(snapshot.tomorrow.teachingWeek, 2);
      expect(snapshot.tomorrow.courses, isEmpty);
      expect(snapshot.futureDays.first.courses.single.courseId, 'week-two');
    });

    test('represents outside semester and empty today distinctly', () {
      final timetable = _timetable(
        startDate: DateTime(2026, 9, 7),
        teachingWeeks: 1,
        courses: [
          _course(id: 'monday', name: 'Monday', weekday: DateTime.monday),
        ],
      );
      final projector = const WidgetSnapshotProjector();
      final emptyToday = projector.project(timetable, DateTime(2026, 9, 8, 10));
      final outside = projector.project(timetable, DateTime(2026, 9, 21));

      expect(emptyToday.state, WidgetSnapshotState.ready);
      expect(emptyToday.today.courses, isEmpty);
      expect(outside.state, WidgetSnapshotState.outsideSemester);
      expect(outside.days.every((day) => day.courses.isEmpty), isTrue);
    });

    test('supports missing periods and stable time/period/id ordering', () {
      final timetable = _timetable(
        courses: [
          _course(id: 'z', name: 'Z', weekday: DateTime.monday, startPeriod: 3),
          _course(id: 'a', name: 'A', weekday: DateTime.monday, startPeriod: 2),
          _course(
            id: 'missing',
            name: 'Missing',
            weekday: DateTime.monday,
            startPeriod: 8,
          ),
        ],
        periods: [_period(2, '09:00', '09:45'), _period(3, '09:00', '09:45')],
      );
      final courses = const WidgetSnapshotProjector()
          .project(timetable, DateTime(2026, 9, 7, 8))
          .today
          .courses;

      expect(courses.map((course) => course.courseId), ['a', 'z', 'missing']);
      expect(courses[0].time, '09:00-09:45');
      expect(courses[2].time, isNull);
      expect(courses[2].startPeriod, 8);
    });

    test('uses calendar dates across month boundaries', () {
      final projected = const WidgetSnapshotProjector().project(
        _timetable(startDate: DateTime(2026, 10, 26), teachingWeeks: 4),
        DateTime(2026, 10, 31, 23, 30),
      );
      final empty = WidgetSnapshot.noTimetable(DateTime(2026, 10, 31, 23, 30));

      expect(projected.days.take(7).map((day) => day.date), [
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
        '2026-11-06',
      ]);
      expect(empty.days.take(7).map((day) => day.date), [
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
        '2026-11-06',
      ]);
    });

    test('round trips nextDate and accepts legacy snapshots', () {
      final snapshot = const WidgetSnapshotProjector().project(
        _timetable(
          courses: [
            _course(
              id: 'tomorrow',
              name: 'Tomorrow',
              weekday: DateTime.tuesday,
            ),
          ],
        ),
        DateTime(2026, 9, 7, 10),
      );
      final decoded = WidgetSnapshot.fromJson(snapshot.toJson());
      final legacy = Map<String, Object?>.from(snapshot.toMap())
        ..remove('nextDate');
      final legacyDecoded = WidgetSnapshot.fromMap(legacy);

      expect(decoded.nextDate, snapshot.nextDate);
      expect(decoded, snapshot);
      expect(legacyDecoded.nextDate, isNull);
    });

    test('round trips stable JSON without private course fields', () {
      final snapshot = const WidgetSnapshotProjector().project(
        _timetable(
          courses: [
            _course(
              id: 'course',
              name: 'Long name',
              weekday: DateTime.monday,
              teacher: 'Teacher',
              location: '东坝校区 · 东区13-301系统应用实训室1',
            ),
          ],
        ),
        DateTime(2026, 9, 7, 8),
      );
      final json = snapshot.toJson();
      final decoded = WidgetSnapshot.fromJson(json);
      final keys = decoded.today.courses.single.toMap().keys.toSet();

      expect(decoded, snapshot);
      expect(json, decoded.toJson());
      expect(keys, {
        'courseId',
        'sessionId',
        'courseName',
        'teacher',
        'location',
        'time',
        'startPeriod',
        'endPeriod',
        'color',
        'ongoing',
      });
      expect(json, isNot(contains('notes')));
      expect(json, isNot(contains('source')));
      expect(json, isNot(contains('student')));
      expect(decoded.today.courses.single.location, '13-301');
    });
  });

  group('WidgetSnapshotPublisher', () {
    test(
      'reports a shared-storage read-back failure without updating widget',
      () async {
        final bridge = _FakeBridge()..forceEmptyReadBack = true;
        final diagnostics = <WidgetPublishDiagnostics>[];
        final publisher = WidgetSnapshotPublisher(
          bridge,
          onDiagnostics: diagnostics.add,
        );

        await expectLater(
          publisher.publish(WidgetSnapshot.noTimetable(DateTime(2026, 9, 7))),
          throwsA(isA<WidgetStorageReadBackException>()),
        );
        expect(bridge.calls.any((call) => call.startsWith('save:')), isTrue);
        expect(bridge.calls, isNot(contains('update')));
        expect(diagnostics.last.errorCode, 'shared-storage-readback-failure');
      },
    );

    test('accepts a valid read-back schema before updating widget', () async {
      final bridge = _FakeBridge();
      final snapshot = WidgetSnapshot.noTimetable(DateTime(2026, 9, 7));
      await WidgetSnapshotPublisher(
        bridge,
        updateRetryDelay: Duration.zero,
      ).publish(snapshot);

      expect(bridge.calls.where((call) => call == 'update'), hasLength(1));
    });

    test(
      'uses shared group, snapshot key indirectly, update names and clear',
      () async {
        final bridge = _FakeBridge();
        final publisher = WidgetSnapshotPublisher(
          bridge,
          updateRetryDelay: Duration.zero,
        );
        final snapshot = WidgetSnapshot.noTimetable(DateTime(2026, 9, 7));

        await publisher.publish(snapshot);
        await publisher.clear();

        expect(bridge.calls, [
          'group:${HomeWidgetStorageBridge.appGroupId}',
          'save:${snapshot.toJson()}',
          'update',
          'group:${HomeWidgetStorageBridge.appGroupId}',
          'clear',
        ]);
      },
    );

    test('retries a failed widget update once and reports the retry', () async {
      final bridge = _FakeBridge()..failFirstUpdate = true;
      final diagnostics = <WidgetPublishDiagnostics>[];

      await WidgetSnapshotPublisher(
        bridge,
        updateRetryDelay: Duration.zero,
        onDiagnostics: diagnostics.add,
      ).publish(WidgetSnapshot.noTimetable(DateTime(2026, 9, 7)));

      expect(bridge.calls.where((call) => call == 'update'), hasLength(2));
      expect(
        diagnostics.any((item) => item.errorCode == 'widget-update-retry'),
        isTrue,
      );
    });
  });
}

SemesterTimetable _timetable({
  DateTime? startDate,
  int teachingWeeks = 4,
  List<CourseWithSessions>? courses,
  List<PeriodDefinition>? periods,
}) {
  final semester = Semester(
    id: 'semester',
    academicYear: '2026-2027',
    term: '1',
    name: '2026-2027 第一学期',
    timetableName: '主课表',
    startDate: startDate ?? DateTime(2026, 9, 7),
    teachingWeeks: teachingWeeks,
    isCurrent: true,
  );
  return SemesterTimetable(
    semester: semester,
    courses: courses ?? const <CourseWithSessions>[],
    periodDefinitions:
        periods ?? [_period(1, '08:00', '08:45'), _period(2, '09:00', '09:45')],
  );
}

CourseWithSessions _course({
  required String id,
  required String name,
  required int weekday,
  Set<int>? weeks,
  String? teacher,
  String? location,
  int startPeriod = 1,
}) {
  return CourseWithSessions(
    course: Course(
      id: id,
      semesterId: 'semester',
      name: name,
      teacher: teacher,
      colorValue: 0xFF123456,
    ),
    sessions: [
      CourseSession(
        id: '$id-session',
        courseId: id,
        weekday: weekday,
        startPeriod: startPeriod,
        endPeriod: startPeriod,
        weeks: weeks ?? {1, 2, 3, 4},
        location: location,
      ),
    ],
  );
}

PeriodDefinition _period(int period, String start, String end) {
  return PeriodDefinition(
    id: 'period-$period',
    semesterId: 'semester',
    period: period,
    startTime: start,
    endTime: end,
    group: PeriodGroup.morning,
  );
}

class _FakeBridge implements WidgetStorageBridge {
  String? savedSnapshot;
  String? readBackOverride;
  bool forceEmptyReadBack = false;
  bool failFirstUpdate = false;
  int updateAttempts = 0;
  final calls = <String>[];
  @override
  Future<void> setAppGroupId(String groupId) async =>
      calls.add('group:$groupId');

  @override
  Future<void> saveSnapshot(String value) async {
    savedSnapshot = value;
    calls.add('save:$value');
  }

  @override
  Future<String?> readSnapshot() async =>
      forceEmptyReadBack ? null : readBackOverride ?? savedSnapshot;

  @override
  Future<void> updateWidget() async {
    updateAttempts++;
    calls.add('update');
    if (failFirstUpdate && updateAttempts == 1) {
      throw StateError('transient update failure');
    }
  }

  @override
  Future<void> clearSnapshot() async => calls.add('clear');
}
