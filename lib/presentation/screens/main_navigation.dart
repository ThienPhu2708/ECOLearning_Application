import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'explore/explore_screen.dart';
import 'home/home_screen.dart';
import 'my_courses/my_courses_screen.dart';
import 'profile/profile_screen.dart';

/// Shell điều hướng chính của phân hệ Học viên (Bottom Navigation Bar 4 Tabs)
/// Bảo tồn trạng thái cuộn của từng trang bằng IndexedStack theo Mục 8
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
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
          HomeScreen(onNavigateTab: _onTabSelected),
          const ExploreScreen(),
          MyCoursesScreen(onNavigateTab: _onTabSelected),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
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
