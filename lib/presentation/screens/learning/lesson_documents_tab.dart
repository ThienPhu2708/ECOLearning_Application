import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/lesson_resources_repository.dart';

class LessonDocumentsTab extends StatefulWidget {
  const LessonDocumentsTab({
    super.key,
    required this.courseId,
    required this.lessonId,
    this.active = true,
    this.repository,
  });
  final String courseId, lessonId;
  final bool active;
  final LessonResourcesRepository? repository;
  @override
  State<LessonDocumentsTab> createState() => _LessonDocumentsTabState();
}

class _LessonDocumentsTabState extends State<LessonDocumentsTab> {
  late final _repo = widget.repository ?? LessonResourcesRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error, _opening;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LessonDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.documents(widget.courseId, widget.lessonId);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Chưa tải được tài liệu.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> doc) async {
    if (_opening != null) return;
    final id = doc['id'].toString();
    setState(() => _opening = id);
    try {
      final bytes = await _repo.download(id);
      final directory = await getApplicationDocumentsDirectory();
      final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final folder = await Directory(
        '${directory.path}/lesson_documents/$safeId',
      ).create(recursive: true);
      final name = (doc['fileName']?.toString() ?? 'tai-lieu')
          .split(RegExp(r'[/\\]'))
          .last
          .replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_');
      final file = File(
        '${folder.path}/${name.isEmpty || name == '.' || name == '..' ? 'tai-lieu' : name}',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw const ApiException(
          message:
              'Đã lưu tài liệu. Điện thoại chưa có ứng dụng mở loại tệp này.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Không mở được tài liệu. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  String _size(dynamic bytes) {
    if (bytes is! num) return '';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  Widget _documentCard(Map<String, dynamic> doc) {
    final type = (doc['fileType']?.toString() ?? 'file').toUpperCase();
    final available = doc['isAvailable'] != false;
    final busy = _opening == doc['id'].toString();
    final color = !available
        ? AppColors.textMuted
        : switch (type) {
            'PDF' => const Color(0xFFE05252),
            'DOC' || 'DOCX' => const Color(0xFF3974C6),
            'XLS' || 'XLSX' || 'CSV' => const Color(0xFF29956C),
            'PPT' || 'PPTX' => const Color(0xFFD27D37),
            _ => AppColors.primary,
          };
    final title = (doc['title']?.toString() ?? 'Tài liệu').replaceAll('_', ' ');
    final size = _size(doc['sizeBytes']);
    final enabled = available && _opening == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => _open(doc) : null,
          onLongPress: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Tên tài liệu'),
              content: SelectableText(doc['fileName']?.toString() ?? title),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'PDF'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.description_outlined,
                        color: color,
                        size: 23,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: available
                              ? AppColors.textHeading
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        !available
                            ? 'Tệp không còn'
                            : [type, if (size.isNotEmpty) size].join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton.filledTonal(
                          tooltip: available
                              ? 'Tải và mở tài liệu'
                              : 'Tệp không còn',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          onPressed: enabled ? () => _open(doc) : null,
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 21,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ] else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Bài học chưa có tài liệu')),
            ),
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tài liệu bài học',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  Text(
                    '${_items.length} tệp',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          for (final doc in _items) _documentCard(doc),
        ],
      ),
    );
  }
}
