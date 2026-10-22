import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/json_utils.dart';
import '../../data/models/course.dart';

/// Một khóa học trong giỏ (lưu trên máy để hiện nhanh; giá thật luôn lấy lại từ server bằng F1)
class CartItem {
  final String id;
  final String title;
  final String imageUrl;
  final String instructor;
  final double price;
  final double originalPrice;

  const CartItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.instructor,
    required this.price,
    required this.originalPrice,
  });

  factory CartItem.fromCourse(Course c) => CartItem(
        id: c.id,
        title: c.title,
        imageUrl: c.imageUrl,
        instructor: c.instructor,
        price: c.price,
        originalPrice: c.originalPrice,
      );

  /// Course tối thiểu để mở màn chi tiết từ giỏ (màn chi tiết tải lại đầy đủ bằng B3)
  Course toCourse() => Course(
        id: id,
        title: title,
        category: '',
        instructor: instructor,
        rating: 0,
        reviewCount: 0,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        tag: '',
        level: '',
        duration: '',
        lessonsCount: 0,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: JsonUtils.asString(json['id']),
        title: JsonUtils.asString(json['title']),
        imageUrl: JsonUtils.asString(json['imageUrl']),
        instructor: JsonUtils.asString(json['instructor']),
        price: JsonUtils.asDouble(json['price']),
        originalPrice: JsonUtils.asDouble(json['originalPrice']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'instructor': instructor,
        'price': price,
        'originalPrice': originalPrice,
      };
}

/// Giỏ hàng lưu trên máy (Task_Tuan10.docx: T-6, quy tắc "Giá" mục 7).
/// Server không giữ giỏ hàng: mỗi lần mở giỏ / đổi mã, màn Giỏ hàng gọi F1 với [ids] để lấy giá mới nhất.
class CartProvider extends ChangeNotifier {
  static const _key = 'cart_items';

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  List<String> get ids => _items.map((e) => e.id).toList();
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  bool contains(String courseId) => _items.any((e) => e.id == courseId);

  /// Gọi 1 lần khi mở app (main.dart)
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      _items
        ..clear()
        ..addAll(JsonUtils.asMapList(raw == null ? null : jsonDecode(raw)).map(CartItem.fromJson));
    } catch (_) {
      _items.clear();
    }
    notifyListeners();
  }

  /// Thêm vào giỏ. Trả false nếu đã có trong giỏ.
  Future<bool> add(Course course) async {
    if (contains(course.id)) return false;
    _items.add(CartItem.fromCourse(course));
    await _save();
    return true;
  }

  /// Cập nhật giá lưu trên máy theo giá mới nhất server báo (F1) để giỏ luôn hiện đúng, kể cả khi mất mạng
  Future<void> updatePrices(Map<String, double> prices, Map<String, double> originalPrices) async {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final price = prices[item.id];
      if (price == null) continue;
      final original = originalPrices[item.id] ?? price;
      if (price != item.price || original != item.originalPrice) {
        _items[i] = CartItem(
          id: item.id,
          title: item.title,
          imageUrl: item.imageUrl,
          instructor: item.instructor,
          price: price,
          originalPrice: original,
        );
        changed = true;
      }
    }
    if (changed) await _save();
  }

  /// Hoàn tác xóa khỏi giỏ
  Future<void> restore(CartItem item) async {
    if (contains(item.id)) return;
    _items.add(item);
    await _save();
  }

  Future<void> remove(String courseId) async {
    _items.removeWhere((e) => e.id == courseId);
    await _save();
  }

  /// Bỏ các khóa đã mua xong (F4 `paid`) hoặc server báo không mua được (F1 `invalidItems`)
  Future<void> removeAll(Iterable<String> courseIds) async {
    final set = courseIds.toSet();
    _items.removeWhere((e) => set.contains(e.id));
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Không lưu được thì giỏ chỉ mất khi tắt app, không ảnh hưởng thao tác hiện tại
    }
  }
}
