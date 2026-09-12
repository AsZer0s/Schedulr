import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/app/app.dart';
import 'package:schedulr/features/timetable/data/providers.dart';
import 'package:schedulr/features/timetable/domain/timetable_models.dart';

void main() {
  testWidgets('app starts with an empty local semester', (tester) async {
    final semester = Semester(
      id: 'test-semester',
      academicYear: '2026-2027',
      term: '1',
      name: '测试学期',
      startDate: DateTime(2026, 9, 7),
      teachingWeeks: 20,
      isCurrent: true,
    );
    final timetable = SemesterTimetable(
      semester: semester,
      courses: const [],
      periodDefinitions: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateProvider.overrideWithValue(DateTime(2026, 9, 12)),
          currentTimetableProvider.overrideWith(
            (ref) => Stream.value(timetable),
          ),
        ],
        child: const SchedulrApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('课程表'), findsOneWidget);
    expect(find.text('本周暂无课程'), findsOneWidget);
    expect(find.text('添加课程'), findsOneWidget);
  });
}
