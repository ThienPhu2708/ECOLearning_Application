import 'package:flutter/foundation.dart';

import '../../../data/models/course.dart';
import '../../../data/repositories/learning_repository.dart';

class MyCoursesPageState {
  List<Course> courses = [];
  int? total;
  int page = 0;
  bool hasMore = false;
  bool loading = true;
  bool loadingMore = false;
  Object? error;
  Object? moreError;
  int request = 0;
}

/// Independent pagination for each tab; a refresh supersedes older requests.
class MyCoursesController extends ChangeNotifier {
  MyCoursesController(this.repository);

  final LearningRepository repository;
  final ongoing = MyCoursesPageState();
  final completed = MyCoursesPageState();
  bool _disposed = false;

  MyCoursesPageState stateFor(String status) =>
      status == MyCourseStatus.completed ? completed : ongoing;

  Future<void> load() => Future.wait([
    refresh(MyCourseStatus.inProgress),
    refresh(MyCourseStatus.completed),
  ]);

  Future<void> refresh(String status) async {
    final state = stateFor(status);
    final request = ++state.request;
    state.loading = true;
    state.loadingMore = false;
    state.error = null;
    state.moreError = null;
    _emit();
    try {
      final result = await repository.myCourses(status: status);
      if (_disposed || request != state.request) return;
      state.courses = _unique(result.items);
      state.total = result.total;
      state.page = result.page;
      state.hasMore = result.hasMore;
    } catch (error) {
      if (_disposed || request != state.request) return;
      state.error = error;
    } finally {
      if (!_disposed && request == state.request) {
        state.loading = false;
        _emit();
      }
    }
  }

  Future<void> loadMore(String status) async {
    final state = stateFor(status);
    if (_disposed || state.loading || state.loadingMore || !state.hasMore) {
      return;
    }
    final request = state.request;
    state.loadingMore = true;
    state.moreError = null;
    _emit();
    try {
      final result = await repository.myCourses(
        status: status,
        page: state.page + 1,
      );
      if (_disposed || request != state.request) return;
      state.courses = _unique([...state.courses, ...result.items]);
      state.total = result.total;
      state.page = result.page;
      state.hasMore = result.hasMore;
    } catch (error) {
      if (_disposed || request != state.request) return;
      state.moreError = error;
    } finally {
      if (!_disposed && request == state.request) {
        state.loadingMore = false;
        _emit();
      }
    }
  }

  List<Course> _unique(List<Course> courses) {
    final byId = <String, Course>{};
    for (final course in courses) {
      byId[course.id] = course;
    }
    return byId.values.toList();
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
