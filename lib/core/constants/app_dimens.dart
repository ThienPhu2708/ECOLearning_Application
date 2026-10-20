import 'package:flutter/material.dart';

/// Design Tokens: Kích thước, bo góc và đổ bóng chuẩn
class AppDimens {
  AppDimens._();

  // Spacing & Padding
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  // Minimum Touch Target
  static const double minTouchTarget = 48.0;

  // Border Radius
  static final BorderRadius radiusFull = BorderRadius.circular(9999.0);
  static final BorderRadius radiusButton = BorderRadius.circular(12.0);
  static final BorderRadius radiusInput = BorderRadius.circular(12.0);
  static final BorderRadius radiusCard = BorderRadius.circular(16.0);
  static const BorderRadius radiusSheet = BorderRadius.vertical(
    top: Radius.circular(24.0),
  );

  // Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: -2,
    ),
  ];

  static final List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
}
