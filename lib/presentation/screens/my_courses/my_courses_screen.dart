import '../../widgets/list_search_field.dart';
import '../../widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/learning_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../learning/learning_space_screen.dart';
import '../course_detail/course_detail_screen.dart';
import '../instructor/instructor_screen.dart';
import '../quiz/quiz_intro_screen.dart';
import 'my_courses_controller.dart';
import 'certificate_screen.dart';
import '../learning/review_flow.dart';
import '../quiz/quiz_results_screen.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/review_repository.dart';

/// G1: owned courses from the API, without a mock-data fallback.
class MyCoursesScreen extends StatefulWidget {
  final bool isActive;
  final int initialTabIndex;
  final Function(int tabIndex)? onNavigateTab;
  final LearningRepository? repository;
  final QuizRepository? quizRepository;
  final CourseRepository? courseRepository;
  final ReviewRepository? reviews;
  final Future<void> Function(Course course)? onOpenLearning;

  const MyCoursesScreen({
    super.key,
    this.isActive = true,
    this.initialTabIndex = 0,
    this.onNavigateTab,
    this.repository,
    this.quizRepository,
    this.courseRepository,
    this.reviews,
    this.onOpenLearning,
  });

  @override
  State<MyCoursesScreen> createState() => MyCoursesScreenState();
}

class MyCoursesScreenState extends State<MyCoursesScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;
  late final MyCoursesController _controller;
  String? _openingId;
  bool _reviewOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _controller = MyCoursesController(
      widget.repository ??
          LearningDataScope.read(context)?.learning ??
          LearningRepository(),
    );
    _controller.load();
  }

  void showTab(int index) => _tabs.animateTo(index.clamp(0, 2));

  @override
  void didUpdateWidget(covariant MyCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _controller.load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openLearning(Course course) async {
    if (_openingId != null) return;
    setState(() => _openingId = course.id);
    try {
      if (widget.onOpenLearning != null) {
        await widget.onOpenLearning!(course);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LearningSpaceScreen(course: course),
          ),
        );
      }
      if (mounted) await _controller.load();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _openQuiz(Course course) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizIntroScreen(
          courseId: course.id,
          repository: widget.quizRepository,
        ),
      ),
    );
    if (mounted) await _controller.load();
  }

  Future<void> _openCoursePage(Course course, Widget screen) async {
    if (_openingId != null) return;
    setState(() => _openingId = course.id);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => screen),
      );
      if (mounted) await _controller.load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  Future<void> _openReview(Course course) async {
    if (_openingId != null || _reviewOpen) return;
    _reviewOpen = true;
    try {
      final scope = LearningDataScope.read(context);
      await openCourseReview(
        context,
        course,
        courses:
            widget.courseRepository ?? scope?.courses ?? CourseRepository(),
        reviews: widget.reviews ?? scope?.reviews ?? ReviewRepository(),
      );
      if (mounted) await _controller.load();
    } finally {
      _reviewOpen = false;
    }
  }

  String _tabLabel(String label, int? total) =>
      total == null ? label : '$label ($total)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              ListSearchField(
                hint: 'Tìm tên khóa học, giảng viên...',
                onChanged: _controller.search,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEFF5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0F172A),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: [
                    Tab(text: _tabLabel('Đang học', _controller.ongoing.total)),

                    Tab(
                      text: _tabLabel(
                        'Đã học đủ bài',
                        _controller.completed.total,
                      ),
                    ),
                    Tab(
                      text: _tabLabel(
                        'Đã nhận chứng chỉ',
                        _controller.certified.total,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildList(MyCourseStatus.inProgress),
                    _buildList(MyCourseStatus.completed),
                    _buildList(MyCourseStatus.certified),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(String status) {
    final state = _controller.stateFor(status);
    final completed = status != MyCourseStatus.inProgress;
    if (state.loading && state.courses.isEmpty) {
      return const LoadingView(message: 'Đang tải khóa học…');
    }
    if (state.error != null && state.courses.isEmpty) {
      return ErrorView(
        error: state.error,
        onRetry: () => _controller.refresh(status),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _controller.refresh(status),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (state.courses.isEmpty) {
            return ListView(
              key: PageStorageKey(status),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: constraints.maxHeight,
                  child: EmptyView(
                    icon: completed
                        ? Icons.task_alt_rounded
                        : Icons.menu_book_rounded,
                    title: _controller.query.isNotEmpty
                        ? 'Không tìm thấy khóa học'
                        : status == MyCourseStatus.certified
                        ? 'Bạn chưa nhận chứng chỉ nào'
                        : completed
                        ? 'Chưa có khóa học hoàn tất'
                        : 'Chưa có khóa học đang học',
                    message: _controller.query.isNotEmpty
                        ? 'Thử tên khóa học hoặc giảng viên khác nha.'
                        : status == MyCourseStatus.certified
                        ? 'Các khóa có chứng chỉ hợp lệ sẽ xuất hiện tại đây.'
                        : completed
                        ? 'Các khóa học đủ 100% bài học và chưa nhận chứng chỉ sẽ xuất hiện tại đây.'
                        : 'Khám phá khóa học mới hoặc xem lại các khóa đã học đủ bài.',
                    actionText: completed
                        ? 'Xem khóa đang học'
                        : 'Khám phá khóa học',
                    onAction: completed
                        ? () => _tabs.animateTo(0)
                        : widget.onNavigateTab == null
                        ? null
                        : () => widget.onNavigateTab!(1),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            key: PageStorageKey(status),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.courses.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (state.error != null) {
                  return _InlineRetry(
                    error: state.error!,
                    onRetry: () => _controller.refresh(status),
                  );
                }
                return state.loading
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(),
                      )
                    : const SizedBox.shrink();
              }
              if (index <= state.courses.length) {
                final course = state.courses[index - 1];
                return _LearningCourseCard(
                  key: ValueKey(course.id),
                  course: course,
                  completed: completed,
                  opening: _openingId == course.id,
                  onLearn: _openingId == null
                      ? () => _openLearning(course)
                      : null,
                  onQuiz: () => _openQuiz(course),
                  onCertificate: _openingId != null
                      ? null
                      : () => _openCoursePage(
                          course,
                          CertificateScreen(
                            course: course,
                            repository: widget.quizRepository,
                          ),
                        ),
                  onResults: _openingId != null
                      ? null
                      : () => _openCoursePage(
                          course,
                          QuizResultsScreen(
                            courseId: course.id,
                            repository: widget.quizRepository,
                          ),
                        ),
                  onReview: !completed || _openingId != null
                      ? null
                      : () => _openReview(course),
                );
              }
              if (state.loadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.moreError != null) {
                return _InlineRetry(
                  error: state.moreError!,
                  onRetry: () => _controller.loadMore(status),
                );
              }
              return PaginationBar(
                page: state.page,
                totalPages: state.totalPages,
                enabled: !state.loading,
                onPageChanged: (page) =>
                    _controller.refresh(status, page: page),
              );
            },
          );
        },
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _InlineRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.warningLight,
      borderRadius: AppDimens.radiusInput,
    ),
    child: Row(
      children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(errorMessage(error), style: AppTypography.labelSmall),
        ),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

class _LearningCourseCard extends StatelessWidget {
  final Course course;
  final bool completed;
  final bool opening;
  final VoidCallback? onLearn;
  final VoidCallback onQuiz;
  final VoidCallback? onCertificate, onResults, onReview;
  const _LearningCourseCard({
    super.key,
    required this.course,
    required this.completed,
    required this.opening,
    required this.onLearn,
    required this.onQuiz,
    required this.onCertificate,
    required this.onResults,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    // Match the web's certified card even if new lessons lower the API percentage.
    final progress = completed && course.hasCertificate
        ? 100.0
        : course.progress.isFinite
        ? course.progress.clamp(0, 100).toDouble()
        : 0.0;
    final tint = completed ? AppColors.success : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 144,
                child: course.imageUrl.isEmpty
                    ? _imageFallback()
                    : Image.network(
                        course.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imageFallback(),
                        loadingBuilder: (_, child, event) =>
                            event == null ? child : _imageFallback(),
                      ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .25),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 14,
                        color: tint,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        completed ? 'Đã học đủ bài' : 'Đang học',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.category.isNotEmpty) ...[
                  Text(
                    course.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      letterSpacing: .5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(course: course),
                    ),
                  ),
                  child: Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (course.instructor.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InstructorScreen(course: course),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: _meta(
                            Icons.person_outline_rounded,
                            course.instructor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tiến độ học tập',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${progress.floor()}%',
                            style: AppTypography.bodyMedium.copyWith(
                              color: tint,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Semantics(
                        label: 'Tiến độ học tập',
                        value: '${progress.floor()} phần trăm',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(tint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (completed) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        course.hasCertificate
                            ? Icons.verified_outlined
                            : Icons.quiz_outlined,
                        color: tint,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          course.hasCertificate
                              ? 'Đã cấp chứng chỉ'
                              : course.pendingQuizReview
                              ? 'Chờ giáo viên xem xét kết quả quiz'
                              : course.quizRetakeRequired
                              ? 'Giáo viên yêu cầu làm lại quiz'
                              : 'Kiểm tra điều kiện nhận chứng chỉ của khóa học.',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (completed && course.hasCertificate)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: opening ? null : onCertificate,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: opening
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_outlined,
                                        size: 19,
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Xem chứng chỉ',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Thao tác khóa học',
                          enabled: !opening && onCertificate != null,
                          icon: const Icon(Icons.more_horiz_rounded),
                          onSelected: (action) {
                            if (action == 'learn') onLearn?.call();
                            if (action == 'results') onResults?.call();
                            if (action == 'review') onReview?.call();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'learn',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.play_lesson_outlined),
                                title: Text('Xem lại bài học'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'results',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.fact_check_outlined),
                                title: Text('Kết quả quiz'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'review',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.star_outline_rounded),
                                title: Text('Đánh giá của tôi'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  AppButton(
                    text: completed
                        ? (course.pendingQuizReview
                              ? 'Xem trạng thái quiz'
                              : course.quizRetakeRequired
                              ? 'Làm lại quiz'
                              : 'Làm quiz cuối khóa')
                        : progress > 0
                        ? 'Tiếp tục học'
                        : 'Bắt đầu học',
                    icon: Icon(
                      completed
                          ? Icons.quiz_outlined
                          : Icons.play_arrow_rounded,
                      size: 20,
                    ),
                    height: 48,
                    isLoading: !completed && opening,
                    onPressed: completed ? onQuiz : onLearn,
                  ),
                  if (completed) ...[
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Đánh giá khóa học',
                      type: AppButtonType.secondary,
                      onPressed: onReview,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Kiểm tra chứng chỉ',
                      type: AppButtonType.secondary,
                      onPressed: opening ? null : onCertificate,
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Xem lại bài học',
                      type: AppButtonType.secondary,
                      height: 44,
                      isLoading: opening,
                      onPressed: onLearn,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w400),
        ),
      ),
    ],
  );

  Widget _imageFallback() => const ColoredBox(
    color: AppColors.primaryLight,
    child: Center(
      child: Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 30),
    ),
  );
}
