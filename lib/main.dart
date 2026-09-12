import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrapper.dart';
import 'core/storage/app_database.dart';
import 'features/timetable/data/providers.dart';
import 'features/timetable/data/timetable_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = TimetableRepository(database);
  await AppBootstrapper(repository).ensureInitialData();

  runApp(
    ProviderScope(
      overrides: [timetableDatabaseProvider.overrideWithValue(database)],
      child: const SchedulrApp(),
    ),
  );
}
