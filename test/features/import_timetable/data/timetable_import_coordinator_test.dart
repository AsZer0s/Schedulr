import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/features/import_timetable/data/timetable_import_coordinator.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  late AppDatabase database;
  late TimetableRepository repository;
  late TimetableImportCoordinator coordinator;
  late SemesterTimetable current;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = TimetableRepository(database);
    coordinator = TimetableImportCoordinator(repository);
    current = _initialTimetable();
    await repository.replaceSemesterTimetable(current);
  });

  tearDown(() => database.close());

  test('merge groups sessions with the same external course id', () async {
    final result = await coordinator.commit(
      currentTimetable: current,
      request: ImportCommitRequest(preview: _preview(ImportStrategy.merge)),
    );
    final stored = await repository.getSemesterTimetable(current.semester.id);

    expect(result.createdCount, 1);
    expect(stored!.courses, hasLength(2));
    final imported = stored.courses.singleWhere(
      (entry) => entry.course.sourceId == 'external-course',
    );
    expect(imported.sessions, hasLength(2));
    expect(imported.course.source, CourseSource.zfsoft);
  });

  test('replace removes existing courses but keeps periods', () async {
    final result = await coordinator.commit(
      currentTimetable: current,
      request: ImportCommitRequest(preview: _preview(ImportStrategy.replace)),
    );
    final stored = await repository.getSemesterTimetable(current.semester.id);

    expect(result.replacedCount, 1);
    expect(stored!.courses, hasLength(1));
    expect(stored.courses.single.course.name, '导入课程');
    expect(stored.periodDefinitions, current.periodDefinitions);
  });

  test('commit updates semester metadata and verified calendar', () async {
    await coordinator.commit(
      currentTimetable: current,
      request: ImportCommitRequest(preview: _preview(ImportStrategy.merge)),
      importedTerm: const ImportTermRequest(academicYear: '2027-2028', term: 2),
      calendar: ImportedSemesterCalendar(
        startDate: DateTime(2027, 9, 6),
        teachingWeeks: 18,
      ),
    );

    final stored = await repository.getSemesterTimetable(current.semester.id);
    expect(stored!.semester.academicYear, '2027-2028');
    expect(stored.semester.term, '2');
    expect(stored.semester.name, '2027-2028 第二学期');
    expect(stored.semester.startDate, DateTime(2027, 9, 6));
    expect(stored.semester.teachingWeeks, 18);
  });

  test('calendar without teachingWeeks updates only startDate', () async {
    await coordinator.commit(
      currentTimetable: current,
      request: ImportCommitRequest(preview: _preview(ImportStrategy.merge)),
      calendar: ImportedSemesterCalendar(startDate: DateTime(2026, 9, 14)),
    );

    final stored = await repository.getSemesterTimetable(current.semester.id);
    expect(stored!.semester.startDate, DateTime(2026, 9, 14));
    expect(stored.semester.teachingWeeks, current.semester.teachingWeeks);
    expect(stored.semester.academicYear, current.semester.academicYear);
  });

  test('commit without calendar preserves local calendar', () async {
    await coordinator.commit(
      currentTimetable: current,
      request: ImportCommitRequest(preview: _preview(ImportStrategy.merge)),
      importedTerm: const ImportTermRequest(academicYear: '2027-2028', term: 2),
    );

    final stored = await repository.getSemesterTimetable(current.semester.id);
    expect(stored!.semester.startDate, current.semester.startDate);
    expect(stored.semester.teachingWeeks, current.semester.teachingWeeks);
  });
}

ImportPreview _preview(ImportStrategy strategy) {
  final entries = [
    ImportedTimetableEntry(
      externalId: 'external-course',
      title: '导入课程',
      teacher: '教师甲',
      location: 'A101',
      dayOfWeek: DateTime.tuesday,
      startPeriod: 1,
      endPeriod: 2,
      weeks: const {1, 2},
    ),
    ImportedTimetableEntry(
      externalId: 'external-course',
      title: '导入课程',
      teacher: '教师甲',
      location: 'B202',
      dayOfWeek: DateTime.thursday,
      startPeriod: 3,
      endPeriod: 4,
      weeks: const {3, 4},
    ),
  ];
  return ImportPreview(
    strategy: strategy,
    items: [
      for (final entry in entries)
        ImportPreviewItem(imported: entry, kind: ImportPreviewItemKind.added),
    ],
  );
}

SemesterTimetable _initialTimetable() {
  final semester = Semester(
    id: 'semester',
    academicYear: '2026-2027',
    term: '1',
    name: '第一学期',
    startDate: DateTime(2026, 9, 7),
    teachingWeeks: 20,
    isCurrent: true,
  );
  final course = Course(id: 'existing', semesterId: semester.id, name: '已有课程');
  return SemesterTimetable(
    semester: semester,
    courses: [
      CourseWithSessions(
        course: course,
        sessions: [
          CourseSession(
            id: 'existing-session',
            courseId: course.id,
            weekday: DateTime.monday,
            startPeriod: 1,
            endPeriod: 2,
            weeks: const {1},
          ),
        ],
      ),
    ],
    periodDefinitions: [
      PeriodDefinition(
        id: 'period-1',
        semesterId: semester.id,
        period: 1,
        startTime: '08:00',
        endTime: '08:45',
        group: PeriodGroup.morning,
      ),
    ],
  );
}
