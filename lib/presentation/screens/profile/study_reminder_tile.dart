import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/notifications/study_reminder_service.dart';
import '../../widgets/state_views.dart';

class StudyReminderTile extends StatefulWidget {
  final StudyReminderService? service;
  const StudyReminderTile({super.key, this.service});
  @override
  State<StudyReminderTile> createState() => _StudyReminderTileState();
}

class _StudyReminderTileState extends State<StudyReminderTile>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? StudyReminderService.instance;
  ReminderSettings _settings = const ReminderSettings();
  bool _busy = true, _blocked = false, _picking = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy && !_picking) _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final settings = await _service.load();
      final blocked =
          settings.enabled && !await _service.notifications.isAllowed();
      if (mounted) {
        setState(() {
          _settings = settings;
          _blocked = blocked;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa đọc được lịch nhắc. Chạm để thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(bool enabled) async {
    if (_busy || _picking) return;
    if (!enabled) {
      await _apply(() => _service.disable());
      return;
    }
    setState(() => _picking = true);
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _settings.hour, minute: _settings.minute),
      helpText: 'Giờ nhắc học mỗi ngày',
      cancelText: 'Hủy',
      confirmText: 'Lưu giờ nhắc',
      hourLabelText: 'Giờ',
      minuteLabelText: 'Phút',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted) return;
    setState(() => _picking = false);
    if (selected != null) await _apply(() => _service.enable(selected));
  }

  Future<void> _apply(Future<ReminderSettings> Function() action) async {
    setState(() => _busy = true);
    try {
      final settings = await action();
      if (mounted) {
        setState(() {
          _settings = settings;
          _blocked = false;
          _error = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.enabled
                  ? 'Đã đặt nhắc học mỗi ngày ${settings.exact ? 'lúc' : 'khoảng'} ${settings.timeLabel}.'
                  : 'Đã tắt nhắc học.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: const Text(
            'Thông báo học tập',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _blocked
                  ? 'Thông báo đang bị chặn trong Cài đặt điện thoại.'
                  : _settings.enabled
                  ? 'Nhắc mỗi ngày ${_settings.exact ? 'lúc' : 'khoảng'} ${_settings.timeLabel}'
                  : 'Chọn giờ để nhắc học mỗi ngày.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          value: _settings.enabled,
          activeTrackColor: AppColors.primary,
          onChanged: _busy || _picking || _error != null ? null : _change,
        ),
        if (_settings.enabled && !_blocked)
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: TextButton.icon(
              onPressed: _busy || _picking ? null : () => _change(true),
              icon: const Icon(Icons.schedule_rounded, size: 17),
              label: const Text('Đổi giờ nhắc'),
            ),
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
