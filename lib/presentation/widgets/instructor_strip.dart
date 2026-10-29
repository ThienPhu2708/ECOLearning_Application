import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/course.dart';
import '../screens/instructor/instructor_screen.dart';

/// Một giảng viên được gom từ danh sách khóa học (API chưa có endpoint giảng viên).
class InstructorEntry {
  final Course course; // khóa đại diện, mang thông tin giảng viên
  final int courseCount;

  const InstructorEntry(this.course, this.courseCount);

  String get name => course.instructor;

  /// Gom các khóa theo tên giảng viên, nhiều khóa nhất lên đầu.
  static List<InstructorEntry> group(Iterable<Course> courses) {
    final reps = <String, Course>{};
    final counts = <String, int>{};
    for (final c in courses) {
      final name = c.instructor.trim();
      if (name.isEmpty) continue;
      reps.putIfAbsent(name, () => c);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return [for (final e in reps.entries) InstructorEntry(e.value, counts[e.key]!)]
      ..sort((a, b) => b.courseCount.compareTo(a.courseCount));
  }
}

/// Dải giảng viên cuộn ngang; bấm vào mở hồ sơ giảng viên.
class InstructorStrip extends StatelessWidget {
  final List<InstructorEntry> instructors;

  const InstructorStrip({super.key, required this.instructors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
        scrollDirection: Axis.horizontal,
        itemCount: instructors.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.p12),
        itemBuilder: (context, i) {
          final entry = instructors[i];
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => InstructorScreen(course: entry.course),
              ),
            ),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: entry.course.instructorAvatar.isEmpty
                        ? null
                        : NetworkImage(entry.course.instructorAvatar),
                    onBackgroundImageError: (_, _) {},
                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionTiny.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                  Text(
                    '${entry.courseCount} khóa học',
                    maxLines: 1,
                    style: AppTypography.captionTiny.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
