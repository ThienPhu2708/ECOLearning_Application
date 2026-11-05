import 'my_reviews_screen.dart';
import '../messages/chat_entry.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../session/current_user.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/state_views.dart';
import '../../../data/models/user.dart';
import 'edit_profile_sheet.dart';
import 'profile_avatar.dart';
import 'study_reminder_tile.dart';
import 'help_terms_screen.dart';
import 'logout_dialog.dart';
import '../chatbot/chatbot_screen.dart';
import 'change_password_sheet.dart';
import '../../../data/repositories/profile_repository.dart';
import '../orders/order_history_screen.dart';
import '../favorites/favorites_screen.dart';
import '../coupons/coupon_wallet_screen.dart';
import '../my_courses/certificates_screen.dart';
import '../my_courses/my_courses_screen.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../data/repositories/quiz_repository.dart';

/// Tab 4: Hồ sơ cá nhân và cài đặt theo QuyChuanThietKe_App.md Mục 4.8, UC2 & UC3
class ProfileScreen extends StatefulWidget {
  final bool isActive;
  final ValueChanged<int>? onOpenCourses;
  final User? user;
  final QuizRepository? repository;
  const ProfileScreen({
    super.key,
    this.isActive = true,
    this.onOpenCourses,
    this.user,
    this.repository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final QuizRepository _quiz =
      widget.repository ??
      LearningDataScope.read(context)?.quiz ??
      QuizRepository();
  int? _certificateCount;
  int _certificateRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadCertificateCount();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadCertificateCount();
  }

  Future<void> _loadCertificateCount() async {
    final request = ++_certificateRequest;
    try {
      final certificates = await _quiz.certificates();
      if (mounted && request == _certificateRequest) {
        setState(() => _certificateCount = certificates.length);
      }
    } catch (_) {
      if (mounted && request == _certificateRequest) {
        setState(() => _certificateCount = null);
      }
    }
  }

  Future<void> _openCourses(int tab) async {
    final navigate = widget.onOpenCourses;
    if (navigate != null) {
      navigate(tab);
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Khóa học của tôi')),
          body: MyCoursesScreen(initialTabIndex: tab),
        ),
      ),
    );
  }

  Future<void> _openCertificates() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => CertificatesScreen(repository: _quiz)),
    );
    if (mounted) await _loadCertificateCount();
  }

  bool _darkModeEnabled = false;

  Future<void> _showEditProfileSheet() async {
    final user = widget.user ?? currentUser(context);
    if (user == null) return;
    final updated = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        user: user,
        onSave: (name, phone, gender, birthDate) async {
          return ProfileRepository().updateMe(
            fullName: name,
            phone: phone,
            gender: gender,
            birthDate: birthDate,
          );
        },
      ),
    );
    if (updated == null || !mounted) return;
    context.read<AuthProvider>().updateUser(updated);
    setState(() {
      final current = user;
      current.fullName = updated.fullName;
      current.phone = updated.phone;
      current.gender = updated.gender;
      current.birthDate = updated.birthDate;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật thông tin cá nhân.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePasswordSheet(
        onSubmit: (current, next) => ProfileRepository().changePassword(
          currentPassword: current,
          newPassword: next,
        ),
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mật khẩu thành công.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user ?? currentUser(context, listen: true);
    if (user == null) {
      return ErrorView(
        error: 'Chưa tải được thông tin tài khoản.',
        onRetry: () async {
          try {
            await context.read<AuthProvider>().refreshUser();
          } catch (e) {
            if (context.mounted) showErrorSnackBar(context, e);
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimens.p16),
          child: Column(
            children: [
              // 1. Header Hồ sơ người dùng
              Container(
                padding: const EdgeInsets.all(AppDimens.p20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimens.radiusCard,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppDimens.cardShadow,
                ),
                child: Column(
                  children: [
                    ProfileAvatar(
                      user: user,
                      upload: (path) async {
                        final auth = context.read<AuthProvider>();
                        final accountId = user.id;
                        final updated = await ProfileRepository()
                            .uploadAvatarAndReload(path);
                        if (!mounted || auth.user?.id != accountId) {
                          throw StateError(
                            'Account changed during avatar upload',
                          );
                        }
                        auth.updateUser(updated);
                        return updated.avatarUrl;
                      },
                    ),
                    const SizedBox(height: 12.0),

                    Text(
                      user.fullName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      user.email,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    const SizedBox(height: 20.0),

                    // Thống kê nhanh
                    Row(
                      children: [
                        _buildStatItem(
                          'Đang học',
                          user.inProgressCoursesCount.toString(),
                          onTap: () => _openCourses(0),
                        ),
                        _buildStatDivider(),
                        _buildStatItem(
                          'Hoàn thành',
                          user.completedCoursesCount.toString(),
                          onTap: () => _openCourses(1),
                        ),
                        _buildStatStatDivider(),
                        _buildStatItem(
                          'Chứng chỉ',
                          _certificateCount?.toString() ?? '—',
                          onTap: _openCertificates,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 2. Danh sách cài đặt & Tùy chọn (ListTile Settings)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimens.radiusCard,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppDimens.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      Icons.person_outline_rounded,
                      'Chỉnh sửa thông tin cá nhân',
                      onTap: _showEditProfileSheet,
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.lock_outline_rounded,
                      'Đổi mật khẩu tài khoản',
                      onTap: _showChangePasswordDialog,
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.receipt_long_rounded,
                      'Lịch sử đơn hàng & Hóa đơn',
                      onTap: _showOrderHistory,
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.local_offer_outlined,
                      'Mã giảm giá của tôi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const CouponWalletScreen(),
                        ),
                      ),
                    ),
                    const Divider(),
                    const StudyReminderTile(),
                    const Divider(),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons.dark_mode_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Chế độ giao diện tối (Dark Mode)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _darkModeEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _darkModeEnabled = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tính năng Dark mode đang được đồng bộ cho phiên bản tiếp theo.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.rate_review_outlined,
                      'Đánh giá của tôi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyReviewsScreen(),
                        ),
                      ),
                    ),
                    const Divider(),
                    const ChatEntry(),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.workspace_premium_outlined,
                      'Chứng chỉ của tôi',
                      onTap: _openCertificates,
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.favorite_border_rounded,
                      'Khóa học yêu thích',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.smart_toy_outlined,
                      'Trợ lý Elearning',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ChatbotScreen(),
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.help_outline_rounded,
                      'Trợ giúp & Điều khoản sử dụng',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpTermsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 3. Nút Đăng xuất tài khoản màu đỏ #EF4444 (UC2)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimens.radiusCard,
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Đăng xuất tài khoản',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                    onTap: () => LogoutDialog.show(context),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  label,
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 28.0, width: 1.0, color: AppColors.border);
  }

  Widget _buildStatStatDivider() {
    return Container(height: 28.0, width: 1.0, color: AppColors.border);
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}
