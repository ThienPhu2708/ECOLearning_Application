import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/core/storage/token_storage.dart';
import 'package:ecolearning_app/data/models/auth_session.dart';
import 'package:ecolearning_app/data/repositories/auth_repository.dart';
import 'package:ecolearning_app/data/repositories/profile_repository.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/presentation/providers/auth_provider.dart';
import 'package:ecolearning_app/presentation/screens/auth/login_screen.dart';

class SessionTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool rejectLogin = false;
  final user = {
    'id': 'learner-42',
    'fullName': 'Học viên API',
    'email': 'learner@example.com',
    'certificateCount': 2,
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final path = options.path;
    final denied = path == '/auth/login' && rejectLogin;
    final Object? data = switch (path) {
      '/auth/login' => {
        'token': 'integration-session',
        'expiresAt': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'user': user,
      },
      '/me' => user,
      '/certificates' => [
        {'code': 'CERT-42', 'courseId': 'COURSE-42'},
      ],
      _ => null,
    };
    return ResponseBody.fromString(
      jsonEncode(
        denied
            ? {
                'success': false,
                'message': 'Email hoặc mật khẩu không đúng.',
                'code': 'INVALID_CREDENTIALS',
              }
            : {'success': true, 'data': data},
      ),
      denied ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class DeniedLogin extends AuthRepository {
  @override
  Future<AuthSession> login(String email, String password) async =>
      throw const ApiException(message: 'Email hoặc mật khẩu không đúng.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage.instance.clear();
  });
  tearDown(() => TokenStorage.instance.clear());

  test(
    'login session authorizes learning APIs, restores after restart, and clears on logout',
    () async {
      final transport = SessionTransport();
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = transport;
      final api = ApiClient(dio: dio);
      AuthProvider makeAuth() => AuthProvider(
        authRepository: AuthRepository(client: api),
        profileRepository: ProfileRepository(client: api),
      );
      final auth = makeAuth();
      await auth.login(' learner@example.com ', 'test-password');
      expect(auth.isLoggedIn, isTrue);
      expect(auth.user?.id, 'learner-42');
      expect(transport.calls.first.data['email'], 'learner@example.com');
      final certificates = await QuizRepository(client: api).certificates();
      expect(certificates.single['code'], 'CERT-42');
      expect(
        transport.calls.last.headers['Authorization'],
        'Bearer integration-session',
      );
      await TokenStorage.instance.load();
      final restored = makeAuth();
      expect(await restored.restoreSession(), isTrue);
      expect(restored.user?.certificateCount, 2);
      var cleared = false;
      restored.onSessionCleared = () async {
        cleared = true;
      };
      await restored.logout();
      expect(restored.isLoggedIn, isFalse);
      expect(restored.user, isNull);
      expect(cleared, isTrue);
      auth.dispose();
      restored.dispose();
    },
  );

  test('failed login never creates a session', () async {
    final transport = SessionTransport()..rejectLogin = true;
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..httpClientAdapter = transport;
    final auth = AuthProvider(
      authRepository: AuthRepository(client: ApiClient(dio: dio)),
    );
    await expectLater(
      auth.login('learner@example.com', 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.isLoggedIn, isFalse);
    expect(auth.user, isNull);
    auth.dispose();
  });

  testWidgets(
    'login screen validates empty inputs and displays API rejection without leaving',
    (tester) async {
      final auth = AuthProvider(authRepository: DeniedLogin());
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.ensureVisible(find.text('Đăng nhập'));
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'learner@example.com',
      );
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.ensureVisible(find.text('Đăng nhập'));
      await tester.tap(find.text('Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.isLoggedIn, isFalse);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
