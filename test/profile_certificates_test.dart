import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/presentation/screens/profile/profile_screen.dart';

class CertificatesRepository extends QuizRepository {
  List<Map<String, dynamic>> items = [];
  bool fail = false;
  @override
  Future<List<Map<String, dynamic>>> certificates() async {
    if (fail) throw Exception('Offline');
    return items;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
    'profile counts issued certificates and refreshes on tab return',
    (tester) async {
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exception is NetworkImageLoadException) return;
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
      final repo = CertificatesRepository();
      Future<void> show(bool active) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              repository: repo,
              isActive: active,
              user: MockData.currentUser,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Finder count(String value) => find.descendant(
        of: find
            .ancestor(of: find.text('Chứng chỉ'), matching: find.byType(Column))
            .first,
        matching: find.text(value),
      );
      await show(true);
      expect(count('0'), findsOneWidget);
      await show(false);
      repo.items = [
        {'code': 'CERT-1', 'courseTitle': 'C#'},
      ];
      await show(true);
      expect(count('1'), findsOneWidget);
      await tester.ensureVisible(find.text('Chứng chỉ của tôi'));
      await tester.tap(find.text('Chứng chỉ của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('CERT-1'), findsOneWidget);
      expect(find.text('Chưa có chứng chỉ'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await show(false);
      repo.fail = true;
      await show(true);
      expect(count('—'), findsOneWidget);
    },
  );
}
