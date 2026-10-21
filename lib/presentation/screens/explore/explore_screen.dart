import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/category.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../widgets/course_card.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';
import 'filter_bottom_sheet.dart';

/// Tab 2: Màn hình Khám phá & Tìm kiếm nâng cao theo QuyChuanThietKe_App.md Mục 4.3 & UC4
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repo = CourseRepository();
  final _favoriteRepo = FavoriteRepository();
  final Map<String, bool> _favorites = {}; // trạng thái tim đã bấm trong phiên này, theo id khóa
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String _searchQuery = '';
  FilterCriteria _filterCriteria = FilterCriteria();

  // Kết quả (B2) phân trang: cuộn gần cuối thì tải trang kế tiếp
  final List<Course> _courses = [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  bool _loading = true;
  Object? _error;
  int _requestId = 0; // bỏ qua kết quả của lượt gọi cũ khi người dùng đổi từ khóa / bộ lọc

  // Lĩnh vực (B1) để lọc nhanh; null là tất cả
  List<Category> _categories = [];
  String? _categoryId;

  // Gợi ý từ khóa (B5): q rỗng thì là từ khóa thịnh hành
  List<String> _keywords = [];

  bool get _hasActiveFilter => _filterCriteria.hasFilter;

  @override
  void initState() {
    super.initState();
    _loadSuggestions('');
    _loadCategories();
    _search();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _repo.categories();
      if (mounted) setState(() => _categories = list);
    } catch (_) {
      // Không có danh sách lĩnh vực thì chỉ mất hàng chip lọc nhanh
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch(int page) async {
    final f = _filterCriteria;
    final result = await _repo.courses(
      q: _searchQuery,
      categoryId: _categoryId,
      level: f.level == 'Tất cả' ? null : f.level,
      price: f.onlyFree ? 'free' : null,
      minRating: f.minRating > 0 ? f.minRating : null,
      sort: f.sort,
      page: page,
    );
    _courses
      ..clear()
      ..addAll(result.items);
    _page = result.page;
    _total = result.total;
    _totalPages = result.totalPages < 1 ? 1 : result.totalPages;
  }

  /// Tìm lại từ trang 1 (đổi từ khóa, bộ lọc, sắp xếp, hoặc bấm "Thử lại")
  Future<void> _search() => _goToPage(1);

  /// Chuyển sang trang [page] (10 khóa mỗi trang) rồi cuộn lên đầu danh sách
  Future<void> _goToPage(int page) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _fetch(page);
      if (!mounted || id != _requestId) return;
      setState(() => _loading = false);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadSuggestions(String q) async {
    try {
      final result = await _repo.suggest(q);
      if (!mounted || q != _searchQuery) return;
      setState(() => _keywords = result.keywords);
    } catch (_) {
      // Gợi ý từ khóa chỉ là phụ trợ, lỗi thì giữ danh sách cũ
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _searchQuery = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadSuggestions(_searchQuery);
      _search();
    });
  }

  void _resetAll() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _categoryId = null;
      _filterCriteria = FilterCriteria();
    });
    _loadSuggestions('');
    _search();
  }

  /// D1. Thả tim / bỏ tim ngay trên thẻ; lỗi (mất mạng, chưa đăng nhập) thì giữ trạng thái cũ và báo
  Future<void> _toggleFavorite(Course course) async {
    final before = _favorites[course.id] ?? course.isFavorite;
    setState(() => _favorites[course.id] = !before);
    try {
      final now = await _favoriteRepo.toggle(course.id);
      if (mounted) setState(() => _favorites[course.id] = now);
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorites[course.id] = before);
      showErrorSnackBar(context, e);
    }
  }

  void _openFilter() {
    FilterBottomSheet.show(
      context,
      initialCriteria: _filterCriteria,
      onApply: (newCriteria) {
        setState(() => _filterCriteria = newCriteria);
        _search();
      },
    );
  }

  void _applyKeyword(String keyword) {
    _debounce?.cancel();
    setState(() {
      _searchController.text = keyword;
      _searchQuery = keyword;
    });
    _loadSuggestions(keyword);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thanh tìm kiếm cố định & Nút Filter
            Padding(
              padding: const EdgeInsets.all(AppDimens.p16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm khóa học, giảng viên, kỹ năng...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onQueryChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.p8),
                  // Nút mở bộ lọc Modal Bottom Sheet
                  Badge(
                    isLabelVisible: _hasActiveFilter,
                    backgroundColor: AppColors.primary,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: _hasActiveFilter
                            ? AppColors.primaryLight
                            : AppColors.surfaceSubtle,
                        borderRadius: AppDimens.radiusButton,
                        border: Border.all(
                          color: _hasActiveFilter
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: _hasActiveFilter
                              ? AppColors.primary
                              : AppColors.textHeading,
                        ),
                        tooltip: 'Bộ lọc nâng cao',
                        onPressed: _openFilter,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2a. Lọc nhanh theo lĩnh vực
            if (_categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: AppDimens.p8),
                  itemBuilder: (context, index) {
                    final id = index == 0 ? null : _categories[index - 1].id;
                    final selected = _categoryId == id;
                    return ChoiceChip(
                      label: Text(index == 0 ? 'Tất cả' : _categories[index - 1].name),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        color: selected ? Colors.white : AppColors.textHeading,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13.0,
                      ),
                      onSelected: (_) {
                        setState(() => _categoryId = id);
                        _search();
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8.0),

            // 2. Danh sách từ khóa xu hướng (Trending Tags)
            SizedBox(
              height: 34,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
                scrollDirection: Axis.horizontal,
                itemCount: _keywords.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppDimens.p8),
                itemBuilder: (context, index) {
                  final tag = _keywords[index];
                  final isCurrent = _searchQuery.toLowerCase() == tag.toLowerCase();

                  return GestureDetector(
                    onTap: () => _applyKeyword(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTypography.captionTiny.copyWith(
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),

            // 3. Số lượng kết quả
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _loading ? 'Đang tìm kiếm...' : 'Tìm thấy $_total khóa học phù hợp (trang $_page/$_totalPages)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_filterCriteria.isDefault || _searchQuery.isNotEmpty || _categoryId != null)
                    GestureDetector(
                      onTap: _resetAll,
                      child: Text(
                        'Xóa bộ lọc',
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),

            // 4. Danh sách khóa học hoặc Trạng thái rỗng
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _error != null
                      ? ErrorView(error: _error, onRetry: _search)
                      : courses.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _search,
                              color: AppColors.primary,
                              child: LayoutBuilder(
                                builder: (context, constraints) => SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: SizedBox(height: constraints.maxHeight, child: _buildEmptyState()),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _goToPage(_page),
                              color: AppColors.primary,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(AppDimens.p16),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: courses.length,
                                itemBuilder: (context, index) {
                                  final course = courses[index];
                                  return CourseCard(
                                    course: course,
                                    layout: CourseCardLayout.listHorizontal,
                                    isFavorite: _favorites[course.id] ?? course.isFavorite,
                                    onFavoriteTap: () => _toggleFavorite(course),
                                    onTap: () => CourseDetailScreen.open(context, course, ClickSource.search),
                                  );
                                },
                              ),
                            ),
            ),

            // 5. Thanh phân trang: ‹ 1 2 … N ›
            if (!_loading && _error == null)
              PaginationBar(page: _page, totalPages: _totalPages, onPageChanged: _goToPage),
          ],
        ),
      ),
    );
  }

  // Trạng thái rỗng khi không tìm thấy kết quả
  Widget _buildEmptyState() {
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
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Không tìm thấy kết quả phù hợp',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc nới lỏng các tiêu chí trong bộ lọc nâng cao.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _resetAll,
              child: const Text('Đặt lại tìm kiếm & Bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }
}
