import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/promo_ad.dart';
import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/promo_ad_repository.dart';
import '../screens/promotions/promo_ad_screen.dart';
import 'state_views.dart';

/// Popup quảng cáo ở trang chủ, giống website:
///  1. Ảnh quảng cáo chiến dịch / chương trình: mỗi lượt truy cập (mở app, đăng nhập lại) hiện một ảnh chưa xem.
///     Bấm ảnh hoặc "Xem ưu đãi" mở trang ưu đãi; dấu X đóng lại.
///  2. Không còn ảnh nào để chiếu thì mới tới popup "Ưu đãi dành riêng cho học viên thân thiết", chỉ với người đã đủ điều kiện
///     (mỗi ngày một lần, có nút "Không hiện lại").
class PromoAdPresenter {
  PromoAdPresenter._();

  static final Set<String> _seen = <String>{};
  static String? _seenToken;
  static bool _busy = false;

  /// Chọn ảnh quảng cáo đầu tiên chưa hiện trong lượt truy cập này (null nếu hết).
  static PromoAd? pickUnseen(List<PromoAd> ads, Set<String> seen) {
    for (final ad in ads) {
      if (!seen.contains(ad.key)) return ad;
    }
    return null;
  }

  /// Gọi khi trang chủ đã tải xong. Lỗi mạng hay API chưa có thì lặng lẽ bỏ qua, không ảnh hưởng trang chủ.
  static Future<void> showOnHome(
    BuildContext context, {
    PromoAdRepository? repository,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      final repo = repository ?? PromoAdRepository();
      // Đăng nhập / đăng xuất làm đổi token: tính là lượt truy cập mới
      final token = TokenStorage.instance.token ?? '';
      if (_seenToken != token) {
        _seen.clear();
        _seenToken = token;
      }

      final ads = await repo.ads();
      if (!context.mounted) return;
      final ad = pickUnseen(ads, _seen);
      if (ad != null) {
        _seen.add(ad.key);
        await _showAd(context, ad);
        return;
      }
      if (TokenStorage.instance.hasToken) {
        await _showLoyalty(context, repo);
      }
    } catch (_) {
      // Quảng cáo là nội dung bổ sung
    } finally {
      _busy = false;
    }
  }

  static Future<void> _showAd(BuildContext context, PromoAd ad) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng quảng cáo',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
          child: child,
        ),
      ),
      pageBuilder: (dialogContext, _, _) => PromoAdDialog(
        ad: ad,
        onOpen: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  PromoAdScreen(type: ad.type, id: ad.id, title: ad.title),
            ),
          );
        },
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  static Future<void> _showLoyalty(
    BuildContext context,
    PromoAdRepository repo,
  ) async {
    final popup = await repo.loyaltyPopup();
    if (!context.mounted || !popup.isEligible) return;

    final prefs = await SharedPreferences.getInstance();
    final neverKey = 'lp_never_${popup.promotionId}';
    final seenKey = 'lp_seen_${popup.promotionId}';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getBool(neverKey) == true || prefs.getString(seenKey) == today) {
      return;
    }
    await prefs.setString(seenKey, today);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => LoyaltyPopupDialog(
        popup: popup,
        onNever: () async {
          await prefs.setBool(neverKey, true);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    );
  }
}

/// Ảnh quảng cáo: khung ôm sát ảnh (kích thước theo ảnh tải lên), dấu X ở góc trên phải,
/// nút "Xem ưu đãi" ở giữa phía dưới và nhấp nhô để thu hút.
class PromoAdDialog extends StatefulWidget {
  final PromoAd ad;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const PromoAdDialog({
    super.key,
    required this.ad,
    required this.onOpen,
    required this.onClose,
  });

  @override
  State<PromoAdDialog> createState() => _PromoAdDialogState();
}

class _PromoAdDialogState extends State<PromoAdDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _pulse.isAnimating) _pulse.stop();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.9,
            maxHeight: size.height * 0.8,
          ),
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: widget.onOpen,
                    child: CachedNetworkImage(
                      imageUrl: widget.ad.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 260,
                        height: 160,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Text('Không tải được ảnh'),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1.12).animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: FilledButton(
                        onPressed: widget.onOpen,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Xem ưu đãi'),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: widget.onClose,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Popup chữ "Ưu đãi dành riêng cho học viên thân thiết" (người đã đủ điều kiện): lưu mã vào ví ngay tại đây.
class LoyaltyPopupDialog extends StatefulWidget {
  final LoyaltyPopup popup;
  final Future<void> Function() onNever;

  const LoyaltyPopupDialog({
    super.key,
    required this.popup,
    required this.onNever,
  });

  @override
  State<LoyaltyPopupDialog> createState() => _LoyaltyPopupDialogState();
}

class _LoyaltyPopupDialogState extends State<LoyaltyPopupDialog> {
  bool _saving = false;
  bool _saved = false;
  String? _message;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await CouponRepository().save(widget.popup.code!);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _message = result['alreadySaved'] == true
            ? 'Mã đã có trong ví.'
            : 'Đã lưu mã vào ví.';
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.popup;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Bạn đã đủ điều kiện nhận ưu đãi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.discountText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((p.note ?? '').isNotEmpty)
                    Text(
                      p.note!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  for (final c in p.conditions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.code!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                        if (p.expiresAt != null)
                          Text(
                            'HSD ${p.expiresAt!.day.toString().padLeft(2, '0')}/${p.expiresAt!.month.toString().padLeft(2, '0')}/${p.expiresAt!.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _message!,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : _saved
                          ? () => Navigator.of(context).pop()
                          : _save,
                      child: Text(
                        _saved
                            ? 'Xong'
                            : (_saving ? 'Đang lưu...' : 'Lưu vào ví'),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Để sau'),
                      ),
                      TextButton(
                        onPressed: widget.onNever,
                        child: const Text('Không hiện lại'),
                      ),
                    ],
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
