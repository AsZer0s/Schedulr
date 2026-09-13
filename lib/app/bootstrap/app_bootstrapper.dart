import '../../features/timetable/data/timetable_repository.dart';

enum AppBootstrapState { needsOnboarding, ready }

class AppBootstrapper {
  const AppBootstrapper(this.repository);

  final TimetableRepository repository;

  Future<AppBootstrapState> resolve() async {
    final semesters = await repository.getSemesters();
    return semesters.isEmpty
        ? AppBootstrapState.needsOnboarding
        : AppBootstrapState.ready;
  }
}
