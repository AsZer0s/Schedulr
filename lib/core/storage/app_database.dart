import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Semesters extends Table {
  TextColumn get id => text()();
  TextColumn get academicYear => text()();
  TextColumn get term => text()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get teachingWeeks => integer()();
  TextColumn get timeZone => text().withDefault(const Constant('local'))();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Courses extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id)();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get teacher => text().nullable()();
  TextColumn get teachingClass => text().nullable()();
  IntColumn get colorValue => integer()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text()();
  TextColumn get sourceId => text().nullable()();
  BoolColumn get isLocallyModified =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'course_sessions_course_id', columns: {#courseId})
class CourseSessions extends Table {
  TextColumn get id => text()();
  TextColumn get courseId => text().references(Courses, #id)();
  IntColumn get weekday => integer()();
  IntColumn get startPeriod => integer()();
  IntColumn get endPeriod => integer()();
  TextColumn get location => text().nullable()();
  TextColumn get weeks => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'period_definitions_semester_period',
  columns: {#semesterId, #period},
  unique: true,
)
class PeriodDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get semesterId => text().references(Semesters, #id)();
  IntColumn get period => integer()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get periodGroup => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Semesters, Courses, CourseSessions, PeriodDefinitions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'schedulr'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
