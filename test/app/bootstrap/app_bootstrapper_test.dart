import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/app/bootstrap/app_bootstrapper.dart';
import 'package:schedulr/core/storage/app_database.dart' show AppDatabase;
import 'package:schedulr/features/timetable/data/timetable_repository.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  test(
    'resolver only reads and reports onboarding for an empty repository',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = TimetableRepository(database);

      expect(
        await AppBootstrapper(repository).resolve(),
        AppBootstrapState.needsOnboarding,
      );
      expect(await repository.getSemesters(), isEmpty);
    },
  );

  test('resolver reports ready without changing existing data', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = TimetableRepository(database);
    final semester = Semester(
      id: 'existing',
      academicYear: '2030-2031',
      term: '2',
      name: '现有学期',
      timetableName: '现有课表',
      startDate: DateTime(2031, 2, 17),
      teachingWeeks: 18,
      isCurrent: true,
    );
    await repository.upsertSemester(semester);

    expect(
      await AppBootstrapper(repository).resolve(),
      AppBootstrapState.ready,
    );
    expect(await repository.getSemesters(), [semester]);
  });
}
