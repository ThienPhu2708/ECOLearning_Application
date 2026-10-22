import '../../../core/network/paged_result.dart';

/// Search all server pages because these endpoints do not accept a search query.
Future<PagedResult<T>> searchPages<T>({
  required Future<PagedResult<T>> Function(int page) fetch,
  required String query,
  required String Function(T item) text,
  required String Function(T item) id,
  required int page,
}) async {
  if (query.trim().isEmpty) return fetch(page);
  final terms = searchText(query).split(RegExp(r'\s+'));
  final matches = <String, T>{};
  var result = await fetch(1);
  final pageSize = result.pageSize > 0 ? result.pageSize : 12;
  while (true) {
    for (final item in result.items) {
      final value = searchText(text(item));
      if (terms.every(value.contains)) matches[id(item)] = item;
    }
    if (!result.hasMore) break;
    final next = await fetch(result.page + 1);
    if (next.page <= result.page) throw StateError('Invalid pagination');
    result = next;
  }
  final items = matches.values.toList();
  return PagedResult(
    items: items.skip((page - 1) * pageSize).take(pageSize).toList(),
    page: page,
    pageSize: pageSize,
    total: items.length,
    totalPages: (items.length / pageSize).ceil(),
  );
}

String searchText(String value) {
  var result = value.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  groups.forEach((letter, accents) {
    for (final accent in accents.split('')) {
      result = result.replaceAll(accent, letter);
    }
  });
  return result;
}
