import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/adaptive_scaffold.dart';

import '../../../course_editor/presentation/course_editor_page.dart';
import '../../data/providers.dart';
import '../../domain/course_conflict_report.dart';
import '../../domain/course_with_sessions.dart';

class CourseEditorRoutePage extends ConsumerWidget {
  const CourseEditorRoutePage({this.courseId, super.key});

  final String? courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetable = ref.watch(currentTimetableProvider);
    return timetable.when(
      loading: () => const AdaptiveStatusPage(message: '', loading: true),
      error: (error, _) => const AdaptiveStatusPage(message: '课程读取失败'),
      data: (value) {
        if (value == null) {
          return const AdaptiveStatusPage(message: '尚未初始化学期');
        }
        final initialCourse = courseId == null
            ? null
            : value.courses
                  .where((entry) => entry.course.id == courseId)
                  .firstOrNull;
        if (courseId != null && initialCourse == null) {
          return const AdaptiveStatusPage(message: '课程不存在');
        }
        return CourseEditorPage(
          semester: value.semester,
          periodDefinitions: value.periodDefinitions,
          initialCourse: initialCourse,
          saveWithConflictCheck:
              (course, {required Set<String> acceptedConflictKeys}) async {
                final result = await ref
                    .read(timetableRepositoryProvider)
                    .saveCourseWithConflictCheck(
                      course,
                      acceptedConflictKeys: acceptedConflictKeys,
                    );
                if (result is CourseSaved && context.mounted) {
                  context.pop();
                }
                return result;
              },
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
