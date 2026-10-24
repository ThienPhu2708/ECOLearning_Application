import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../navigation/app_navigator.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/state_views.dart';

class CouponDetailsScreen extends StatefulWidget {
  const CouponDetailsScreen({super.key, required this.code, this.repository});

  final String code;
  final CouponRepository? repository;

  @override
  State<CouponDetailsScreen> createState() => _CouponDetailsScreenState();
}

class _CouponDetailsScreenState extends State<CouponDetailsScreen> {
  static const _generalRules = [
    'Mỗi đơn hàng chỉ áp dụng một mã giảm giá, không cộng dồn nhiều mã.',
    'Mã giảm trên giá bán hiện tại của khóa học, đã gồm giá khuyến mãi của khóa học nếu có.',
    'Lượt dùng chỉ được tính khi đơn hàng thanh toán thành công.',
    'Mã đã lưu không thể xóa khỏi danh sách và thao tác lưu không thể hoàn tác.',
    'Tiền giảm không quy đổi thành tiền mặt và không chuyển cho tài khoản khác.',
  ];

  late final CouponRepository _repo = widget.repository ?? CouponRepository();
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  Map<String, dynamic> _details = {};

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
      final result = await _repo.details(widget.code);
      if (!mounted) return;
      setState(() {
        _details = JsonUtils.asMap(result['coupon'] ?? result);
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

  Future<void> _save() async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      AppNavigator.toLogin(message: 'Đăng nhập để lưu mã ưu đãi vào ví.');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await _repo.save(widget.code);
      if (!mounted) return;
      final alreadySaved = JsonUtils.asBool(result['alreadySaved']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadySaved
                ? 'Mã ${widget.code} đã có trong ví.'
                : 'Đã lưu mã ${widget.code} vào ví.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết ưu đãi')),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : _buildContent(),
      bottomNavigationBar: !_loading && _error == null && _canSave
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppDimens.p16,
                AppDimens.p8,
                AppDimens.p16,
                AppDimens.p16,
              ),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_outlined),
                label: Text(_saving ? 'Đang lưu mã...' : 'Lưu mã vào ví'),
              ),
            )
          : null,
    );
  }

  bool get _canSave =>
      JsonUtils.asBool(_details['canSave']) &&
      !JsonUtils.asBool(_details['saved']);

  Widget _buildContent() {
    final coupon = Coupon.fromJson(_details);
    final terms = JsonUtils.asMapList(_details['terms']);
    final conditions = JsonUtils.asStringList(_details['conditions']);
    final courses = JsonUtils.asMapList(_details['courses']);
    final history = JsonUtils.asMapList(_details['myHistory']);
    final policyValue = _details['policy'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummary(coupon),
          if (terms.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
            _section('Chính sách áp dụng', [
              for (final term in terms)
                _termRow(
                  JsonUtils.asString(term['label']),
                  JsonUtils.asString(term['value']),
                ),
            ]),
          ],
          if (policyValue != null &&
              policyValue.toString().trim().isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
            _section('Quy định chung', [
              if (policyValue is String)
                Text(policyValue.toString())
              else
                for (final entry in JsonUtils.asMap(policyValue).entries)
                  _termRow(entry.key, entry.value.toString()),
            ]),
          ] else ...[
            const SizedBox(height: AppDimens.p16),
            _section('Quy định chung', [
              for (final rule in _generalRules)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.p8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(rule)),
                    ],
                  ),
                ),
            ]),
          ],
          if (terms.isEmpty && conditions.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
            _section('Điều kiện áp dụng', [
              for (final condition in conditions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.p8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(condition)),
                    ],
                  ),
                ),
            ]),
          ],
          if (courses.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
            _section('Khóa học áp dụng', [
              for (final course in courses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.school_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    JsonUtils.asString(
                      course['title'] ?? course['courseName'] ?? course['name'],
                      fallback: 'Khóa học',
                    ),
                  ),
                  subtitle: Text(
                    JsonUtils.asString(course['courseId'] ?? course['id']),
                  ),
                  trailing: course['price'] == null
                      ? null
                      : Text('${JsonUtils.asString(course['price'])} đ'),
                ),
            ]),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
            _section('Lịch sử sử dụng', [
              for (final record in history)
                _termRow(
                  JsonUtils.asString(
                    record['orderCode'] ?? record['orderId'] ?? 'Đơn hàng',
                  ),
                  _historyDescription(record),
                ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(Coupon coupon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 112,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: Text(
              coupon.discountText,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.p12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(coupon.description),
                  const SizedBox(height: 5),
                  Text(
                    coupon.code,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (coupon.statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        coupon.statusText,
                        style: AppTypography.captionTiny.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppDimens.p16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppDimens.radiusCard,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        ...children,
      ],
    ),
  );

  Widget _termRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimens.p8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.p8),
        Expanded(child: Text(value, style: AppTypography.bodyMedium)),
      ],
    ),
  );

  String _historyDescription(Map<String, dynamic> record) {
    final date = JsonUtils.asDate(record['usedAt'] ?? record['createdAt']);
    final discount = record['discount'] ?? record['discountAmount'];
    final parts = <String>[];
    if (date != null) parts.add('${date.day}/${date.month}/${date.year}');
    if (discount != null) parts.add('Giảm ${JsonUtils.asString(discount)} đ');
    return parts.isEmpty
        ? record.entries.map((e) => '${e.key}: ${e.value}').join(' · ')
        : parts.join(' · ');
  }
}
