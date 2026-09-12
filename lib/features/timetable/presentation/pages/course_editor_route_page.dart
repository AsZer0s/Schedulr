import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../course_editor/presentation/course_editor_page.dart';
import '../../data/providers.dart';
import '../../domain/course_with_sessions.dart';

class CourseEditorRoutePage extends ConsumerWidget {
  const CourseEditorRoutePage({this.courseId, super.key});

  final String? courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetable = ref.watch(currentTimetableProvider);
    return timetable.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const Scaffold(body: Center(child: Text('课程读取失败'))),
      data: (value) {
        if (value == null) {
          return const Scaffold(body: Center(child: Text('尚未初始化学期')));
        }
        final initialCourse = courseId == null
            ? null
            : value.courses
                  .where((entry) => entry.course.id == courseId)
                  .firstOrNull;
        if (courseId != null && initialCourse == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('课程不存在')),
          );
        }
        return CourseEditorPage(
          semester: value.semester,
          initialCourse: initialCourse,
          onSave: (course) async {
            await ref.read(timetableRepositoryProvider).upsertCourse(course);
            if (context.mounted) context.pop();
          },
          onDelete: initialCourse == null
              ? null
              : () async {
                  await ref
                      .read(timetableRepositoryProvider)
                      .deleteCourse(initialCourse.course.id);
                  if (context.mounted) context.go('/');
                },
        );
      },
    );
  }
}

extension on Iterable<CourseWithSessions> {
  CourseWithSessions? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
