import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/course.dart';
import '../../widgets/app_button.dart';

/// Màn hình Xem và Tải chứng chỉ tốt nghiệp điện tử theo Mục 4.7 & UC8
class CertificateScreen extends StatelessWidget {
  final Course course;

  const CertificateScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chứng chỉ tốt nghiệp',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            children: [
              // Khung hiển thị chứng chỉ số sang trọng (Certificate Frame)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.p20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppDimens.radiusCard,
                  border: Border.all(color: const Color(0xFFD97706), width: 3.0), // Viền vàng kim
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.p16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Huy hiệu chứng nhận
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFD97706),
                        size: 56.0,
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'CHỨNG CHỈ TỐT NGHIỆP',
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 20.0,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'CERTIFICATE OF COMPLETION',
                        style: AppTypography.captionTiny.copyWith(
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      Text(
                        'Chứng nhận học viên',
                        style: AppTypography.labelSmall.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        MockData.currentUser.fullName.toUpperCase(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22.0,
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'Đã hoàn thành xuất sắc 100% chương trình khóa học:',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        course.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Thông tin giảng viên & Mã xác thực
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giảng viên chứng nhận',
                                style: AppTypography.captionTiny.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                course.instructor,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Ngày cấp: 15/01/2026',
                                style: AppTypography.captionTiny.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          // QR Code mô phỏng xác thực
                          Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 48.0,
                              color: AppColors.textHeading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'Mã số xác thực: CERT-2026-KLCN044-${course.id.hashCode.abs().toString().substring(0, 5)}',
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Cụm nút hành động Tải về và Chia sẻ
              AppButton(
                text: 'Tải chứng chỉ về máy (PDF / Ảnh)',
                icon: const Icon(Icons.download_rounded, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang lưu chứng chỉ định dạng PDF độ phân giải cao...'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12.0),

              AppButton(
                text: 'Chia sẻ lên LinkedIn / Facebook',
                type: AppButtonType.secondary,
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết xác thực chứng chỉ số!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
