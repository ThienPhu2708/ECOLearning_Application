import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';

class _HeroSlide {
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final int tab;
  final List<Color> colors;

  const _HeroSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.tab,
    required this.colors,
  });
}

const _slides = [
  _HeroSlide(
    eyebrow: 'NỀN TẢNG ĐÀO TẠO TRỰC TUYẾN',
    title: 'Khởi đầu hành trình chinh phục tri thức',
    body: 'Kết hợp lý thuyết và dự án thực tế, đồng hành cùng chuyên gia.',
    cta: 'Khám phá ngay',
    icon: Icons.explore_rounded,
    tab: 1,
    colors: [Color(0xFF1E1B4B), AppColors.primary],
  ),
  _HeroSlide(
    eyebrow: 'GỢI Ý CÁ NHÂN HÓA',
    title: 'Khóa học dành riêng cho bạn',
    body: 'Dựa trên những khóa bạn đã xem, học và đánh giá để đề xuất khóa tiếp theo.',
    cta: 'Tìm khóa phù hợp',
    icon: Icons.lightbulb_rounded,
    tab: 1,
    colors: [Color(0xFF312E81), Color(0xFF7C3AED)],
  ),
  _HeroSlide(
    eyebrow: 'HỌC LINH HOẠT',
    title: 'Học mọi lúc, mọi nơi',
    body: 'Tự động lưu tiến độ, học tiếp đúng bài đang dừng và nhận chứng chỉ khi hoàn thành.',
    cta: 'Khóa học của tôi',
    icon: Icons.play_circle_fill_rounded,
    tab: 2,
    colors: [Color(0xFF0F172A), Color(0xFF0E7490)],
  ),
];

/// Banner đầu Trang chủ: 3 slide tự chuyển (giống banner trên web), có thể vuốt.
class HomeHeroCarousel extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeHeroCarousel({super.key, this.onNavigateTab});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % _slides.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _startTimer(); // vuốt tay thì tính lại 5 giây
            },
            itemBuilder: (context, i) => _SlideCard(
              slide: _slides[i],
              onTap: () => widget.onNavigateTab?.call(_slides[i].tab),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  final _HeroSlide slide;
  final VoidCallback onTap;

  const _SlideCard({required this.slide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: slide.colors.last.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -10,
            child: Icon(
              slide.icon,
              size: 92,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  slide.eyebrow,
                  style: AppTypography.captionTiny.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                slide.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(slide.icon, size: 18),
                label: Text(
                  slide.cta,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
