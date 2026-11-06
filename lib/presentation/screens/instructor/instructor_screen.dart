import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/models/course.dart';
import '../../../data/models/instructor_profile.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/instructor_repository.dart';
import '../learning_support/learning_data_scope.dart';
import '../../widgets/course_card.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';

/// Hồ sơ giảng viên, giống trang "Thông tin Giáo viên" trên web.
///
class InstructorScreen extends StatefulWidget {
  final Course course; // khóa học đang xem, mang theo thông tin giảng viên
  final CourseRepository? courseRepository;
  final InstructorRepository? instructorRepository;

  const InstructorScreen({
    super.key,
    required this.course,
    this.courseRepository,
    this.instructorRepository,
  });

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen> {
  late final _repo =
      widget.courseRepository ??
      LearningDataScope.read(context)?.courses ??
      CourseRepository();
  late final _instructors =
      widget.instructorRepository ?? InstructorRepository();
  InstructorProfile? _profile;
  int _generation = 0;
  bool _reviewsLoading = false;
  Object? _reviewsError;

  bool _loading = true;
  Object? _error;
  List<Course> _courses = [];

  // Đánh giá của học viên về các khóa của giảng viên (B4), mới nhất trước
  List<_InstructorReview> _reviews = [];
  int _shownReviews = 5;

  // Mục đang mở khi bấm vào số liệu ở đầu trang: null = chưa mở, 0 = khóa học, 1 = đánh giá
  int? _panel;
  int _coursePage = 1;
  String _courseFilter =
      'all'; // all | top (từ 4 sao) | popular (nhiều học viên) | sale
  int _starFilter = 0; // 0 = mọi đánh giá, 1..5 = chỉ đúng số sao đó
  bool _aboutExpanded = false;

  String get _name => _profile?.name ?? widget.course.instructor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var id = widget.course.instructorId;
      if (id.isEmpty && widget.course.id.isNotEmpty) {
        id = (await _repo.detail(widget.course.id)).instructorId;
      }
      if (id.isEmpty) id = await _instructors.findId(widget.course.instructor);
      final profile = await _instructors.profile(id);
      if (!mounted || generation != _generation) return;
      setState(() {
        _profile = profile;
        _courses = profile.courses;
        _reviews = [];
        _reviewsError = null;
        _loading = false;
      });
      _loadReviews(generation);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// API hồ sơ chưa có danh sách đánh giá, tải đầy đủ các trang theo từng khóa.
  Future<void> _loadReviews(int generation) async {
    if (!mounted || generation != _generation) return;
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    final withReviews = _courses.where((c) => c.reviewCount > 0).toList();
    final merged = <_InstructorReview>[];
    try {
      for (final c in withReviews) {
        var page = 1;
        while (true) {
          final data = await _repo.reviews(c.id, page: page);
          if (!mounted || generation != _generation) return;
          for (final r in JsonUtils.asMapList(data['items'])) {
            merged.add(
              _InstructorReview(
                userName: JsonUtils.asString(
                  r['userName'],
                  fallback: 'Học viên',
                ),
                rating: JsonUtils.asDouble(r['rating']),
                comment: JsonUtils.asString(r['comment']),
                createdAt: JsonUtils.asDate(r['createdAt']),
                courseTitle: c.title,
              ),
            );
          }
          final current = JsonUtils.asInt(data['page'], fallback: 1);
          final total = JsonUtils.asInt(data['totalPages'], fallback: 1);
          if (current != page) {
            throw const FormatException('Invalid review page');
          }
          if (current >= total) break;
          page++;
        }
      }
      merged.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
      if (mounted && generation == _generation) {
        setState(() => _reviews = merged);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _reviewsError = error);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _reviewsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  int get _totalReviews => _profile?.reviewCount ?? 0;

  /// Điểm trung bình theo số lượt đánh giá của từng khóa
  double get _rating => _profile?.rating ?? 0;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Thông tin giảng viên',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppDimens.p16),
          children: [
            _buildHeader(course),
            const SizedBox(height: AppDimens.p16),
            _buildAbout(course),
            const SizedBox(height: AppDimens.p16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppDimens.p32),
                child: LoadingView(),
              )
            else if (_error != null)
              ErrorView(error: _error, onRetry: _load)
            else ...[
              if (_panel == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.p8),
                  child: Text(
                    'Bấm vào số khóa học hoặc số lượt đánh giá ở trên để xem chi tiết.',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionTiny.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else if (_panel == 0)
                ..._buildCourseTab()
              else
                _buildReviews(),
            ],
          ],
        ),
      ),
    );
  }

  bool _onSale(Course c) => c.originalPrice > c.price;

  bool _isTop(Course c) => c.rating >= 4.0 && c.reviewCount > 0;

  List<Course> get _visibleCourses {
    switch (_courseFilter) {
      case 'top':
        return _courses.where(_isTop).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
      case 'popular':
        return _courses.where((c) => c.studentsCount > 0).toList()
          ..sort((a, b) => b.studentsCount.compareTo(a.studentsCount));
      case 'sale':
        return _courses.where(_onSale).toList();
      default:
        return _courses;
    }
  }

  int get _courseTotalPages =>
      (_visibleCourses.length / ApiConfig.defaultPageSize).ceil().clamp(
        1,
        1000,
      );

  List<Widget> _buildCourseTab() {
    final onSaleCount = _courses.where(_onSale).length;
    final list = _visibleCourses;
    final size = ApiConfig.defaultPageSize;
    final start = (_coursePage - 1) * size;
    final pageItems = list.skip(start).take(size).toList();

    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: selected ? Colors.white : AppColors.textHeading,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13.0,
      ),
      onSelected: (_) => onTap(),
    );

    void pick(String f) => setState(() {
      _courseFilter = f;
      _coursePage = 1;
    });

    return [
      Wrap(
        spacing: AppDimens.p8,
        runSpacing: AppDimens.p4,
        children: [
          chip(
            'Tất cả (${_courses.length})',
            _courseFilter == 'all',
            () => pick('all'),
          ),
          chip(
            'Được đánh giá cao (${_courses.where(_isTop).length})',
            _courseFilter == 'top',
            () => pick('top'),
          ),
          chip(
            'Học nhiều (${_courses.where((c) => c.studentsCount > 0).length})',
            _courseFilter == 'popular',
            () => pick('popular'),
          ),
          chip(
            'Đang giảm giá ($onSaleCount)',
            _courseFilter == 'sale',
            () => pick('sale'),
          ),
        ],
      ),
      const SizedBox(height: AppDimens.p12),
      if (list.isEmpty)
        EmptyView(
          icon: Icons.local_offer_outlined,
          title: switch (_courseFilter) {
            'top' => 'Chưa có khóa được đánh giá từ 4 sao',
            'popular' => 'Chưa có khóa nào có học viên',
            'sale' => 'Chưa có khóa đang giảm giá',
            _ => 'Chưa có khóa học đang mở bán',
          },
        )
      else ...[
        for (final c in pageItems)
          CourseCard(
            course: c,
            layout: CourseCardLayout.listHorizontal,
            onTap: () =>
                CourseDetailScreen.open(context, c, ClickSource.search),
          ),
        PaginationBar(
          page: _coursePage,
          totalPages: _courseTotalPages,
          onPageChanged: (p) => setState(() => _coursePage = p),
        ),
      ],
    ];
  }

  Widget _buildReviews() {
    if (_reviewsLoading) {
      return const LoadingView(message: 'Đang tải đánh giá…');
    }
    if (_reviewsError != null) {
      return ErrorView(
        error: _reviewsError,
        onRetry: () => _loadReviews(_generation),
      );
    }
    if (_reviews.isEmpty) {
      return const EmptyView(
        icon: Icons.rate_review_outlined,
        title: 'Chưa có đánh giá',
        message:
            'Các khóa của giảng viên này chưa có đánh giá nào từ học viên.',
      );
    }
    final filtered = _starFilter == 0
        ? _reviews
        : _reviews.where((r) => r.rating.round() == _starFilter).toList();
    final shown = filtered.take(_shownReviews).toList();

    Widget starChip(String label, int star) {
      final selected = _starFilter == star;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: selected ? Colors.white : AppColors.textHeading,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13.0,
        ),
        onSelected: (_) => setState(() {
          _starFilter = star;
          _shownReviews = 5;
        }),
      );
    }

    return _buildSection(
      'Đánh giá từ học viên (${_reviews.length})',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimens.p8,
            runSpacing: AppDimens.p4,
            children: [
              starChip('Tất cả (${_reviews.length})', 0),
              for (var star = 5; star >= 1; star--)
                starChip(
                  '$star sao (${_reviews.where((r) => r.rating.round() == star).length})',
                  star,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.p12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
              child: Center(
                child: Text(
                  'Không có đánh giá $_starFilter sao',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(color: AppColors.border, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shown[i].userName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RatingStars(rating: shown[i].rating),
              ],
            ),
            if (shown[i].comment.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Text(
                shown[i].comment,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textBody,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 4.0),
            Text(
              'Khóa: ${shown[i].courseTitle}${shown[i].createdAt == null ? '' : '  •  ${_date(shown[i].createdAt!)}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionTiny.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (filtered.length > 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_shownReviews < filtered.length)
                  TextButton(
                    onPressed: () => setState(() => _shownReviews += 5),
                    child: const Text('Xem thêm'),
                  ),
                if (_shownReviews > 5)
                  TextButton(
                    onPressed: () => setState(() => _shownReviews = 5),
                    child: const Text('Thu gọn'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Giới thiệu, chứng chỉ và thông tin giảng dạy; thu gọn mặc định cho trang gọn
  Widget _buildAbout(Course course) {
    final totalStudents = _profile?.studentsCount ?? 0;
    final fields = _courses
        .map((c) => c.category)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final certified = _courses.where((c) => c.hasCertificate).length;

    final facts = <(IconData, String)>[
      if (!_loading && _error == null)
        (
          Icons.menu_book_outlined,
          'Đang giảng dạy ${_profile?.coursesCount ?? 0} khóa học',
        ),
      if (totalStudents > 0)
        (Icons.groups_outlined, '$totalStudents học viên đã đăng ký'),
      if (fields.isNotEmpty)
        (Icons.category_outlined, 'Lĩnh vực: ${fields.join(', ')}'),
      if (certified > 0)
        (
          Icons.workspace_premium_outlined,
          '$certified khóa cấp chứng chỉ hoàn thành',
        ),
    ];
    final certs = course.instructorCertificates;
    final bio = (_profile?.experience ?? '').trim();

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: AppDimens.p12, bottom: 4.0),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    final intro = _loading
        ? const Text('Đang tải thông tin giảng viên…')
        : _error != null
        ? const Text('Không tải được thông tin giới thiệu.')
        : bio.isEmpty
        ? Text(
            'Giảng viên chưa cập nhật lời giới thiệu.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          )
        : Text(
            bio,
            maxLines: _aboutExpanded ? null : 3,
            overflow: _aboutExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textBody,
              height: 1.5,
            ),
          );

    return _buildSection(
      'Giới thiệu giảng viên',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro,
          if (_aboutExpanded) ...[
            if (facts.isNotEmpty) ...[
              heading('Thông tin giảng dạy'),
              for (final f in facts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(f.$1, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          f.$2,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            heading('Chứng chỉ'),
            if (certs.isEmpty)
              Text(
                'Chưa có thông tin chứng chỉ.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              )
            else
              for (final c in certs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          c,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
              child: Text(_aboutExpanded ? 'Ẩn bớt' : 'Xem thêm'),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _buildHeader(Course course) {
    final profileAvatar = _profile?.avatarUrl ?? '';
    final avatar = profileAvatar.isNotEmpty
        ? profileAvatar
        : course.instructorAvatar;
    return Container(
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: avatar.isEmpty ? null : NetworkImage(avatar),
            onBackgroundImageError: avatar.isEmpty ? null : (_, _) {},
            child: null,
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            _name,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19.0,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            (_profile?.specialty.isNotEmpty ?? false)
                ? _profile!.specialty
                : 'Chưa có thông tin chuyên môn',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          if (!_loading && _error == null) ...[
            Text(
              '${_profile?.studentsCount ?? 0} học viên',
              style: AppTypography.captionTiny.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_totalReviews > 0) ...[
              RatingStars(
                rating: _rating,
                reviewCount: _totalReviews,
                size: 18,
              ),
              const SizedBox(height: 8.0),
              _loveBadge(),
              const SizedBox(height: AppDimens.p12),
            ] else ...[
              Text(
                'Chưa có đánh giá về giảng viên này',
                style: AppTypography.captionTiny.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimens.p12),
            ],
            Row(
              children: [
                _stat('${_profile?.coursesCount ?? 0}', 'Khóa học', 0),
                _stat('$_totalReviews', 'Lượt đánh giá', 1),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Nhãn đánh giá chung về giảng viên theo điểm trung bình
  Widget _loveBadge() {
    final String label;
    final IconData icon;
    final Color color;
    final Color bg;
    if (_rating >= 4.5) {
      label = 'Giảng viên được yêu thích';
      icon = Icons.favorite_rounded;
      color = AppColors.error;
      bg = AppColors.errorLight;
    } else if (_rating >= 4.0) {
      label = 'Được học viên đánh giá cao';
      icon = Icons.thumb_up_alt_rounded;
      color = AppColors.success;
      bg = AppColors.successLight;
    } else {
      label = 'Đánh giá chung: ${_rating.toStringAsFixed(1)}/5';
      icon = Icons.star_half_rounded;
      color = AppColors.warning;
      bg = AppColors.warningLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: AppTypography.captionTiny.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Số liệu bấm được: bấm để mở danh sách bên dưới, bấm lần nữa để đóng
  Widget _stat(String value, String label, int panel) {
    final selected = _panel == panel;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _panel = selected ? null : panel;
          _coursePage = 1;
        }),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.captionTiny.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8.0),
          child,
        ],
      ),
    );
  }
}

class _InstructorReview {
  final String userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;
  final String courseTitle;

  const _InstructorReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.courseTitle,
  });
}
