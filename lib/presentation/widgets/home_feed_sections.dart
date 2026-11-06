import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/course.dart';
import '../../data/models/home_feed.dart';
import 'course_card.dart';

Widget homeSectionHeader(
  String title,
  String subtitle, {
  VoidCallback? onSeeAll,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text(
                'Xem tất cả >',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// "Tiếp tục học": các khóa đang học dở, kèm tiến độ và bài đang dừng.
class HomeContinueSection extends StatelessWidget {
  final HomeSection section;
  final ValueChanged<HomeContinueItem> onOpen;

  const HomeContinueSection({
    super.key,
    required this.section,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        homeSectionHeader(section.title, section.subtitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: section.continues.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, i) => _ContinueCard(
              item: section.continues[i],
              onTap: () => onOpen(section.continues[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final HomeContinueItem item;
  final VoidCallback onTap;

  const _ContinueCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = item.progress.clamp(0, 100).toDouble();
    final lesson = item.lessonTitle.isEmpty
        ? 'Bắt đầu học'
        : (item.lessonNumber > 0
              ? 'Bài ${item.lessonNumber}: ${item.lessonTitle}'
              : item.lessonTitle);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 264,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: double.infinity,
              child: Image.network(
                ApiConfig.resolveMediaUrl(item.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.primaryLight,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.primaryLight,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percent.round()}% hoàn thành',
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mục khóa học cuộn ngang (bán chạy, vì bạn đã học, đánh giá cao, mới ra mắt,
/// yêu thích, đã xem gần đây). Nhãn nằm trên ảnh, ghi chú nằm dưới thẻ.
class HomeCourseRail extends StatelessWidget {
  final HomeSection section;
  final ValueChanged<Course> onTap;
  final VoidCallback? onSeeAll;

  const HomeCourseRail({
    super.key,
    required this.section,
    required this.onTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = section.courses.any((c) => (c.note ?? '').isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        homeSectionHeader(section.title, section.subtitle, onSeeAll: onSeeAll),
        const SizedBox(height: 12),
        SizedBox(
          height: hasNote ? 340 : 310,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
            scrollDirection: Axis.horizontal,
            itemCount: section.courses.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppDimens.p12),
            itemBuilder: (context, i) {
              final item = section.courses[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 310,
                    child: CourseCard(
                      course: item.course,
                      badges: [if (item.badge != null) item.badge!],
                      onTap: () => onTap(item.course),
                    ),
                  ),
                  if (hasNote) _NoteRow(item: item),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  final HomeCourseItem item;

  const _NoteRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final note = item.note ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: 260,
        child: Row(
          children: [
            if (note.isNotEmpty)
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
