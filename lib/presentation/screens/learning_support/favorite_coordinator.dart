import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../core/storage/token_storage.dart';

/// One favorite state for cards, detail and the saved-course list.
class FavoriteCoordinator extends ChangeNotifier {
  FavoriteCoordinator(this.repository);
  final FavoriteRepository repository;
  static String? _token;
  static FavoriteCoordinator? _api;
  static FavoriteCoordinator get api {
    final token = TokenStorage.instance.token;
    if (_api == null || token != _token) {
      _token = token;
      _api = forRepository(FavoriteRepository());
    }
    return _api!;
  }

  static final _instances = Expando<FavoriteCoordinator>();
  static FavoriteCoordinator forRepository(FavoriteRepository repository) =>
      _instances[repository] ??= FavoriteCoordinator(repository);
  final Map<String, bool> _values = {};
  final Map<String, int> _changedAt = {};
  final Set<String> _pending = {};
  int _version = 0;
  bool _loaded = false;
  Future<void>? _loading;
  void register(Course course) {
    _values.putIfAbsent(course.id, () => _loaded ? false : course.isFavorite);
  }

  bool isFavorite(Course course) => _values[course.id] ?? course.isFavorite;
  bool get loading => _loading != null;
  bool isPending(String id) => _pending.contains(id);
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _read().whenComplete(() {
      _loading = null;
      notifyListeners();
    });
  }

  Future<void> _read() async {
    final started = _version;
    final favorites = <String>{};
    try {
      int page = 1;
      while (true) {
        final data = await repository.list(page: page);
        favorites.addAll(data.items.map((c) => c.id));
        if (!data.hasMore) break;
        page++;
      }
      for (final id in {..._values.keys, ...favorites}) {
        if ((_changedAt[id] ?? 0) <= started) {
          _values[id] = favorites.contains(id);
        }
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // A failed initial read must not pretend that a toggle was saved.
      // The next visit can retry, and toggle errors are shown by the caller.
    }
  }

  Future<bool> toggle(Course course) async {
    if (_pending.contains(course.id)) return isFavorite(course);
    _pending.add(course.id);
    notifyListeners();
    try {
      final favorite = await repository.toggle(course.id);
      _values[course.id] = favorite;
      _changedAt[course.id] = ++_version;
      course.isFavorite = favorite;
      return favorite;
    } finally {
      _pending.remove(course.id);
      notifyListeners();
    }
  }
}
