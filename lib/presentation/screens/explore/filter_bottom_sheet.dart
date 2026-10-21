import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/app_button.dart';

class FilterCriteria {
  double minRating; // 0.0, 3.0, 4.0, 4.5
  String level;     // 'Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'
  bool onlyFree;
  String sort;      // popular, newest, rating, price_asc, price_desc (B2)

  static const String defaultSort = 'popular';

  FilterCriteria({
    this.minRating = 0.0,
    this.level = 'Tất cả',
    this.onlyFree = false,
    this.sort = defaultSort,
  });

  FilterCriteria clone() {
    return FilterCriteria(
      minRating: minRating,
      level: level,
      onlyFree: onlyFree,
      sort: sort,
    );
  }

  /// Có lọc theo sao / trình độ / giá (sắp xếp không tính là lọc)
  bool get hasFilter => minRating > 0 || level != 'Tất cả' || onlyFree;
  bool get isDefault => !hasFilter && sort == defaultSort;
}

/// Modal Bottom Sheet Bộ lọc nâng cao theo QuyChuanThietKe_App.md Mục 4.3 & UC4
class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final Function(FilterCriteria) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required FilterCriteria initialCriteria,
    required Function(FilterCriteria) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialCriteria: initialCriteria,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterCriteria _criteria;

  final List<String> _levels = ['Tất cả', 'Cơ bản', 'Trung cấp', 'Nâng cao'];
  final List<Map<String, String>> _sorts = [
    {'label': 'Phổ biến', 'val': 'popular'},
    {'label': 'Mới nhất', 'val': 'newest'},
    {'label': 'Đánh giá cao', 'val': 'rating'},
    {'label': 'Giá tăng dần', 'val': 'price_asc'},
    {'label': 'Giá giảm dần', 'val': 'price_desc'},
  ];
  final List<Map<String, dynamic>> _ratings = [
    {'label': 'Tất cả xếp hạng', 'val': 0.0},
    {'label': 'Từ 3.0★ trở lên', 'val': 3.0},
    {'label': 'Từ 4.0★ trở lên', 'val': 4.0},
    {'label': 'Từ 4.5★ trở lên', 'val': 4.5},
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria.clone();
  }

  void _reset() {
    setState(() {
      _criteria = FilterCriteria();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.p24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.radiusSheet,
      ),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc tìm kiếm',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  'Thiết lập lại',
                  style: AppTypography.captionTiny.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // 1. Tiêu chí Xếp hạng đánh giá (Stars)
          Text(
            'Xếp hạng đánh giá',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _ratings.map((r) {
              final isSelected = _criteria.minRating == r['val'];
              return ChoiceChip(
                label: Text(r['label'] as String),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceSubtle,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textHeading,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.0,
                ),
                onSelected: (val) {
                  setState(() => _criteria.minRating = r['val'] as double);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // 2. Tiêu chí Cấp độ
          Text(
            'Trình độ học viên',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _levels.map((lvl) {
              final isSelected = _criteria.level == lvl;
              return ChoiceChip(
                label: Text(lvl),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceSubtle,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textHeading,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.0,
                ),
                onSelected: (val) {
                  setState(() => _criteria.level = lvl);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // 3. Sắp xếp (B2 sort)
          Text(
            'Sắp xếp theo',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _sorts.map((o) {
              final isSelected = _criteria.sort == o['val'];
              return ChoiceChip(
                label: Text(o['label']!),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceSubtle,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textHeading,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.0,
                ),
                onSelected: (val) {
                  setState(() => _criteria.sort = o['val']!);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // 4. Mức giá (Switch Miễn phí)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chỉ hiển thị khóa học Miễn phí',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _criteria.onlyFree,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _criteria.onlyFree = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Nút Áp dụng bộ lọc
          AppButton(
            text: 'Áp dụng bộ lọc',
            onPressed: () {
              widget.onApply(_criteria);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      ),
    );
  }
}
