import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';

/// Điều hướng không cần BuildContext, dùng khi lớp gọi API báo phiên đăng nhập hết hạn (401).
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Xóa toàn bộ màn hình đang mở, về màn Đăng nhập (kèm thông báo nếu có)
  static void toLogin({String? message}) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    if (message != null) showMessage(message);
  }

  static void showMessage(String message) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
