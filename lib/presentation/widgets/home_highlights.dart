import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';

Widget _sectionTitle(String eyebrow, String title) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: AppTypography.captionTiny.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  ),
);

/// Dải số liệu nổi bật (giống dải thống kê trên web).
class HomeStatsBand extends StatelessWidget {
  const HomeStatsBand({super.key});

  static const _stats = [
    ('15,000+', 'Học viên tin tưởng lựa chọn'),
    ('500+', 'Bài giảng video chuyên sâu'),
    ('98%', 'Đánh giá hài lòng'),
    ('24/7', 'Đồng hành hỗ trợ học viên'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row == 1) const SizedBox(height: 16),
            Row(
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(child: _stat(_stats[row * 2 + col])),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat((String, String) s) => Column(
    children: [
      Text(
        s.$1,
        style: AppTypography.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        s.$2,
        textAlign: TextAlign.center,
        style: AppTypography.captionTiny.copyWith(
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ],
  );
}

/// "Tại sao chọn E-Learning": 4 thẻ giá trị cốt lõi.
class HomeWhySection extends StatelessWidget {
  const HomeWhySection({super.key});

  static const _items = [
    (
      Icons.work_outline_rounded,
      '100% thực chiến',
      'Tham gia xây dựng dự án thực tế sát yêu cầu tuyển dụng.',
    ),
    (
      Icons.school_rounded,
      'Giảng viên chuyên gia',
      'Đội ngũ nhiều năm kinh nghiệm, tận tình giải đáp.',
    ),
    (
      Icons.devices_rounded,
      'Học mọi thiết bị',
      'Video Full HD mượt mà, tự lưu tiến độ học.',
    ),
    (
      Icons.workspace_premium_rounded,
      'Chứng chỉ uy tín',
      'Cấp chứng chỉ số sau khi hoàn thành khóa học.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Giá trị cốt lõi', 'Vì sao chọn E-Learning?'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row == 1) const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _card(_items[row * 2])),
                      const SizedBox(width: 12),
                      Expanded(child: _card(_items[row * 2 + 1])),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _card((IconData, String, String) item) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.$1, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          item.$2,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.$3,
          style: AppTypography.captionTiny.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

/// "Bắt đầu với 4 bước": dòng thời gian dọc.
class HomeStepsSection extends StatelessWidget {
  const HomeStepsSection({super.key});

  static const _steps = [
    ('Đăng ký / Đăng nhập', 'Tạo tài khoản trong 30 giây để bắt đầu.'),
    ('Chọn khóa học', 'Khám phá kho khóa học đa ngành với gợi ý cá nhân hóa.'),
    ('Học và thực hành', 'Xem video, ghi chú trực tiếp và làm bài kiểm tra cuối bài.'),
    ('Nhận chứng chỉ', 'Hoàn thành từ 80% trở lên để nhận chứng nhận và đánh giá khóa học.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quy trình tinh gọn', 'Bắt đầu với 4 bước'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p16),
          child: Column(
            children: [
              for (var i = 0; i < _steps.length; i++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Column(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (i < _steps.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _steps.length - 1 ? 16 : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _steps[i].$1,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textHeading,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _steps[i].$2,
                                style: AppTypography.captionTiny.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
