import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/bitc_refresh_reconciler.dart';
import 'package:schedulr/features/import_timetable/domain/imported_timetable_entry.dart';
import 'package:schedulr/features/timetable/domain/course.dart';
import 'package:schedulr/features/timetable/domain/course_session.dart';
import 'package:schedulr/features/timetable/domain/course_source.dart';
import 'package:schedulr/features/timetable/domain/course_with_sessions.dart';
import 'package:schedulr/features/timetable/domain/period_definition.dart';
import 'package:schedulr/features/timetable/domain/semester.dart';
import 'package:schedulr/features/timetable/domain/semester_timetable.dart';

void main() {
  test('groups rows, adds new courses, and uses injected IDs', () {
    var nextId = 0;
    final plan = _reconciler(() => 'generated-${nextId++}').reconcile(
      existing: _timetable([]),
      imported: [
        _entry('remote-a', title: '数学', day: 1),
        _entry('remote-a', title: '数学', day: 3),
        _entry('remote-b', title: '物理', day: 2),
      ],
    );

    expect(plan.addedCount, 2);
    expect(plan.updatedCount, 0);
    expect(plan.desiredCourses, hasLength(2));
    expect(plan.desiredSourceManagedCourses, hasLength(2));
    expect(plan.added[0].course.id, 'generated-0');
    expect(plan.added[0].sessions.map((session) => session.id), [
      'generated-1',
      'generated-2',
    ]);
    expect(plan.added[0].sessions, hasLength(2));
    expect(plan.added[0].course.source, CourseSource.zfsoft);
    expect(plan.added[0].course.sourceId, 'remote-a');
  });

  test('updates matching unmodified course and reuses stable IDs', () {
    final current = _courseWithSessions(
      courseId: 'local-course',
      sourceId: 'remote-a',
      name: '旧名称',
      sessions: [
        _session(
          id: 'stable-session',
          courseId: 'local-course',
          day: 1,
          weeks: {1, 2},
          location: 'A101',
        ),
        _session(
          id: 'removed-session',
          courseId: 'local-course',
          day: 5,
          weeks: {1},
        ),
      ],
    );
    var generated = 0;
    final plan = _reconciler(() => 'new-${generated++}').reconcile(
      existing: _timetable([current]),
      imported: [
        _entry(
          'remote-a',
          title: '新名称',
          day: 1,
          weeks: {1, 2, 3},
          location: 'B202',
          teacher: '新老师',
          notes: '新备注',
        ),
        _entry('remote-a', title: '新名称', day: 4),
      ],
    );

    final refreshed = plan.updated.single;
    expect(plan.added, isEmpty);
    expect(plan.removed, isEmpty);
    expect(refreshed.course.id, 'local-course');
    expect(refreshed.course.name, '新名称');
    expect(refreshed.course.teacher, '新老师');
    expect(refreshed.course.notes, '新备注');
    expect(refreshed.sessions[0].id, 'stable-session');
    expect(refreshed.sessions[0].weeks, {1, 2, 3});
    expect(refreshed.sessions[0].location, 'B202');
    expect(refreshed.sessions[1].id, 'new-0');
    expect(plan.desiredCourses, [refreshed]);
  });

  test('classifies equal matching remote course as unchanged', () {
    final current = _courseWithSessions(
      courseId: 'course-a',
      sourceId: 'remote-a',
      name: '数学',
      sessions: [
        _session(
          id: 'session-a',
          courseId: 'course-a',
          day: 1,
          weeks: {1, 2},
          location: 'A101',
        ),
      ],
    );
    final plan = _reconciler().reconcile(
      existing: _timetable([current]),
      imported: [
        _entry(
          'remote-a',
          title: '数学',
          day: 1,
          weeks: {1, 2},
          location: 'A101',
        ),
      ],
    );

    expect(plan.unchanged, [current]);
    expect(plan.updated, isEmpty);
    expect(plan.desiredCourses.single, same(current));
  });

  test('removes absent unmodified zfsoft courses', () {
    final retained = _courseWithSessions(
      courseId: 'retained',
      sourceId: 'present',
      name: '保留',
    );
    final removed = _courseWithSessions(
      courseId: 'removed',
      sourceId: 'absent',
      name: '删除',
    );
    final plan = _reconciler().reconcile(
      existing: _timetable([retained, removed]),
      imported: [_entry('present', title: '保留')],
    );

    expect(plan.removed, [removed]);
    expect(plan.desiredCourses.single.course.id, retained.course.id);
    expect(plan.desiredCourses.single.sessions, hasLength(1));
    expect(plan.removedCount, 1);
  });

  test('preserves manual and locally modified courses', () {
    final manual = _courseWithSessions(
      courseId: 'manual',
      name: '手动课程',
      source: CourseSource.manual,
    );
    final modified = _courseWithSessions(
      courseId: 'modified',
      sourceId: 'remote-a',
      name: '本地改名',
      locallyModified: true,
    );
    final absentModified = _courseWithSessions(
      courseId: 'absent-modified',
      sourceId: 'remote-gone',
      name: '本地保留',
      locallyModified: true,
    );
    final plan = _reconciler().reconcile(
      existing: _timetable([manual, modified, absentModified]),
      imported: [_entry('remote-a', title: '远端名称')],
    );

    expect(plan.manualCoursesPreserved, [manual]);
    expect(plan.locallyModifiedPreserved, [modified, absentModified]);
    expect(plan.updated, isEmpty);
    expect(plan.removed, isEmpty);
    expect(plan.desiredCourses, [manual, modified, absentModified]);
  });

  test('preserves zfsoft courses without source IDs conservatively', () {
    final unmanaged = _courseWithSessions(
      courseId: 'unmanaged',
      name: '无外部 ID',
      source: CourseSource.zfsoft,
    );
    final plan = _reconciler().reconcile(
      existing: _timetable([unmanaged]),
      imported: [_entry('new-remote', title: '新课程')],
    );

    expect(plan.unmanagedSourceCoursesPreserved, [unmanaged]);
    expect(plan.desiredCourses, [unmanaged, plan.added.single]);
    expect(plan.removed, isEmpty);
  });

  test('rejects empty remote when an unmodified source course exists', () {
    final existing = _courseWithSessions(
      courseId: 'course-a',
      sourceId: 'remote-a',
      name: '数学',
    );

    expect(
      () => _reconciler().reconcile(
        existing: _timetable([existing]),
        imported: const [],
      ),
      throwsA(isA<BitcRefreshException>()),
    );
  });

  test('allows empty remote when only protected courses exist', () {
    final manual = _courseWithSessions(
      courseId: 'manual',
      name: '手动',
      source: CourseSource.manual,
    );
    final modified = _courseWithSessions(
      courseId: 'modified',
      sourceId: 'remote-a',
      name: '本地',
      locallyModified: true,
    );
    final plan = _reconciler().reconcile(
      existing: _timetable([manual, modified]),
      imported: const [],
    );

    expect(plan.desiredCourses, [manual, modified]);
    expect(plan.locallyModifiedPreserved, [modified]);
  });

  test('does not mutate caller collections and returns unmodifiable lists', () {
    final imported = <ImportedTimetableEntry>[_entry('remote-a', title: '数学')];
    final existingCourses = <CourseWithSessions>[];
    final plan = _reconciler().reconcile(
      existing: _timetable(existingCourses),
      imported: imported,
    );
    imported.clear();
    existingCourses.clear();

    expect(plan.desiredCourses, hasLength(1));
    expect(() => plan.added.add(plan.added.single), throwsUnsupportedError);
    expect(() => plan.desiredCourses.clear(), throwsUnsupportedError);
  });
}

BitcRefreshReconciler _reconciler([String Function()? generator]) {
  return BitcRefreshReconciler(idGenerator: generator);
}

SemesterTimetable _timetable(List<CourseWithSessions> courses) {
  return SemesterTimetable(
    semester: Semester(
      id: 'semester',
      academicYear: '2026-2027',
      term: '1',
      name: '第一学期',
      timetableName: '主课表',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
    ),
    courses: courses,
    periodDefinitions: const <PeriodDefinition>[],
  );
}

CourseWithSessions _courseWithSessions({
  required String courseId,
  required String name,
  CourseSource source = CourseSource.zfsoft,
  String? sourceId,
  bool locallyModified = false,
  List<CourseSession> sessions = const [],
}) {
  return CourseWithSessions(
    course: Course(
      id: courseId,
      semesterId: 'semester',
      name: name,
      source: source,
      sourceId: sourceId,
      isLocallyModified: locallyModified,
    ),
    sessions: sessions,
  );
}

CourseSession _session({
  required String id,
  required String courseId,
  required int day,
  Set<int> weeks = const {1},
  String? location,
}) {
  return CourseSession(
    id: id,
    courseId: courseId,
    weekday: day,
    startPeriod: 1,
    endPeriod: 2,
    weeks: weeks,
    location: location,
  );
}

ImportedTimetableEntry _entry(
  String externalId, {
  String title = '课程',
  int day = 1,
  Set<int> weeks = const {1},
  String? location,
  String? teacher,
  String? notes,
}) {
  return ImportedTimetableEntry(
    externalId: externalId,
    title: title,
    dayOfWeek: day,
    startPeriod: 1,
    endPeriod: 2,
    weeks: weeks,
    location: location,
    teacher: teacher,
    notes: notes,
  );
}
