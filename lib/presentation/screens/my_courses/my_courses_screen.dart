import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';
import '../learning/learning_space_screen.dart';
import 'certificate_screen.dart';

/// Tab 3: Khóa học của tôi (My Learning) theo QuyChuanThietKe_App.md Mục 4.7 & UC8
class MyCoursesScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const MyCoursesScreen({super.key, this.onNavigateTab});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inProgressCourses =
        MockData.allCourses.where((c) => c.isEnrolled && !c.isCompleted).toList();
    final completedCourses =
        MockData.allCourses.where((c) => c.isEnrolled && c.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TabBar 2 mục: Đang học & Đã hoàn thành
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3.0,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.0,
                ),
                tabs: [
                  Tab(text: 'Đang học (${inProgressCourses.length})'),
                  Tab(text: 'Đã hoàn thành (${completedCourses.length})'),
                ],
              ),
            ),

            // TabBarView hiển thị danh sách
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Tab Đang học
                  _buildInProgressTab(inProgressCourses),

                  // 2. Tab Đã hoàn thành
                  _buildCompletedTab(completedCourses),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện Tab Đang học
  Widget _buildInProgressTab(List<Course> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 44,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Bạn chưa sở hữu khóa học nào',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Hãy tìm kiếm và đăng ký khóa học bạn yêu thích để bắt đầu học tập.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20.0),
              AppButton(
                text: 'Khám phá khóa học ngay',
                width: 220,
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      physics: const BouncingScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusCard,
            border: Border.all(color: AppColors.border),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: SizedBox(
                        width: 90,
                        height: 65,
                        child: Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            course.instructor,
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Thanh tiến độ %
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999.0),
                        child: LinearProgressIndicator(
                          value: course.progress / 100.0,
                          backgroundColor: AppColors.surfaceSubtle,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Text(
                      '${course.progress.toInt()}% Hoàn thành',
                      style: AppTypography.captionTiny.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Nút Tiếp tục học
                AppButton(
                  text: 'Tiếp tục học',
                  height: 44.0,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LearningSpaceScreen(course: course),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Giao diện Tab Đã hoàn thành (Xem chứng chỉ)
  Widget _buildCompletedTab(List<Course> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.p32),
          child: Text(
            'Bạn chưa hoàn thành khóa học nào. Hãy tiếp tục cố gắng nhé!',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.p16),
      physics: const BouncingScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimens.p16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusCard,
            border: Border.all(color: AppColors.border),
            boxShadow: AppDimens.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: SizedBox(
                        width: 90,
                        height: 65,
                        child: Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '✓ ĐÃ HOÀN THÀNH 100%',
                              style: AppTypography.captionTiny.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            course.instructor,
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Nút Xem chứng chỉ tốt nghiệp
                AppButton(
                  text: 'Xem chứng chỉ',
                  height: 44.0,
                  type: AppButtonType.secondary,
                  icon: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CertificateScreen(course: course),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
