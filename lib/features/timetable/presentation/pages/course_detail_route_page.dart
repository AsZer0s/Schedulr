import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/adaptive_scaffold.dart';

import '../../../course_editor/presentation/course_detail_page.dart';
import '../../data/providers.dart';
import '../../domain/course_with_sessions.dart';

class CourseDetailRoutePage extends ConsumerWidget {
  const CourseDetailRoutePage({required this.courseId, super.key});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetable = ref.watch(currentTimetableProvider);
    return timetable.when(
      loading: () => const AdaptiveStatusPage(message: '', loading: true),
      error: (error, _) => const AdaptiveStatusPage(message: '课程读取失败'),
      data: (value) {
        final course = value?.courses
            .where((entry) => entry.course.id == courseId)
            .firstOrNull;
        if (course == null) {
          return const AdaptiveStatusPage(message: '课程不存在或已被删除');
        }
        return CourseDetailPage(
          course: course,
          periodDefinitions: value?.periodDefinitions ?? const [],
          onEdit: () => context.push('/course/$courseId/edit'),
          onDelete: () async {
            await ref.read(timetableRepositoryProvider).deleteCourse(courseId);
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
