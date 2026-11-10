import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_typography.dart';
import '../session/current_user.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'sign_in_required.dart';
import 'user_avatar.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/favorites/favorites_screen.dart';

/// AppBar chuẩn hóa cho phân hệ Học viên theo QuyChuanThietKe_App.md Mục 3.2 & 4.2
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final bool showCart;
  final bool showFavorites;
  final bool showAvatar;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;
  final List<Widget>? extraActions;

  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.showCart = true,
    this.showFavorites = false,
    this.showAvatar = false,
    this.onAvatarTap,
    this.onSearchTap,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final user = currentUser(context, listen: true);
    final signedIn = Provider.of<AuthProvider?>(context)?.isLoggedIn ?? false;
    final cartCount = Provider.of<CartProvider?>(context)?.count ?? 0;
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
      leading: leading,
      centerTitle: title != null && !showAvatar,
      title: showAvatar
          ? Row(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.0),
                    ),
                    child: user == null
                        ? const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.person_outline),
                          )
                        : UserAvatar(user: user, radius: 18),
                  ),
                ),
                const SizedBox(width: AppDimens.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user == null
                            ? 'Xin chào'
                            : 'Xin chào, ${user.fullName} 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Cùng tiếp tục lộ trình học nào!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : (title != null
                ? Text(
                    title!,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null),
      actions: [
        if (onSearchTap != null)
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textHeading,
            tooltip: 'Tìm kiếm khóa học',
            onPressed: onSearchTap,
          ),
        ...?extraActions,
        if (showFavorites)
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.p8),
            child: IconButton(
              tooltip: 'Khóa học yêu thích',
              icon: const Icon(Icons.favorite_border_rounded),
              color: AppColors.textHeading,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => signedIn
                      ? const FavoritesScreen()
                      : const Scaffold(body: SignInRequired()),
                ),
              ),
            ),
          ),
        if (showCart)
          Padding(
            padding: const EdgeInsets.only(right: AppDimens.p8),
            child: IconButton(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.primary,
                label: Text(
                  '$cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textHeading,
                ),
              ),
              tooltip: 'Giỏ hàng',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
      ],
    );
  }
}
