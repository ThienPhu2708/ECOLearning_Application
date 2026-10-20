import 'package:flutter/material.dart';

import '../../core/utils/json_utils.dart';

/// Model Danh mục khóa học
class Category {
  final String id;
  final String name;
  final IconData icon;
  final String emoji;
  final int coursesCount;
  final String? imageUrl; // Ảnh minh họa do Admin cập nhật (B1)

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.emoji,
    this.coursesCount = 0,
    this.imageUrl,
  });

  /// B1 `{ "id", "name", "imageUrl", "coursesCount" }`. API không có icon / emoji nên dùng mặc định;
  /// màn hình ưu tiên hiện [imageUrl] nếu có.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: JsonUtils.asString(json['id']),
      name: JsonUtils.asString(json['name']),
      icon: Icons.school_outlined,
      emoji: '📚',
      coursesCount: JsonUtils.asInt(json['coursesCount']),
      imageUrl: JsonUtils.asStringOrNull(json['imageUrl']),
    );
  }
}
