import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ecolearning_app/main.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/providers/cart_provider.dart';

void main() {
  // Môi trường test không có mạng để tải font
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App khởi động tới màn Splash', (WidgetTester tester) async {
    await tester.pumpWidget(EcoLearningApp(auth: AuthProvider(), cart: CartProvider()));
    expect(find.byType(EcoLearningApp), findsOneWidget);
    // Tên thương hiệu đồng bộ với website
    expect(find.text('E-Learning'), findsOneWidget);
    expect(find.text('EDU LEARNER'), findsNothing);
    expect(find.byIcon(BootstrapIcons.book_half), findsOneWidget, reason: 'logo giống website');
    // Chờ hết hẹn giờ chuyển trang của Splash
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
