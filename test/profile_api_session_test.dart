import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolearning_app/data/models/user.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/screens/profile/profile_screen.dart';
import 'package:ecolearning_app/presentation/widgets/custom_app_bar.dart';

class Certificates extends QuizRepository {
  @override
  Future<List<Map<String, dynamic>>> certificates() async => [];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'profile and greeting use shared authenticated user and server stats',
    (tester) async {
      final auth = AuthProvider();
      auth.updateUser(
        User(
          id: 'server-42',
          fullName: 'Người dùng API',
          email: 'test@example.com',
          avatarUrl: '',
          inProgressCoursesCount: 17,
          completedCoursesCount: 12,
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            home: Scaffold(
              appBar: const CustomAppBar(showAvatar: true, showCart: false),
              body: ProfileScreen(repository: Certificates()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Người dùng API'), findsOneWidget);
      expect(find.textContaining('Xin chào, Người dùng API'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      auth.updateUser(
        User(
          id: 'server-42',
          fullName: 'Tên vừa sửa',
          email: 'test@example.com',
          avatarUrl: '',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tên vừa sửa'), findsOneWidget);
      expect(find.textContaining('Xin chào, Tên vừa sửa'), findsOneWidget);
      expect(find.text('Người dùng API'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
