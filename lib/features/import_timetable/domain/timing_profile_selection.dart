import 'imported_period_schedule.dart';
import 'imported_timetable_entry.dart';

final class TimingProfileSelection {
  TimingProfileSelection({
    required Iterable<ImportedTimingProfile> options,
    required this.defaultProfile,
  }) : options = List.unmodifiable(options);

  final List<ImportedTimingProfile> options;
  final ImportedTimingProfile? defaultProfile;

  bool get requiresUserChoice => options.length > 1;
}

/// Removes profiles with identical schedules while preserving source order,
/// then chooses the profile referenced by the largest number of course entries.
TimingProfileSelection selectTimingProfilesForImport({
  required Iterable<ImportedTimingProfile> profiles,
  required Iterable<ImportedTimetableEntry> entries,
}) {
  final valid = profiles
      .where((profile) => profile.hasValidSchedule)
      .toList(growable: false);
  final unique = <ImportedTimingProfile>[];
  for (final profile in valid) {
    if (!unique.any((item) => item.schedule == profile.schedule)) {
      unique.add(profile);
    }
  }
  if (unique.isEmpty) {
    return TimingProfileSelection(options: const [], defaultProfile: null);
  }

  final counts = <String, int>{};
  for (final entry in entries) {
    final id = entry.timingProfileId;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  final selected = unique.reduce(
    (first, second) =>
        (counts[second.id] ?? 0) > (counts[first.id] ?? 0) ? second : first,
  );
  return TimingProfileSelection(options: unique, defaultProfile: selected);
}
