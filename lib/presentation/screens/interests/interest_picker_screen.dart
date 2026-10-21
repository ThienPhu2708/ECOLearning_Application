import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/repositories/recommendation_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';
import '../main_navigation.dart';

/// Cổng vào app sau khi đăng nhập / đăng ký (T-3, API C2): nếu server báo `needSurvey = true`
/// thì hiện màn chọn lĩnh vực quan tâm, ngược lại vào thẳng Trang chủ.
class InterestGate {
  InterestGate._();

  static Future<void> enter(BuildContext context, {RecommendationRepository? repository}) async {
    final nav = Navigator.of(context);
    Widget next = const MainNavigationScreen();
    InterestStatus? status;
    try {
      status = await (repository ?? RecommendationRepository()).interests();
    } catch (_) {
      // Không kiểm tra được thì bỏ qua khảo sát, vào Trang chủ
    }
    if (status != null && status.needSurvey && status.categories.isNotEmpty) {
      next = InterestPickerScreen(initialStatus: status);
    }
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => next), (_) => false);
  }
}

/// Chọn lĩnh vực quan tâm (Task_Tuan10.docx mục 2.2). Phụ trách: Thư – việc T-3 – API C2, C3, C4.
/// Hiện lần đầu sau khi đăng nhập nếu needSurvey = true. Chọn tối đa 3 lĩnh vực, có nút Bỏ qua.
class InterestPickerScreen extends StatefulWidget {
  final InterestStatus? initialStatus;

  const InterestPickerScreen({super.key, this.initialStatus});

  @override
  State<InterestPickerScreen> createState() => _InterestPickerScreenState();
}

class _InterestPickerScreenState extends State<InterestPickerScreen> {
  final _repo = RecommendationRepository();

  InterestStatus? _status;
  Object? _error;
  bool _loading = false;
  bool _saving = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _status = widget.initialStatus;
      _selected.addAll(widget.initialStatus!.selected);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _repo.interests();
      if (!mounted) return;
      setState(() {
        _status = status;
        _selected
          ..clear()
          ..addAll(status.selected);
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

  int get _max => _status?.maxSelect ?? 3;

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < _max) {
        _selected.add(id);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Chỉ được chọn tối đa $_max lĩnh vực'),
            behavior: SnackBarBehavior.floating,
          ));
      }
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (_) => false,
    );
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.saveInterests(_selected.toList());
      if (!mounted) return;
      _goHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, e);
    }
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      await _repo.skipInterests();
    } catch (_) {
      // Lỗi mạng: vẫn cho vào app, lần sau server sẽ hỏi lại
    }
    if (!mounted) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null || _status == null) return ErrorView(error: _error, onRetry: _load);

    final categories = _status!.categories;
    return Padding(
      padding: const EdgeInsets.all(AppDimens.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : _skip,
                child: Text('Bỏ qua',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          Text('Bạn quan tâm lĩnh vực nào?', style: AppTypography.headlineMedium),
          const SizedBox(height: AppDimens.p8),
          Text(
            'Chọn tối đa $_max lĩnh vực để chúng tôi gợi ý khóa học phù hợp với bạn.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimens.p20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppDimens.p8,
                runSpacing: AppDimens.p8,
                children: categories.map((c) {
                  final selected = _selected.contains(c.id);
                  return FilterChip(
                    label: Text(c.name),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: 1.5),
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: selected ? AppColors.primary : AppColors.textBody,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.p8, vertical: AppDimens.p8),
                    onSelected: _saving ? null : (_) => _toggle(c.id),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.p16),
          AppButton(
            text: 'Tiếp tục (${_selected.length}/$_max)',
            isLoading: _saving,
            onPressed: _selected.isEmpty || _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
