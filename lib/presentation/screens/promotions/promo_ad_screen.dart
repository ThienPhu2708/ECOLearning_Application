import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/course.dart';
import '../../../data/models/promo_ad.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/promo_ad_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/course_card.dart';
import '../../widgets/state_views.dart';
import '../course_detail/course_detail_screen.dart';
import '../coupons/coupon_wallet_screen.dart';

/// Trang ưu đãi mở ra khi bấm ảnh quảng cáo: các chương trình của chiến dịch (hoặc một chương trình),
/// mã để lưu vào ví và các khóa học được áp dụng, giống trang `/UuDai/...` trên website.
class PromoAdScreen extends StatefulWidget {
  /// `campaign` hoặc `promotion`.
  final String type;
  final String id;
  final String? title;

  const PromoAdScreen({
    super.key,
    required this.type,
    required this.id,
    this.title,
  });

  @override
  State<PromoAdScreen> createState() => _PromoAdScreenState();
}

class _PromoAdScreenState extends State<PromoAdScreen> {
  final PromoAdRepository _repo = PromoAdRepository();
  final CouponRepository _couponRepo = CouponRepository();

  PromoAdPage? _page;
  Object? _error;
  bool _loading = true;
  final Set<String> _saving = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repo.page(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _save(PromoOffer offer) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      AppNavigator.toLogin(message: 'Đăng nhập để lưu mã ưu đãi vào ví.');
      return;
    }
    final code = offer.code;
    if (code == null) return;
    setState(() => _saving.add(offer.id));
    try {
      final result = await _couponRepo.save(code);
      if (!mounted) return;
      setState(() {
        _page = _replaceOffer(
          offer.id,
          (o) => o.copyWith(saved: true, canSave: false),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['alreadySaved'] == true
                ? 'Mã $code đã có trong ví.'
                : 'Đã lưu mã $code vào ví.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving.remove(offer.id));
    }
  }

  PromoAdPage? _replaceOffer(
    String id,
    PromoOffer Function(PromoOffer) change,
  ) {
    final p = _page;
    if (p == null) return null;
    return PromoAdPage(
      type: p.type,
      id: p.id,
      title: p.title,
      description: p.description,
      imageUrl: p.imageUrl,
      startsAt: p.startsAt,
      endsAt: p.endsAt,
      offers: [for (final o in p.offers) o.id == id ? change(o) : o],
    );
  }

  static String _date(DateTime? d) => d == null
      ? ''
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title ?? _page?.title ?? 'Ưu đãi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : RefreshIndicator(onRefresh: _load, child: _buildBody(_page!)),
    );
  }

  Widget _buildBody(PromoAdPage page) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((page.imageUrl ?? '').isNotEmpty)
                CachedNetworkImage(
                  imageUrl: page.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Chip(
                      icon: Icons.event_rounded,
                      text: '${_date(page.startsAt)} – ${_date(page.endsAt)}',
                      color: AppColors.primary,
                      background: AppColors.primaryLight,
                    ),
                    if ((page.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        page.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (page.offers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Hiện chưa có ưu đãi nào đang áp dụng.')),
          )
        else
          for (final offer in page.offers) ...[
            _OfferCard(
              offer: offer,
              saving: _saving.contains(offer.id),
              dateText: _date(offer.expiresAt),
              onSave: () => _save(offer),
              onOpenWallet: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CouponWalletScreen(),
                ),
              ),
              onOpenCourse: (course) =>
                  CourseDetailScreen.open(context, course, ClickSource.promo),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  final Color background;

  const _Chip({
    this.icon,
    required this.text,
    this.color = AppColors.textSecondary,
    this.background = AppColors.surfaceSubtle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final PromoOffer offer;
  final bool saving;
  final String dateText;
  final VoidCallback onSave;
  final VoidCallback onOpenWallet;
  final void Function(Course course) onOpenCourse;

  const _OfferCard({
    required this.offer,
    required this.saving,
    required this.dateText,
    required this.onSave,
    required this.onOpenWallet,
    required this.onOpenCourse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      child: Text(
                        offer.discountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (offer.note ?? '').isNotEmpty
                          ? offer.note!
                          : (offer.isDirectDiscount
                                ? 'Giảm trực tiếp'
                                : 'Mã giảm giá'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          text: offer.isDirectDiscount
                              ? 'Tự động áp dụng'
                              : 'Nhập mã khi thanh toán',
                        ),
                        if (offer.isLoyalty)
                          const _Chip(
                            icon: Icons.workspace_premium_rounded,
                            text: 'Thân thiết',
                            color: Color(0xFF92400E),
                            background: Color(0xFFFEF3C7),
                          ),
                        if (dateText.isNotEmpty) _Chip(text: 'Đến $dateText'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (offer.conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final c in offer.conditions)
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
          ],
          if ((offer.message ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                offer.message!,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ] else if ((offer.code ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      offer.code!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (offer.saved)
                    OutlinedButton(
                      onPressed: onOpenWallet,
                      child: const Text('Đã lưu · xem ví'),
                    )
                  else
                    FilledButton(
                      onPressed: saving ? null : onSave,
                      child: Text(
                        saving
                            ? 'Đang lưu...'
                            : (offer.canSave
                                  ? 'Lưu vào ví'
                                  : 'Đăng nhập để lưu'),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (offer.appliesToAll) ...[
            const SizedBox(height: 12),
            const Text(
              'Áp dụng cho mọi khóa học trên hệ thống.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ] else if (offer.courses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Khóa học được áp dụng (${offer.totalCourses})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 10),
            for (final course in offer.courses)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CourseCard(
                  course: course,
                  layout: CourseCardLayout.listHorizontal,
                  onTap: () => onOpenCourse(course),
                ),
              ),
            if (offer.totalCourses > offer.courses.length)
              Text(
                'Và ${offer.totalCourses - offer.courses.length} khóa học khác.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
          ] else ...[
            const SizedBox(height: 12),
            const Text(
              'Hiện chưa có khóa học nào đang mở bán trong phạm vi của ưu đãi này.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
