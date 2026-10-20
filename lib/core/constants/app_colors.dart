import 'package:flutter/material.dart';

/// Design Tokens: Bảng mã màu chuẩn ứng dụng Mobile E-Learning
/// Kế thừa và đồng bộ 100% với QuyChuanThietKe_App.md
class AppColors {
  AppColors._();

  // Brand Primary (Electric Indigo)
  static const Color primary = Color(0xFF434CE8);
  static const Color primaryHover = Color(0xFF353EC4);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);    // Pure White
  static const Color surfaceSubtle = Color(0xFFF1F5F9); // Slate 100

  // Text Typography Colors
  static const Color textHeading = Color(0xFF0F172A);   // Slate 900
  static const Color textBody = Color(0xFF334155);      // Slate 700
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Semantic States
  static const Color success = Color(0xFF10B981);      // Emerald (Tích xanh >= 80%)
  static const Color successLight = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);      // Amber (Sao vàng 5*, Bán chạy)
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFEF4444);        // Rose Red (Lỗi, xóa giỏ, đăng xuất)
  static const Color errorLight = Color(0xFFFEF2F2);
}
