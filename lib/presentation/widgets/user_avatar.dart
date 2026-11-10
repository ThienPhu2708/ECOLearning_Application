import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../core/constants/app_colors.dart';

class AvatarImages {
  static final _images = <String, ValueNotifier<Uint8List?>>{};
  static ValueNotifier<Uint8List?> forUser(String id) =>
      _images.putIfAbsent(id, () => ValueNotifier(null));
}

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;
  const UserAvatar({super.key, required this.user, required this.radius});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Uint8List?>(
    valueListenable: AvatarImages.forUser(user.id),
    builder: (_, bytes, _) => ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : user.avatarUrl.isEmpty
            ? _fallback()
            : Image.network(
                user.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              ),
      ),
    ),
  );
  Widget _fallback() => ColoredBox(
    color: AppColors.primaryLight,
    child: Icon(Icons.person_rounded, color: AppColors.primary, size: radius),
  );
}
