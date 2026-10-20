import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/mock_data.dart';
import '../../widgets/app_button.dart';
import 'logout_dialog.dart';

/// Tab 4: Hồ sơ cá nhân và cài đặt theo QuyChuanThietKe_App.md Mục 4.8, UC2 & UC3
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: MockData.currentUser.fullName);
    final phoneCtrl = TextEditingController(text: MockData.currentUser.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.only(
            top: AppDimens.p24,
            left: AppDimens.p24,
            right: AppDimens.p24,
            bottom: AppDimens.p24 + bottomInset,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.radiusSheet,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉnh sửa thông tin cá nhân',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Họ và tên',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Nhập họ tên...'),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Số điện thoại',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(hintText: 'Nhập số điện thoại...'),
              ),
              const SizedBox(height: 20.0),
              AppButton(
                text: 'Lưu thay đổi',
                onPressed: () {
                  setState(() {
                    MockData.currentUser.fullName = nameCtrl.text.trim();
                    MockData.currentUser.phone = phoneCtrl.text.trim();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật thông tin thành công!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusCard),
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Mật khẩu hiện tại'),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Mật khẩu mới (tối thiểu 8 ký tự)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (newPass.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu mới phải có tối thiểu 8 ký tự!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đổi mật khẩu thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  void _showOrderHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.radiusCard),
        title: const Text('Lịch sử đơn hàng'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                title: const Text('Đơn #ORD-2026-8891'),
                subtitle: const Text('02 khóa học • 1.698.000 đ\n10/01/2026 - Thành công'),
                isThreeLine: true,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                title: const Text('Đơn #ORD-2025-4412'),
                subtitle: const Text('01 khóa học • 849.000 đ\n15/12/2025 - Thành công'),
                isThreeLine: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;

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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46.0,
                          backgroundImage: NetworkImage(user.avatarUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(
                        '🎓 VAI TRÒ: ${user.role.toUpperCase()}',
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Thống kê nhanh
                    Row(
                      children: [
                        _buildStatItem('Đang học', '2'),
                        _buildStatDivider(),
                        _buildStatItem('Hoàn thành', '1'),
                        _buildStatStatDivider(),
                        _buildStatItem('Chứng chỉ', '1'),
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
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Thông báo học tập',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      value: _notificationsEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
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
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      value: _darkModeEnabled,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _darkModeEnabled = val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng Dark mode đang được đồng bộ cho phiên bản tiếp theo.'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _buildSettingsTile(
                      Icons.help_outline_rounded,
                      'Trợ giúp & Điều khoản sử dụng',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hệ sinh thái E-Learning Học viên v1.0 - KLTN Tuần 04'),
                          ),
                        );
                      },
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
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
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
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28.0,
      width: 1.0,
      color: AppColors.border,
    );
  }

  Widget _buildStatStatDivider() {
    return Container(
      height: 28.0,
      width: 1.0,
      color: AppColors.border,
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
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
    );
  }
}
