import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_button.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _pages = [
    {
      'tag': '✨ KHÁM PHÁ KHÔNG GIỚI HẠN',
      'title': 'Hàng Ngàn Khóa Học\nChất Lượng Cao',
      'desc':
          'Học hỏi từ các chuyên gia hàng đầu về Lập trình, UI/UX Design, AI và Marketing số.',
      'icon': Icons.auto_stories_rounded,
      'color': AppColors.primary,
    },
    {
      'tag': '🤖 THUẬT TOÁN ĐỀ XUẤT THÔNG MINH',
      'title': 'Gợi Ý Khóa Học\nChuẩn Xác 98% Match',
      'desc':
          'Ứng dụng thuật toán Collaborative Filtering đề xuất lộ trình tối ưu riêng cho từng học viên.',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'tag': '🏆 CHỨNG CHỈ TỐT NGHIỆP',
      'title': 'Theo Dõi Tiến Độ &\nCấp Chứng Chỉ Điện Tử',
      'desc':
          'Tự động theo dõi tiến độ học tập, tích xanh bài giảng và nhận chứng nhận số có mã QR xác thực.',
      'icon': Icons.workspace_premium_rounded,
      'color': const Color(0xFF10B981),
    },
  ];

  void _onFinish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Bỏ qua
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p16,
                vertical: AppDimens.p8,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _onFinish,
                  child: Text(
                    'Bỏ qua',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView các trang minh họa
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon minh họa lớn
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (page['color'] as Color).withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 68.0,
                            color: page['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 36.0),

                        // Tag viên thuốc
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(999.0),
                          ),
                          child: Text(
                            page['tag'] as String,
                            style: AppTypography.captionTiny.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Tiêu đề
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Mô tả
                        Text(
                          page['desc'] as String,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Controls
            Padding(
              padding: const EdgeInsets.all(AppDimens.p24),
              child: Column(
                children: [
                  // Indicators dạng viên thuốc
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8.0,
                        width: isActive ? 24.0 : 8.0,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(999.0),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28.0),

                  // Nút chuyển trang / Bắt đầu
                  AppButton(
                    text: _currentPage == _pages.length - 1
                        ? 'Bắt đầu ngay'
                        : 'Tiếp tục',
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onFinish();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
