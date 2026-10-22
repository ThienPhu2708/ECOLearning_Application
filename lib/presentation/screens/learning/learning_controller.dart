import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';

import '../../../data/models/lesson.dart';
import '../../../data/repositories/learning_repository.dart';

/// Keeps progress tied to the lesson that produced it, even during navigation.
class LearningController extends ChangeNotifier {
  LearningController(this.repository, this.courseId);
  final LearningRepository repository;
  final String courseId;
  LearningOverview? overview;
  Lesson? current;
  Object? error;
  Object? progressError;
  bool loading = false;
  bool selecting = false;
  bool _disposed = false;
  int _request = 0;
  Future<void> _saves = Future.value();
  final Map<String, (int, int)> _pending = {};

  List<Chapter> get chapters => overview?.chapters ?? [];

  /// Same sequential lesson rule as the web, across chapter boundaries.
  bool isUnlocked(String lessonId) {
    final lessons = chapters.expand((c) => c.lessons).toList();
    final index = lessons.indexWhere((l) => l.id == lessonId);
    return index >= 0 &&
        (index == 0 ||
            lessons[index].isCompleted ||
            lessons[index - 1].isCompleted);
  }

  double get progress => overview?.progress.clamp(0, 100).toDouble() ?? 0;
  bool get canReview =>
      (overview?.canReview ?? false) &&
      (overview?.quizPassed ?? false) &&
      progress >= 100;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final request = ++_request;
    loading = true;
    error = null;
    _emit();
    try {
      final data = await repository.overview(courseId);
      if (_disposed || request != _request) return;
      overview = data;
      final lessons = chapters.expand((c) => c.lessons).toList();
      current = null;
      if (lessons.isNotEmpty) {
        final chosen = lessons.firstWhere(
          (l) => l.id == data.currentLessonId && isUnlocked(l.id),
          orElse: () => lessons.firstWhere(
            (l) => !l.isCompleted && isUnlocked(l.id),
            orElse: () => lessons.first,
          ),
        );
        final selected = await repository.lesson(courseId, chosen.id);
        if (_disposed || request != _request) return;
        current = selected;
      }
    } catch (e) {
      if (!_disposed && request == _request) error = e;
    } finally {
      if (!_disposed && request == _request) {
        loading = false;
        _emit();
      }
    }
  }

  Future<bool> select(Lesson lesson) async {
    if (selecting || _disposed) return false;
    if (!isUnlocked(lesson.id)) {
      error = const ApiException(
        code: 'LESSON_LOCKED',
        message:
            'Cần xem ít nhất 80% bài trước và lưu tiến độ thành công để mở bài này.',
      );
      _emit();
      return false;
    }
    final request = ++_request;
    selecting = true;
    error = null;
    _emit();
    try {
      final data = await repository.lesson(courseId, lesson.id);
      if (_disposed || request != _request) return false;
      current = data;
      return true;
    } catch (e) {
      if (!_disposed && request == _request) error = e;
      return false;
    } finally {
      if (!_disposed && request == _request) {
        selecting = false;
        _emit();
      }
    }
  }

  Future<void> save(String lessonId, int position, int duration) {
    if (duration <= 0) return Future.value();
    final snapshot = (position.clamp(0, duration), duration);
    _pending[lessonId] = snapshot;
    // Serialize requests: an older response must never replace newer progress.
    _saves = _saves.then((_) async {
      try {
        final result = await repository.saveProgress(
          courseId,
          lessonId,
          positionSeconds: snapshot.$1,
          durationSeconds: snapshot.$2,
        );
        if (_pending[lessonId] == snapshot) _pending.remove(lessonId);
        if (_disposed) return;
        for (final l in chapters.expand((c) => c.lessons)) {
          if (l.id == lessonId) {
            l.isCompleted = result.lessonCompleted;
            l.lastPositionSeconds = snapshot.$1;
          }
        }
        if (current?.id == lessonId) {
          current!.isCompleted = result.lessonCompleted;
          current!.lastPositionSeconds = snapshot.$1;
        }
        final old = overview;
        if (old != null) {
          overview = LearningOverview(
            courseId: old.courseId,
            title: old.title,
            progress: result.courseProgress,
            currentLessonId: old.currentLessonId,
            chapters: old.chapters,
            quizAvailable: old.quizAvailable,
            quizPassed: old.quizPassed,
            certificateIssued: old.certificateIssued,
            canReview: old.canReview,
          );
        }
        progressError = _pending.isEmpty ? null : progressError;
        _emit();
        // Eligibility belongs to the server, never infer it from a local timer.
        if (result.lessonCompleted || snapshot.$1 >= snapshot.$2 * .8) {
          try {
            final latest = await repository.overview(courseId);
            if (!_disposed) {
              overview = latest;
              final saved = latest.chapters.expand((c) => c.lessons)
                  .where((l) => l.id == lessonId);
              if (current?.id == lessonId && saved.isNotEmpty) {
                current!.isCompleted = saved.first.isCompleted;
              }
              _emit();
            }
          } catch (_) {
            /* Progress was saved; keep the last confirmed eligibility. */
          }
        }
      } catch (e) {
        if (!_disposed) {
          progressError = e;
          _emit();
        }
      }
    });
    return _saves;
  }

  Future<void> retryProgress() async {
    for (final entry in Map.of(_pending).entries) {
      await save(entry.key, entry.value.$1, entry.value.$2);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
