import 'package:flutter/foundation.dart';
import '../../../core/network/paged_result.dart';

class PagedCollection<T> extends ChangeNotifier {
  PagedCollection(this.fetch, this.id);
  final Future<PagedResult<T>> Function(int page) fetch;
  final String Function(T value) id;
  List<T> items = [];
  int total = 0;
  int totalPages = 0;
  int get page => _page;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = false;
  Object? error;
  int _page = 0;
  int _generation = 0;
  bool _disposed = false;
  final Set<String> _removed = {};
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool more = false, int targetPage = 1}) async {
    if (more && (loading || loadingMore || !hasMore)) return;
    final generation = more ? _generation : ++_generation;
    final page = more ? _page + 1 : targetPage;
    if (more) {
      loadingMore = true;
    } else {
      loading = true;
      loadingMore = false;
      _removed.clear();
    }
    error = null;
    _emit();
    try {
      final result = await fetch(page);
      if (_disposed || generation != _generation) return;
      final merged = {for (final item in more ? items : <T>[]) id(item): item};
      for (final item in result.items) {
        if (!_removed.contains(id(item))) merged[id(item)] = item;
      }
      items = merged.values.toList();
      total = result.total;
      totalPages = result.totalPages;
      _page = result.page;
      hasMore = result.hasMore;
    } catch (e) {
      if (!_disposed && generation == _generation) error = e;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        loadingMore = false;
        _emit();
      }
    }
  }

  void remove(String key) {
    _removed.add(key);
    items.removeWhere((value) => id(value) == key);
    total = (total - 1).clamp(0, 100000000);
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
