import 'package:flutter_test/flutter_test.dart';
import 'package:schedulr/features/import_timetable/domain/import_timetable.dart';

void main() {
  test('相同 schedule 自动去重并保留首个 profile', () {
    final schedule = _schedule('08:00');
    final selection = selectTimingProfilesForImport(
      profiles: [
        ImportedTimingProfile(id: 'profile-0', name: '甲校区', schedule: schedule),
        ImportedTimingProfile(id: 'profile-1', name: '乙校区', schedule: schedule),
      ],
      entries: const [],
    );

    expect(selection.options.map((profile) => profile.id), ['profile-0']);
    expect(selection.requiresUserChoice, isFalse);
  });

  test('不同 schedule 默认选择课程 entry 数最多的 profile', () {
    final selection = selectTimingProfilesForImport(
      profiles: [
        ImportedTimingProfile(
          id: 'profile-0',
          name: '甲校区',
          schedule: _schedule('08:00'),
        ),
        ImportedTimingProfile(
          id: 'profile-1',
          name: '乙校区',
          schedule: _schedule('08:30'),
        ),
      ],
      entries: [
        _entry('a', 'profile-0'),
        _entry('b', 'profile-1'),
        _entry('c', 'profile-1'),
      ],
    );

    expect(selection.requiresUserChoice, isTrue);
    expect(selection.defaultProfile?.id, 'profile-1');
  });
}

ImportedPeriodSchedule _schedule(String startTime) => ImportedPeriodSchedule(
  periods: [
    ImportedPeriod(
      number: 1,
      startTime: startTime,
      endTime: '09:15',
      group: ImportedPeriodGroup.morning,
    ),
  ],
);

ImportedTimetableEntry _entry(String id, String profileId) =>
    ImportedTimetableEntry(
      externalId: id,
      title: '虚构课程 $id',
      dayOfWeek: 1,
      startPeriod: 1,
      endPeriod: 1,
      weeks: const {1},
      timingProfileId: profileId,
    );
