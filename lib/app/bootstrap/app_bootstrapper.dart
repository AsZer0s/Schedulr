import 'package:uuid/uuid.dart';

import '../../features/timetable/data/timetable_repository.dart';
import '../../features/timetable/domain/timetable_models.dart';

class AppBootstrapper {
  const AppBootstrapper(this.repository);

  final TimetableRepository repository;

  Future<void> ensureInitialData() async {
    final semesters = await repository.getSemesters();
    if (semesters.isNotEmpty) return;

    final semester = Semester(
      id: const Uuid().v4(),
      academicYear: '2026-2027',
      term: '1',
      name: '2026-2027 第一学期',
      timetableName: '我的课表',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
      isCurrent: true,
    );

    await repository.replaceSemesterTimetable(
      SemesterTimetable(
        semester: semester,
        courses: const [],
        periodDefinitions: _defaultPeriods(semester.id),
      ),
    );
  }

  List<PeriodDefinition> _defaultPeriods(String semesterId) {
    const times = <(String, String, PeriodGroup)>[
      ('08:00', '08:45', PeriodGroup.morning),
      ('08:55', '09:40', PeriodGroup.morning),
      ('10:00', '10:45', PeriodGroup.morning),
      ('10:55', '11:40', PeriodGroup.morning),
      ('14:00', '14:45', PeriodGroup.afternoon),
      ('14:55', '15:40', PeriodGroup.afternoon),
      ('16:00', '16:45', PeriodGroup.afternoon),
      ('16:55', '17:40', PeriodGroup.afternoon),
      ('19:00', '19:45', PeriodGroup.evening),
      ('19:55', '20:40', PeriodGroup.evening),
      ('20:50', '21:35', PeriodGroup.evening),
      ('21:45', '22:30', PeriodGroup.evening),
    ];

    return [
      for (var index = 0; index < times.length; index++)
        PeriodDefinition(
          id: '$semesterId-period-${index + 1}',
          semesterId: semesterId,
          period: index + 1,
          startTime: times[index].$1,
          endTime: times[index].$2,
          group: times[index].$3,
        ),
    ];
  }
}
