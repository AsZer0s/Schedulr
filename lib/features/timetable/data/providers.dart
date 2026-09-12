import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart' show AppDatabase;
import '../domain/timetable_models.dart';
import 'timetable_repository.dart';

final timetableDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.watch(timetableDatabaseProvider));
});

final semestersProvider = StreamProvider<List<Semester>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchSemesters();
});

final currentSemesterProvider = StreamProvider<Semester?>((ref) {
  return ref.watch(timetableRepositoryProvider).watchCurrentSemester();
});

final semesterTimetableProvider =
    StreamProvider.family<SemesterTimetable?, String>((ref, semesterId) {
      return ref
          .watch(timetableRepositoryProvider)
          .watchSemesterTimetable(semesterId);
    });

final currentTimetableProvider = StreamProvider<SemesterTimetable?>((ref) {
  return ref.watch(timetableRepositoryProvider).watchCurrentTimetable();
});
