import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/json_utils.dart';
import '../../data/repositories/review_repository.dart';

/// "Bạn thấy hữu ích?" dưới một đánh giá (E2, giống website).
/// Bấm lại lựa chọn đang có để bỏ bình chọn. Đánh giá của chính mình chỉ hiện số đếm.
class ReviewHelpfulBar extends StatefulWidget {
  /// Một phần tử `items` của B4: `id`, `helpfulCount`, `notHelpfulCount`, `myVote`, `isMine`
  final Map<String, dynamic> review;
  final ReviewRepository? repository;

  /// Mặc định: có token đăng nhập
  final bool Function()? isLoggedIn;

  const ReviewHelpfulBar({
    super.key,
    required this.review,
    this.repository,
    this.isLoggedIn,
  });

  @override
  State<ReviewHelpfulBar> createState() => _ReviewHelpfulBarState();
}

class _ReviewHelpfulBarState extends State<ReviewHelpfulBar> {
  late int _helpful = JsonUtils.asInt(widget.review['helpfulCount']);
  late int _notHelpful = JsonUtils.asInt(widget.review['notHelpfulCount']);
  late bool? _myVote = _vote(widget.review['myVote']);
  bool _sending = false;

  bool get _isMine => JsonUtils.asBool(widget.review['isMine']);

  static bool? _vote(dynamic v) => v is bool ? v : null;

  Future<void> _send(bool helpful) async {
    if (_sending) return;
    final messenger = ScaffoldMessenger.of(context);
    final loggedIn = (widget.isLoggedIn ?? () => TokenStorage.instance.hasToken)();
    if (!loggedIn) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để bình chọn đánh giá.')),
        );
      return;
    }
    setState(() => _sending = true);
    try {
      final data = await (widget.repository ?? ReviewRepository()).vote(
        JsonUtils.asString(widget.review['id']),
        helpful: helpful,
      );
      if (!mounted) return;
      setState(() {
        _helpful = JsonUtils.asInt(data['helpfulCount']);
        _notHelpful = JsonUtils.asInt(data['notHelpfulCount']);
        _myVote = _vote(data['myVote']);
      });
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _isMine
        ? 'Đánh giá của bạn'
        : _myVote == null
        ? 'Bạn thấy hữu ích?'
        : 'Cảm ơn bạn đã bình chọn';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.captionTiny.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _VoteButton(
          tooltip: 'Hữu ích',
          icon: Icons.thumb_up_alt_outlined,
          selectedIcon: Icons.thumb_up_alt_rounded,
          count: _helpful,
          selected: _myVote == true,
          onPressed: _isMine || _sending ? null : () => _send(true),
        ),
        const SizedBox(width: 6),
        _VoteButton(
          tooltip: 'Không hữu ích',
          icon: Icons.thumb_down_alt_outlined,
          selectedIcon: Icons.thumb_down_alt_rounded,
          count: _notHelpful,
          selected: _myVote == false,
          onPressed: _isMine || _sending ? null : () => _send(false),
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final IconData selectedIcon;
  final int count;
  final bool selected;
  final VoidCallback? onPressed;

  const _VoteButton({
    required this.tooltip,
    required this.icon,
    required this.selectedIcon,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.captionTiny.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
