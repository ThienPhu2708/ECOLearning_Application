import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Thanh phân trang gọn, một dòng, nằm sát góc phải và rộng tối đa nửa màn hình: `‹ 1 … 5 … 20 ›`.
/// Luôn hiện trang đầu, trang hiện tại và trang cuối; chỗ bị lược thay bằng "…". Trang 1 và trang cuối
/// hiện thêm trang kề bên cho dễ bấm. [page] bắt đầu từ 1. Không hiện gì nếu chỉ có 1 trang.
class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool enabled;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.enabled = true,
  });

  /// Danh sách mục hiển thị: số trang, hoặc null là dấu "…"
  static List<int?> items(int page, int totalPages) {
    final wanted = <int>{1, totalPages, page};
    if (page == 1) wanted.add(2);
    if (page == totalPages) wanted.add(totalPages - 1);
    final shown = wanted.where((p) => p >= 1 && p <= totalPages).toList()..sort();
    final result = <int?>[];
    for (var i = 0; i < shown.length; i++) {
      if (i > 0) {
        final gap = shown[i] - shown[i - 1];
        if (gap == 2) {
          result.add(shown[i] - 1); // chỉ thiếu đúng 1 trang thì hiện luôn số đó
        } else if (gap > 2) {
          result.add(null);
        }
      }
      result.add(shown[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final maxWidth = MediaQuery.of(context).size.width * 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          // Hẹp quá thì thu nhỏ cả hàng chứ không xuống dòng
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _arrow(Icons.chevron_left_rounded, 'Trang trước', page > 1 ? () => onPageChanged(page - 1) : null),
                for (final p in items(page, totalPages))
                  if (p == null)
                    const SizedBox(
                      width: 18,
                      child: Center(child: Text('…', style: TextStyle(color: AppColors.textMuted))),
                    )
                  else
                    _number(p),
                _arrow(Icons.chevron_right_rounded, 'Trang sau',
                    page < totalPages ? () => onPageChanged(page + 1) : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onTap) {
    final active = enabled && onTap != null;
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 22,
        icon: Icon(icon, color: active ? AppColors.textHeading : AppColors.textMuted),
        onPressed: active ? onTap : null,
      ),
    );
  }

  Widget _number(int p) {
    final selected = p == page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled && !selected ? () => onPageChanged(p) : null,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            '$p',
            style: AppTypography.labelSmall.copyWith(
              color: selected ? Colors.white : AppColors.textHeading,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
