import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/user.dart';
import '../../widgets/user_avatar.dart';

class ProfileAvatar extends StatefulWidget {
  final User user;
  final Future<String> Function(String path)? upload;
  final Future<XFile?> Function(ImageSource source)? pickImage;
  const ProfileAvatar({
    super.key,
    required this.user,
    this.upload,
    this.pickImage,
  });
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _busy = false;
  Future<void> _choose() async {
    if (_busy) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Đổi ảnh đại diện',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final image =
          await (widget.pickImage?.call(source) ??
              ImagePicker().pickImage(
                source: source,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              ));
      if (image == null || !mounted) return;
      if (await image.length() > 10 * 1024 * 1024) {
        throw const ApiException(
          message: 'Ảnh quá lớn. Vui lòng chọn ảnh dưới 10 MB.',
        );
      }
      final bytes = await image.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
      if (!mounted) return;
      final url = widget.upload == null
          ? null
          : await widget.upload!(image.path);
      if (!mounted) return;
      if (url != null && url.trim().isEmpty) {
        throw const ApiException(
          message: 'Chưa nhận được ảnh mới từ máy chủ. Vui lòng thử lại.',
        );
      }
      if (url != null) widget.user.avatarUrl = url;
      AvatarImages.forUser(widget.user.id).value = bytes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.upload == null
                ? 'Đã đổi ảnh trong phiên dùng thử này.'
                : 'Đã cập nhật ảnh đại diện.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : e is PlatformException
          ? 'Không mở được máy ảnh hoặc thư viện. Vui lòng kiểm tra quyền truy cập trong Cài đặt.'
          : 'Chưa đổi được ảnh. Vui lòng chọn ảnh khác hoặc thử lại.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Đổi ảnh đại diện',
    child: Semantics(
      button: true,
      label: 'Đổi ảnh đại diện',
      child: InkWell(
        onTap: _busy ? null : _choose,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: UserAvatar(user: widget.user, radius: 46),
              ),
              if (_busy)
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x66000000),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
