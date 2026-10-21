import 'package:flutter/material.dart';
import '../learning_support/learning_data_scope.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/json_utils.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/order_repository.dart';
import '../../widgets/state_views.dart';
import '../learning_support/paged_collection.dart';

String orderMoney(dynamic value) {
  final amount = JsonUtils.asDouble(value);
  return amount == 0 ? '0 đ' : AppFormatters.formatCurrency(amount);
}

String orderDate(dynamic value) {
  final date = JsonUtils.asDate(value);
  return date == null
      ? '—'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

Widget orderStatus(Map<String, dynamic> order) {
  final status = JsonUtils.asString(order['status']);
  final color = status == 'paid'
      ? AppColors.success
      : status == 'pending'
      ? AppColors.warning
      : status == 'failed'
      ? AppColors.error
      : AppColors.textSecondary;
  const labels = {
    'paid': 'Đã thanh toán',
    'pending': 'Chờ thanh toán',
    'failed': 'Thanh toán thất bại',
    'expired': 'Đã hết hạn',
    'cancelled': 'Đã hủy',
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      JsonUtils.asString(
        order['statusText'],
        fallback: labels[status] ?? 'Chưa xác định',
      ),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class OrderHistoryScreen extends StatefulWidget {
  final OrderRepository? repository;
  const OrderHistoryScreen({super.key, this.repository});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderRepository _repo =
      widget.repository ??
      LearningDataScope.read(context)?.orders ??
      OrderRepository();
  late final PagedCollection<Map<String, dynamic>> _list = PagedCollection(
    (page) => _repo.orders(page: page),
    (o) => JsonUtils.asString(o['orderId']),
  );
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    _list.addListener(_update);
    _list.load();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _list.removeListener(_update);
    _list.dispose();
    super.dispose();
  }

  Future<void> _open(String id) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: id, repository: _repo),
        ),
      );
      if (mounted) await _list.load();
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Lịch sử đơn hàng')),
    body: _list.loading && _list.items.isEmpty
        ? const LoadingView()
        : _list.error != null && _list.items.isEmpty
        ? ErrorView(error: _list.error, onRetry: _list.load)
        : RefreshIndicator(
            onRefresh: _list.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_list.items.isEmpty)
                  const SizedBox(
                    height: 380,
                    child: EmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: 'Bạn chưa có đơn hàng',
                      message: 'Các đơn mua khóa học sẽ xuất hiện tại đây.',
                    ),
                  ),
                if (_list.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Text(
                      '${_list.total} đơn hàng',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                for (final order in _list.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () =>
                            _open(JsonUtils.asString(order['orderId'])),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.receipt_long_outlined,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      JsonUtils.asString(order['orderId']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                orderDate(order['createdAt']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  orderStatus(order),
                                  Text(
                                    '${JsonUtils.asInt(order['itemsCount'])} khóa học',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Tổng thanh toán',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    orderMoney(order['total']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_list.error != null)
                  Text(
                    errorMessage(_list.error!),
                    style: const TextStyle(color: AppColors.error),
                  ),
                if (_list.error != null)
                  TextButton(
                    onPressed: () => _list.load(),
                    child: const Text('Tải lại danh sách'),
                  ),
                if (_list.hasMore)
                  TextButton(
                    onPressed: _list.loadingMore
                        ? null
                        : () => _list.load(more: true),
                    child: Text(_list.loadingMore ? 'Đang tải…' : 'Xem thêm'),
                  ),
              ],
            ),
          ),
  );
}

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final OrderRepository repository;
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.repository,
  });
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  Object? _error;
  bool _loading = true;
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
      final data = await widget.repository.order(widget.orderId);
      if (mounted) setState(() => _order = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 14),
                        SelectableText(
                          JsonUtils.asString(order['orderId']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 16),
                        orderStatus(order),
                        const SizedBox(height: 20),
                        _row('Ngày tạo', orderDate(order['createdAt'])),
                        if (order['paidAt'] != null)
                          _row('Thanh toán lúc', orderDate(order['paidAt'])),
                        if (order['paymentMethod'] != null)
                          _row(
                            'Phương thức',
                            JsonUtils.asString(order['paymentMethod']),
                          ),
                        if (JsonUtils.asString(
                          order['transactionNo'],
                        ).isNotEmpty)
                          _row(
                            'Mã giao dịch',
                            JsonUtils.asString(order['transactionNo']),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khóa học trong đơn',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final item in JsonUtils.asMapList(order['items']))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.menu_book_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    JsonUtils.asString(item['title']),
                                    style: const TextStyle(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(height: 28),
                        _row('Giảm giá', orderMoney(order['discount'])),
                        _row(
                          'Tổng thanh toán',
                          orderMoney(order['total']),
                          primary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
  Widget _row(String title, String value, {bool primary = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: primary ? FontWeight.w800 : FontWeight.w500,
              color: primary ? AppColors.primary : AppColors.textBody,
            ),
          ),
        ),
      ],
    ),
  );
}
