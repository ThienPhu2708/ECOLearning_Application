import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/certificates_screen.dart';
import 'fixtures/learning_preview_app.dart';

void main() {
  testWidgets(
    'profile stats select the correct existing course tab and open certificates',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
      await tester.pumpWidget(const LearningPreviewApp());
      await tester.pumpAndSettle();
      for (final entry in [
        ('Hoàn thành', 1),
        ('Đang học', 0),
        ('Hoàn thành', 1),
      ]) {
        await tester.tap(find.text('Hồ sơ').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(entry.$1));
        await tester.tap(find.text(entry.$1));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TabBar>(find.byType(TabBar)).controller!.index,
          entry.$2,
        );
        expect(find.text('Khóa học của tôi'), findsOneWidget);
      }
      await tester.tap(find.text('Hồ sơ').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chứng chỉ'));
      await tester.pumpAndSettle();
      expect(find.byType(CertificatesScreen), findsOneWidget);
      expect(find.text('Chưa có chứng chỉ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
