import 'dart:async';
import '../../core/storage/token_storage.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/course.dart';
import '../../data/repositories/favorite_repository.dart';
import '../screens/learning_support/favorite_coordinator.dart';
import '../screens/learning_support/learning_data_scope.dart';
import 'state_views.dart';

class CourseFavoriteButton extends StatefulWidget {
  final Course course;
  final FavoriteRepository? repository;
  final double size;
  const CourseFavoriteButton({
    super.key,
    required this.course,
    this.repository,
    this.size = 36,
  });
  @override
  State<CourseFavoriteButton> createState() => _CourseFavoriteButtonState();
}

class _CourseFavoriteButtonState extends State<CourseFavoriteButton> {
  late FavoriteCoordinator _state;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository =
        widget.repository ?? LearningDataScope.read(context)?.favorites;
    _state = repository == null
        ? FavoriteCoordinator.api
        : FavoriteCoordinator.forRepository(repository);
    _state.register(widget.course);
    if (repository != null || TokenStorage.instance.hasToken) {
      unawaited(_state.ensureLoaded());
    }
  }

  @override
  void didUpdateWidget(CourseFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      final repository =
          widget.repository ?? LearningDataScope.read(context)?.favorites;
      _state = repository == null
          ? FavoriteCoordinator.api
          : FavoriteCoordinator.forRepository(repository);
      if (repository != null || TokenStorage.instance.hasToken) {
        unawaited(_state.ensureLoaded());
      }
    }
    _state.register(widget.course);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _state,
    builder: (context, _) {
      final selected = _state.isFavorite(widget.course);
      final busy = _state.loading || _state.isPending(widget.course.id);
      return Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: widget.size,
              height: widget.size,
            ),
            tooltip:
                '${selected ? 'Bỏ yêu thích' : 'Thêm vào yêu thích'} ${widget.course.title}',
            onPressed: busy
                ? null
                : () async {
                    if (widget.repository == null &&
                        LearningDataScope.read(context)?.favorites == null &&
                        !TokenStorage.instance.hasToken) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đăng nhập để lưu khóa học yêu thích.'),
                        ),
                      );
                      return;
                    }
                    try {
                      await _state.toggle(widget.course);
                    } catch (e) {
                      if (context.mounted) showErrorSnackBar(context, e);
                    }
                  },
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    selected
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: selected ? AppColors.error : AppColors.textSecondary,
                    size: 21,
                  ),
          ),
        ),
      );
    },
  );
}
