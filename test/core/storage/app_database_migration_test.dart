import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/core/storage/app_database.dart';
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates v1 database to v2 without losing timetable data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'schedulr-migration-',
    );
    final file = File('${directory.path}/schedulr.sqlite');
    addTearDown(() => directory.delete(recursive: true));

    final v1 = sqlite3.open(file.path);
    v1.execute('PRAGMA foreign_keys = ON');
    v1.execute('''
      CREATE TABLE semesters (
        id TEXT NOT NULL PRIMARY KEY,
        academic_year TEXT NOT NULL,
        term TEXT NOT NULL,
        name TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        teaching_weeks INTEGER NOT NULL,
        time_zone TEXT NOT NULL DEFAULT 'local',
        is_current INTEGER NOT NULL DEFAULT 0 CHECK (is_current IN (0, 1))
      )
    ''');
    v1.execute('''
      CREATE TABLE courses (
        id TEXT NOT NULL PRIMARY KEY,
        semester_id TEXT NOT NULL REFERENCES semesters(id),
        name TEXT NOT NULL,
        code TEXT,
        teacher TEXT,
        teaching_class TEXT,
        color_value INTEGER NOT NULL,
        notes TEXT,
        source TEXT NOT NULL,
        source_id TEXT,
        is_locally_modified INTEGER NOT NULL DEFAULT 0
          CHECK (is_locally_modified IN (0, 1))
      )
    ''');
    v1.execute('''
      CREATE TABLE course_sessions (
        id TEXT NOT NULL PRIMARY KEY,
        course_id TEXT NOT NULL REFERENCES courses(id),
        weekday INTEGER NOT NULL,
        start_period INTEGER NOT NULL,
        end_period INTEGER NOT NULL,
        location TEXT,
        weeks TEXT NOT NULL
      )
    ''');
    v1.execute(
      'CREATE INDEX course_sessions_course_id '
      'ON course_sessions (course_id)',
    );
    v1.execute('''
      CREATE TABLE period_definitions (
        id TEXT NOT NULL PRIMARY KEY,
        semester_id TEXT NOT NULL REFERENCES semesters(id),
        period INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        period_group TEXT NOT NULL
      )
    ''');
    v1.execute(
      'CREATE UNIQUE INDEX period_definitions_semester_period '
      'ON period_definitions (semester_id, period)',
    );
    v1.execute('''
      INSERT INTO semesters VALUES (
        'semester', '2026-2027', '1', '第一学期', 1788739200,
        20, 'Asia/Shanghai', 1
      )
    ''');
    v1.execute('''
      INSERT INTO courses VALUES (
        'course', 'semester', '高等数学', 'MATH101', '教师甲', '教学班 1',
        4282339765, '备注', 'zfsoft', 'source-course', 0
      )
    ''');
    v1.execute('''
      INSERT INTO course_sessions VALUES (
        'session', 'course', 1, 1, 2, 'A101', '1-2,4'
      )
    ''');
    v1.execute('''
      INSERT INTO period_definitions VALUES (
        'period', 'semester', 1, '08:00', '08:45', 'morning'
      )
    ''');
    v1.execute('PRAGMA user_version = 1');
    v1.close();

    final database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final repository = TimetableRepository(database);
    final timetable = await repository.getSemesterTimetable('semester');

    expect(database.schemaVersion, 2);
    expect(timetable, isNotNull);
    expect(timetable!.semester.timetableName, '我的课表');
    expect(timetable.semester.isCurrent, isTrue);
    expect(timetable.semester.timeZone, 'Asia/Shanghai');
    expect(timetable.courses.single.course.name, '高等数学');
    expect(timetable.courses.single.sessions.single.id, 'session');
    expect(timetable.courses.single.sessions.single.weeks, {1, 2, 4});
    expect(timetable.periodDefinitions.single.id, 'period');

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data['user_version'], 2);
    final foreignKeyErrors = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    expect(foreignKeyErrors, isEmpty);
  });
}
