import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_navigator.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp token đã lưu và giỏ hàng trên máy trước khi vẽ màn hình đầu tiên
  await TokenStorage.instance.load();
  final auth = AuthProvider();
  final cart = CartProvider();
  await cart.load();

  // Token hết hạn / bị thu hồi (401): xóa phiên, về màn Đăng nhập
  ApiClient.instance.onUnauthorized = () async {
    if (auth.isLoggingOut) return;
    await auth.handleSessionExpired();
    AppNavigator.toLogin(message: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
  };

  runApp(EcoLearningApp(auth: auth, cart: cart));
}

class EcoLearningApp extends StatelessWidget {
  final AuthProvider auth;
  final CartProvider cart;

  const EcoLearningApp({super.key, required this.auth, required this.cart});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CartProvider>.value(value: cart),
      ],
      child: MaterialApp(
        title: 'ECOLearning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: AppNavigator.navigatorKey,
        scaffoldMessengerKey: AppNavigator.messengerKey,
        home: const SplashScreen(),
      ),
    );
  }
}
