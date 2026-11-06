import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sign_in_required.dart';
import 'package:flutter/material.dart';
import '../../core/notifications/study_reminder_service.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'explore/explore_screen.dart';
import 'explore/filter_bottom_sheet.dart';
import 'home/home_screen.dart';
import 'my_courses/my_courses_screen.dart';
import 'profile/profile_screen.dart';
import 'orders/order_history_screen.dart';

/// Shell điều hướng chính của phân hệ Học viên (Bottom Navigation Bar 4 Tabs)
/// Bảo tồn trạng thái cuộn của từng trang bằng IndexedStack theo Mục 8
class MainNavigationScreen extends StatefulWidget {
  /// Tab mở đầu: 0 Trang chủ, 1 Khám phá, 2 Khóa học của tôi, 3 Hồ sơ
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex = widget.initialIndex;

  final _homeKey = GlobalKey<HomeScreenState>();
  final _coursesKey = GlobalKey<MyCoursesScreenState>();
  final _exploreKey = GlobalKey<ExploreScreenState>();

  @override
  void initState() {
    super.initState();
    DeviceReminderNotifications.openCourses.addListener(_openReminder);
    unawaited(
      StudyReminderService.instance.notifications
          .initialize()
          .then((_) => _openReminder())
          .catchError((Object _) {}),
    );
  }

  void _openReminder() {
    if (!mounted || !DeviceReminderNotifications.openCourses.value) return;
    DeviceReminderNotifications.openCourses.value = false;
    setState(() => _currentIndex = 2);
  }

  @override
  void dispose() {
    DeviceReminderNotifications.openCourses.removeListener(_openReminder);
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Số liệu đổi theo việc mua / học nên tải lại khi mở tab
    if (index == 0 && _currentIndex == 0) _homeKey.currentState?.reload();
    if (index == 3) {
      context.read<AuthProvider>().refreshUser().catchError((_) {});
    }
  }

  void _openCourses(int tab) {
    _onTabSelected(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coursesKey.currentState?.showTab(tab);
    });
  }

  void _openExploreGroup(CourseGroup group) {
    _onTabSelected(1);
    _exploreKey.currentState?.showGroup(group);
  }

  void _openExploreTopRated() {
    _onTabSelected(1);
    _exploreKey.currentState?.showTopRated();
  }

  void _openExploreSort(String sort) {
    _onTabSelected(1);
    _exploreKey.currentState?.showSort(sort);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthProvider?>()?.isLoggedIn ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showCart: _currentIndex == 0 || _currentIndex == 1,
        showFavorites: _currentIndex == 2,
        extraActions: _currentIndex == 2
            ? [
                IconButton(
                  tooltip: 'Lịch sử đơn hàng',
                  icon: const Icon(Icons.receipt_long_outlined),
                  color: AppColors.textHeading,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => signedIn
                          ? const OrderHistoryScreen()
                          : const Scaffold(body: SignInRequired()),
                    ),
                  ),
                ),
              ]
            : null,
        showAvatar: _currentIndex == 0,
        title: _currentIndex == 0
            ? null
            : (_currentIndex == 1
                  ? 'Khám phá khóa học'
                  : (_currentIndex == 2
                        ? 'Khóa học của tôi'
                        : 'Hồ sơ học viên')),
        onAvatarTap: () => _onTabSelected(3),
        onSearchTap: _currentIndex == 0 ? () => _onTabSelected(1) : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            key: _homeKey,
            onNavigateTab: _onTabSelected,
            onExploreGroup: _openExploreGroup,
            onExploreTopRated: _openExploreTopRated,
            onExploreSort: _openExploreSort,
          ),
          ExploreScreen(key: _exploreKey),
          signedIn
              ? MyCoursesScreen(
                  key: _coursesKey,
                  isActive: _currentIndex == 2,
                  onNavigateTab: _onTabSelected,
                )
              : const SignInRequired(),
          signedIn
              ? ProfileScreen(
                  isActive: _currentIndex == 3,
                  onOpenCourses: _openCourses,
                )
              : const SignInRequired(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          elevation: 0,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_lesson_outlined),
              activeIcon: Icon(Icons.play_lesson_rounded),
              label: 'Khóa học',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}
