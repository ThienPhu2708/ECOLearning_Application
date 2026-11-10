import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../widgets/coupon_voucher_card.dart';
import '../../widgets/state_views.dart';
import 'coupon_details_screen.dart';

class CouponWalletScreen extends StatefulWidget {
  const CouponWalletScreen({super.key, this.repository});

  final CouponRepository? repository;

  @override
  State<CouponWalletScreen> createState() => _CouponWalletScreenState();
}

class _CouponWalletScreenState extends State<CouponWalletScreen> {
  static const _tabs = ['usable', 'used', 'expired', 'collectable'];
  static const _labels = [
    'Có thể dùng',
    'Đã dùng',
    'Hết hiệu lực',
    'Thu thập mã',
  ];

  late final CouponRepository _repo = widget.repository ?? CouponRepository();
  final _codeController = TextEditingController();
  String _tab = 'usable';
  String _walletTab = 'usable';
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  CouponWallet? _wallet;
  CollectableCoupons? _collectable;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Nạp ví và mã có thể thu thập cùng lúc để màn hình mở nhanh hơn.
      final results = await Future.wait([
        _repo.wallet('usable'),
        _repo.collectable(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as CouponWallet;
        _walletTab = 'usable';
        _collectable = results[1] as CollectableCoupons;
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

  Future<void> _selectTab(String tab) async {
    // Bỏ qua lần chọn lặp nếu dữ liệu của tab đang chọn đã có sẵn.
    if (tab == _tab &&
        (tab == 'collectable' ? _collectable != null : _walletTab == tab)) {
      return;
    }
    setState(() {
      _tab = tab;
      _loading = true;
      _error = null;
    });
    try {
      if (tab == 'collectable') {
        _collectable = await _repo.collectable();
      } else {
        _wallet = await _repo.wallet(tab);
        _walletTab = tab;
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _reloadCurrent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (_tab == 'collectable') {
      try {
        _collectable = await _repo.collectable();
        if (mounted) setState(() => _loading = false);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e;
            _loading = false;
          });
        }
      }
    } else {
      final tab = _tab;
      try {
        _wallet = await _repo.wallet(tab);
        _walletTab = tab;
        if (mounted) setState(() => _loading = false);
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e;
            _loading = false;
          });
        }
      }
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Tab thu thập dùng API riêng; khi làm mới vẫn cập nhật ví ở tab khả dụng.
      final walletTab = _tab == 'collectable' ? 'usable' : _tab;
      final results = await Future.wait([
        _repo.wallet(walletTab),
        _repo.collectable(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as CouponWallet;
        _walletTab = walletTab;
        _collectable = results[1] as CollectableCoupons;
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

  Future<void> _saveCoupon([String? value]) async {
    // Chuẩn hóa mã nhập tay hoặc mã lấy từ thẻ trước khi gửi lên API.
    final code = (value ?? _codeController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã ưu đãi.')));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _repo.save(code);
      if (!mounted) return;
      final alreadySaved = JsonUtils.asBool(result['alreadySaved']);
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? 'Mã $code đã có trong ví.'
                : 'Đã lưu mã $code vào ví.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  int _count(String tab) {
    if (tab == 'collectable') return _collectable?.coupons.length ?? 0;
    return _wallet?.counts[tab] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mã giảm giá của tôi')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.p16,
                AppDimens.p12,
                AppDimens.p16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lưu mã vào ví, đến giỏ hàng chọn mã ở mục Mã giảm giá. Mỗi đơn hàng dùng tối đa 1 mã.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveCoupon(),
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã marketing gửi cho bạn',
                            prefixIcon: Icon(Icons.confirmation_num_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimens.p8),
                      FilledButton(
                        onPressed: _saving ? null : () => _saveCoupon(),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Lưu vào ví'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.p12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppDimens.p8),
                          ChoiceChip(
                            label: Text('${_labels[i]} ${_count(_tabs[i])}'),
                            selected: _tab == _tabs[i],
                            onSelected: (_) => _selectTab(_tabs[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(error: _error, onRetry: _reloadCurrent);
    }
    if (_tab == 'collectable') return _buildCollectableList();
    final coupons = _wallet?.items ?? const <Coupon>[];
    if (coupons.isEmpty) {
      return EmptyView(
        icon: Icons.local_activity_outlined,
        title: _tab == 'usable'
            ? 'Ví chưa có mã giảm giá'
            : 'Chưa có mã ở mục này',
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadCurrent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p16,
          AppDimens.p8,
          AppDimens.p16,
          AppDimens.p24,
        ),
        itemCount: coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p12),
        itemBuilder: (context, index) =>
            _couponCard(coupons[index], saved: true),
      ),
    );
  }

  Widget _buildCollectableList() {
    final collectable = _collectable;
    final coupons = collectable?.coupons ?? const <Coupon>[];
    if (coupons.isEmpty && (collectable?.loyaltyUpcoming.isEmpty ?? true)) {
      return const EmptyView(
        icon: Icons.local_activity_outlined,
        title: 'Hiện chưa có mã để thu thập',
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadCurrent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.p16,
          AppDimens.p8,
          AppDimens.p16,
          AppDimens.p24,
        ),
        children: [
          for (final coupon in coupons) ...[
            _couponCard(coupon),
            const SizedBox(height: AppDimens.p12),
          ],
          if (collectable != null &&
              collectable.loyaltyUpcoming.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimens.p8,
                bottom: AppDimens.p12,
              ),
              child: Text(
                'Ưu đãi thân thiết sắp mở',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final item in collectable.loyaltyUpcoming)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(JsonUtils.asString(item['title'])),
                  subtitle: Text(JsonUtils.asString(item['progress'])),
                  trailing: Text(JsonUtils.asString(item['discountText'])),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _couponCard(Coupon coupon, {bool saved = false}) => CouponVoucherCard(
    coupon: coupon,
    saved: saved,
    onDetails: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CouponDetailsScreen(code: coupon.code),
      ),
    ),
    onSave: saved || coupon.saved || _saving
        ? null
        : () => _saveCoupon(coupon.code),
  );
}
