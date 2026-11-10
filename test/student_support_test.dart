import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/user.dart';
import 'package:ecolearning_app/data/repositories/chatbot_repository.dart';
import 'package:ecolearning_app/data/repositories/review_repository.dart';
import 'package:ecolearning_app/data/repositories/support_repository.dart';
import 'package:ecolearning_app/presentation/screens/chatbot/chatbot_screen.dart';
import 'package:ecolearning_app/presentation/screens/learning/report_violation_sheet.dart';
import 'package:ecolearning_app/presentation/screens/profile/contact_screen.dart';
import 'package:ecolearning_app/presentation/widgets/chatbot_bubble.dart';
import 'package:ecolearning_app/presentation/widgets/review_helpful_bar.dart';
import 'api_learning_contract_test.dart' show Transport;

// ---------------------------------------------------------------- repository giả cho widget test

class FakeReviews extends ReviewRepository {
  final calls = <(String, bool)>[];
  Map<String, dynamic> result = const {};
  ApiException? error;
  @override
  Future<Map<String, dynamic>> vote(String reviewId, {required bool helpful}) async {
    calls.add((reviewId, helpful));
    if (error != null) throw error!;
    return result;
  }
}

class FakeSupport extends SupportRepository {
  final reports = <Map<String, Object?>>[];
  final contacts = <Map<String, Object?>>[];
  ApiException? error;
  @override
  Future<List<String>> violationTypes() async => ['Nội dung không phù hợp', 'Khác'];
  @override
  Future<void> reportCourse(String courseId, {required String type, required String description, String? lessonId}) async {
    if (error != null) throw error!;
    reports.add({'courseId': courseId, 'type': type, 'description': description, 'lessonId': lessonId});
  }

  @override
  Future<void> contact({String? fullName, String? email, String? subject, required String content}) async {
    if (error != null) throw error!;
    contacts.add({'fullName': fullName, 'email': email, 'subject': subject, 'content': content});
  }
}

class FakeChatbot extends ChatbotRepository {
  List<ChatMessage> saved = [];
  ApiException? historyError;
  ApiException? askError;
  int clears = 0;
  final questions = <String>[];
  @override
  Future<List<ChatMessage>> history() async {
    if (historyError != null) throw historyError!;
    return saved;
  }

  @override
  Future<ChatMessage> ask(String question) async {
    questions.add(question);
    if (askError != null) throw askError!;
    return ChatMessage(
      fromUser: false,
      content: '**Gợi ý** cho bạn:\n* Python cơ bản - 299.000đ',
      courses: [Course.fromJson({'id': 'PY01', 'title': 'Python cơ bản', 'price': 299000})],
    );
  }

  @override
  Future<void> clearHistory() async => clears++;
}

class ThrowingChatbot extends FakeChatbot {
  @override
  Future<ChatMessage> ask(String question) async => throw const FormatException('bad json');
}

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  // ---------------------------------------------------------------- hợp đồng API (đường dẫn, body)
  group('API contract', () {
    late Transport transport;
    late ApiClient api;
    setUp(() {
      transport = Transport();
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))..httpClientAdapter = transport;
      api = ApiClient(dio: dio, tokenProvider: () => 'token');
      ChatbotRepository.resetAvailability();
    });

    test('E2 vote posts helpful flag to review', () async {
      transport.data = {'reviewId': 'DG1', 'helpfulCount': 3, 'notHelpfulCount': 1, 'myVote': true};
      final data = await ReviewRepository(client: api).vote('DG1', helpful: true);
      expect(transport.calls.last.method, 'POST');
      expect(transport.calls.last.path, '/reviews/DG1/helpful');
      expect(transport.calls.last.data, {'helpful': true});
      expect(data['helpfulCount'], 3);
    });

    test('J1–J3 support endpoints', () async {
      final repo = SupportRepository(client: api);
      transport.data = ['Nội dung không phù hợp', 'Khác'];
      expect(await repo.violationTypes(), ['Nội dung không phù hợp', 'Khác']);
      expect(transport.calls.last.path, '/violation-types');

      transport.data = null;
      await repo.reportCourse('C1', type: 'Khác', description: '  Video lỗi tiếng  ', lessonId: 'L2');
      expect(transport.calls.last.path, '/courses/C1/reports');
      expect(transport.calls.last.data, {'type': 'Khác', 'description': 'Video lỗi tiếng', 'lessonId': 'L2'});
      await repo.reportCourse('C1', type: 'Khác', description: 'Cả khóa có vấn đề');
      expect((transport.calls.last.data as Map).containsKey('lessonId'), isFalse);

      await repo.contact(fullName: ' ', email: '', subject: null, content: ' Xin chào ');
      expect(transport.calls.last.path, '/contact');
      expect(transport.calls.last.data, {'content': 'Xin chào'});
      await repo.contact(fullName: 'An', email: 'an@x.vn', subject: 'Hỏi', content: 'Nội dung');
      expect(transport.calls.last.data, {'fullName': 'An', 'email': 'an@x.vn', 'subject': 'Hỏi', 'content': 'Nội dung'});

      transport.status = 409;
      transport.raw = {'success': false, 'code': 'REPORT_PENDING', 'message': 'Đang chờ xử lý'};
      await expectLater(
        repo.reportCourse('C1', type: 'Khác', description: 'Mô tả đủ dài'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'REPORT_PENDING')),
      );
    });

    test('K1–K3 chatbot endpoints map reply, courses and history', () async {
      final repo = ChatbotRepository(client: api);
      transport.data = {
        'reply': 'Bạn thử khóa này nhé',
        'courses': [
          {'id': 'PY01', 'title': 'Python', 'thumbnail': 'https://cdn/x.jpg', 'price': 299000, 'rating': 4.5, 'reviewCount': 8},
        ],
      };
      final reply = await repo.ask('  Python?  ');
      expect(transport.calls.last.path, '/chatbot/ask');
      expect(transport.calls.last.data, {'question': 'Python?'});
      expect(reply.fromUser, isFalse);
      expect(reply.courses.single.id, 'PY01');
      expect(reply.courses.single.imageUrl, 'https://cdn/x.jpg');
      expect(reply.courses.single.price, 299000);

      transport.data = {
        'messages': [
          {'role': 'user', 'content': 'Hỏi'},
          {'role': 'model', 'content': 'Đáp'},
        ],
      };
      final history = await repo.history();
      expect(history.map((m) => m.fromUser), [true, false]);
      expect(history.last.content, 'Đáp');

      await repo.clearHistory();
      expect(transport.calls.last.method, 'DELETE');
      expect(transport.calls.last.path, '/chatbot/history');
    });

    test('isAvailable remembers a disabled chatbot', () async {
      final repo = ChatbotRepository(client: api);
      transport.status = 404;
      transport.raw = {'success': false, 'code': 'CHATBOT_DISABLED', 'message': 'Tắt'};
      expect(await repo.isAvailable(), isFalse);
      transport.status = 200;
      transport.raw = null;
      transport.data = {'messages': []};
      final before = transport.calls.length;
      expect(await repo.isAvailable(), isFalse, reason: 'kết quả 404 được nhớ trong phiên');
      expect(transport.calls.length, before);

      ChatbotRepository.resetAvailability();
      expect(await repo.isAvailable(), isTrue);
    });

    test('isAvailable retries after a server error', () async {
      final repo = ChatbotRepository(client: api);
      transport.status = 500;
      transport.raw = {'success': false, 'code': 'SERVER_ERROR', 'message': 'Lỗi'};
      expect(await repo.isAvailable(), isFalse);
      transport.status = 200;
      transport.raw = null;
      transport.data = {'messages': []};
      expect(await repo.isAvailable(), isTrue);
    });
  });

  // ---------------------------------------------------------------- B1 đánh giá hữu ích
  group('ReviewHelpfulBar', () {
    final review = {'id': 'DG1', 'helpfulCount': 2, 'notHelpfulCount': 0, 'myVote': null, 'isMine': false};

    testWidgets('guest is asked to sign in and nothing is sent', (tester) async {
      final repo = FakeReviews();
      await tester.pumpWidget(host(ReviewHelpfulBar(review: review, repository: repo, isLoggedIn: () => false)));
      await tester.tap(find.byTooltip('Hữu ích'));
      await tester.pump();
      expect(find.text('Vui lòng đăng nhập để bình chọn đánh giá.'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('vote updates counts from the server and can be undone', (tester) async {
      final repo = FakeReviews()..result = {'helpfulCount': 3, 'notHelpfulCount': 0, 'myVote': true};
      await tester.pumpWidget(host(ReviewHelpfulBar(review: review, repository: repo, isLoggedIn: () => true)));
      expect(find.text('Bạn thấy hữu ích?'), findsOneWidget);
      await tester.tap(find.byTooltip('Hữu ích'));
      await tester.pump();
      expect(repo.calls.single, ('DG1', true));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Cảm ơn bạn đã bình chọn'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);

      repo.result = {'helpfulCount': 2, 'notHelpfulCount': 0, 'myVote': null};
      await tester.tap(find.byTooltip('Hữu ích'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Bạn thấy hữu ích?'), findsOneWidget);
    });

    testWidgets('own review only shows counts', (tester) async {
      final repo = FakeReviews();
      await tester.pumpWidget(host(ReviewHelpfulBar(review: {...review, 'isMine': true}, repository: repo, isLoggedIn: () => true)));
      expect(find.text('Đánh giá của bạn'), findsOneWidget);
      await tester.tap(find.byTooltip('Không hữu ích'));
      await tester.pump();
      expect(repo.calls, isEmpty);
    });

    testWidgets('server error is shown and counts stay', (tester) async {
      final repo = FakeReviews()..error = const ApiException(statusCode: 403, code: 'OWN_REVIEW', message: 'Bạn không thể tự bình chọn đánh giá của mình.');
      await tester.pumpWidget(host(ReviewHelpfulBar(review: review, repository: repo, isLoggedIn: () => true)));
      await tester.tap(find.byTooltip('Không hữu ích'));
      await tester.pump();
      expect(find.text('Bạn không thể tự bình chọn đánh giá của mình.'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- B2 báo cáo vi phạm
  group('ReportViolationSheet', () {
    Future<void> open(WidgetTester tester, FakeSupport repo) async {
      await tester.pumpWidget(host(Builder(
        builder: (context) => TextButton(
          onPressed: () => showReportViolationSheet(context, courseId: 'C1', lessonId: 'L2', lessonTitle: 'Bài 2', repository: repo),
          child: const Text('Mở'),
        ),
      )));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
    }

    testWidgets('validates, then sends the report with the current lesson', (tester) async {
      final repo = FakeSupport();
      await open(tester, repo);
      expect(find.text('Nội dung không phù hợp'), findsOneWidget);
      expect(find.text('Liên quan đến bài: Bài 2'), findsOneWidget);

      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pump();
      expect(find.text('Vui lòng chọn loại vi phạm.'), findsOneWidget);
      expect(find.textContaining('tối thiểu 10 ký tự'), findsOneWidget);
      expect(repo.reports, isEmpty);

      await tester.tap(find.text('Khác'));
      await tester.enterText(find.byType(TextField), 'Video bị mất tiếng từ phút thứ 2');
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(repo.reports.single, {'courseId': 'C1', 'type': 'Khác', 'description': 'Video bị mất tiếng từ phút thứ 2', 'lessonId': 'L2'});
      expect(find.textContaining('Đã gửi báo cáo vi phạm'), findsOneWidget);
      expect(find.text('Gửi báo cáo'), findsNothing);
    });

    testWidgets('unchecking the lesson reports the whole course', (tester) async {
      final repo = FakeSupport();
      await open(tester, repo);
      await tester.tap(find.text('Liên quan đến bài: Bài 2'));
      await tester.tap(find.text('Khác'));
      await tester.enterText(find.byType(TextField), 'Cả khóa thiếu nội dung như mô tả');
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(repo.reports.single['lessonId'], isNull);
    });

    testWidgets('pending report error stays in the sheet', (tester) async {
      final repo = FakeSupport()
        ..error = const ApiException(statusCode: 409, code: 'REPORT_PENDING', message: 'Bạn đã có một báo cáo đang chờ xử lý cho khóa học này.');
      await open(tester, repo);
      await tester.tap(find.text('Khác'));
      await tester.enterText(find.byType(TextField), 'Video bị mất tiếng từ phút thứ 2');
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã có một báo cáo đang chờ xử lý cho khóa học này.'), findsOneWidget);
      expect(find.text('Gửi báo cáo'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- B3 Trợ lý Elearning (giao diện giống website)
  group('ChatbotScreen', () {
    testWidgets('new chat starts with the web greeting and the 4 web suggestions', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ChatbotScreen(repository: FakeChatbot(), isLoggedIn: () => true)));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý Elearning'), findsOneWidget);
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text(ChatbotScreen.greeting.replaceAll('**', '')), findsOneWidget);
      for (final s in ChatbotScreen.suggestions) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text(ChatbotScreen.footer), findsOneWidget);
      expect(find.byType(ChatbotRobot), findsWidgets);
    });

    testWidgets('shows saved history, then asks and opens a suggested course', (tester) async {
      final repo = FakeChatbot()
        ..saved = [
          const ChatMessage(fromUser: true, content: 'Câu cũ'),
          const ChatMessage(fromUser: false, content: 'Trả lời cũ'),
        ];
      Course? opened;
      await tester.pumpWidget(MaterialApp(
        home: ChatbotScreen(repository: repo, isLoggedIn: () => true, onOpenCourse: (_, c) => opened = c),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Câu cũ'), findsOneWidget);
      expect(find.text('Trả lời cũ'), findsOneWidget);
      expect(find.text(ChatbotScreen.greeting.replaceAll('**', '')), findsNothing, reason: 'có lịch sử thì không chào lại');
      expect(find.text(ChatbotScreen.suggestions.first), findsNothing, reason: 'gợi ý chỉ hiện khi bắt đầu cuộc trò chuyện');

      await tester.enterText(find.byType(TextField), 'Có khóa Python không?');
      await tester.tap(find.byTooltip('Gửi'));
      await tester.pumpAndSettle();
      expect(repo.questions.single, 'Có khóa Python không?');
      // Giống website: **...** in đậm, các ký tự khác giữ nguyên
      expect(find.text('Gợi ý cho bạn:\n* Python cơ bản - 299.000đ'), findsOneWidget);
      expect(find.text('299.000đ'), findsOneWidget, reason: 'giá trên thẻ khóa học');
      await tester.tap(find.text('Python cơ bản'));
      expect(opened?.id, 'PY01');
    });

    testWidgets('suggestion asks, errors are red, restart shows the greeting again', (tester) async {
      final repo = FakeChatbot()
        ..askError = const ApiException(statusCode: 503, code: 'CHATBOT_BUSY', message: 'Trợ lý đang bận, bạn thử lại sau ít giây nhé.');
      await tester.pumpWidget(MaterialApp(home: ChatbotScreen(repository: repo, isLoggedIn: () => true)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ChatbotScreen.suggestions[1]));
      await tester.pumpAndSettle();
      expect(repo.questions.single, ChatbotScreen.suggestions[1]);
      expect(find.text(ChatbotScreen.suggestions.first), findsNothing, reason: 'hỏi rồi thì ẩn gợi ý');
      final error = tester.widget<Text>(find.text('Trợ lý đang bận, bạn thử lại sau ít giây nhé.'));
      expect(error.style?.color, ChatbotColors.errorText);

      await tester.tap(find.byTooltip('Bắt đầu cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      expect(repo.clears, 1);
      expect(find.text('Trợ lý đang bận, bạn thử lại sau ít giây nhé.'), findsNothing);
      expect(find.text(ChatbotScreen.suggestions.first), findsOneWidget);
    });

    testWidgets('guest restart does not call the server; minimize closes the screen', (tester) async {
      final repo = FakeChatbot();
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatbotScreen(repository: repo, isLoggedIn: () => false))),
            child: const Text('Mở'),
          ),
        ),
      ));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Xin chào');
      await tester.tap(find.byTooltip('Gửi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bắt đầu cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      expect(repo.clears, 0);
      await tester.tap(find.byTooltip('Thu nhỏ'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatbotScreen), findsNothing);
    });

    testWidgets('unexpected failure shows the web connection error', (tester) async {
      final repo = ThrowingChatbot();
      await tester.pumpWidget(MaterialApp(home: ChatbotScreen(repository: repo, isLoggedIn: () => true)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Xin chào');
      await tester.tap(find.byTooltip('Gửi'));
      await tester.pumpAndSettle();
      expect(find.text('Không kết nối được máy chủ, bạn thử lại nhé.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled chatbot shows an empty state', (tester) async {
      final repo = FakeChatbot()
        ..historyError = const ApiException(statusCode: 404, code: 'CHATBOT_DISABLED', message: 'Tắt');
      await tester.pumpWidget(MaterialApp(home: ChatbotScreen(repository: repo, isLoggedIn: () => true)));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý Elearning chưa được bật'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('bubble shows teaser and unread badge like the web', (tester) async {
      var taps = 0;
      var dismissed = false;
      await tester.pumpWidget(host(Align(
        alignment: Alignment.bottomRight,
        child: ChatbotBubble(onPressed: () => taps++, unread: 1, showTeaser: true, onDismissTeaser: () => dismissed = true),
      )));
      expect(find.text('Xin chào! 👋\nMình là Trợ lý Elearning. Bạn cần tìm khóa học nào?'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byType(ChatbotRobot));
      expect(taps, 1);
      await tester.tap(find.byTooltip('Ẩn lời chào'));
      expect(dismissed, isTrue);

      await tester.pumpWidget(host(ChatbotBubble(onPressed: () {}, unread: 12)));
      expect(find.text('9+'), findsOneWidget);
      expect(find.textContaining('Xin chào'), findsNothing);
    });

    test('reply formatting, price and meta follow the web', () {
      final spans = replySpans('Khóa **Python** rất tốt\nGiá rẻ');
      expect(spans.map((s) => s.text), ['Khóa ', 'Python', ' rất tốt\nGiá rẻ']);
      expect(spans[1].style?.fontWeight, FontWeight.w700);
      expect(chatPrice(299000), '299.000đ');
      expect(chatPrice(0), 'Miễn phí');
      final c = Course.fromJson({'id': 'x', 'title': 't', 'instructor': 'Trần Khoa', 'rating': 4.5, 'reviewCount': 3});
      expect(courseMeta(c), 'Trần Khoa · ★ 4.5');
      expect(courseMeta(Course.fromJson({'id': 'y', 'instructor': 'Hà', 'rating': 5, 'reviewCount': 0})), 'Hà');
    });
  });

  // ---------------------------------------------------------------- B4 liên hệ
  group('ContactScreen', () {
    testWidgets('guest fills name, email and content', (tester) async {
      final repo = FakeSupport();
      await tester.pumpWidget(MaterialApp(home: ContactScreen(repository: repo)));
      await tester.ensureVisible(find.text('Gửi liên hệ'));
      await tester.tap(find.text('Gửi liên hệ'));
      await tester.pump();
      expect(find.text('Vui lòng nhập Họ và tên!'), findsOneWidget);
      expect(find.text('Email không được để trống!'), findsOneWidget);
      expect(find.text('Vui lòng nhập Nội dung liên hệ!'), findsOneWidget);
      expect(repo.contacts, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Họ và tên'), 'Nguyễn An');
      await tester.enterText(find.widgetWithText(TextField, 'Email nhận phản hồi'), 'an@x.vn');
      await tester.enterText(find.widgetWithText(TextField, 'Nội dung'), 'Cần hỗ trợ thanh toán');
      await tester.ensureVisible(find.text('Gửi liên hệ'));
      await tester.tap(find.text('Gửi liên hệ'));
      await tester.pumpAndSettle();
      expect(repo.contacts.single, {'fullName': 'Nguyễn An', 'email': 'an@x.vn', 'subject': '', 'content': 'Cần hỗ trợ thanh toán'});
    });

    testWidgets('signed-in user only writes the message; server field errors are shown', (tester) async {
      final user = User.fromJson({'id': '7', 'fullName': 'Bình Trần', 'email': 'binh@x.vn'});
      final repo = FakeSupport()
        ..error = const ApiException(statusCode: 400, code: 'INVALID_DATA', message: 'Nội dung tối đa 5000 ký tự!', errors: {'content': 'Nội dung tối đa 5000 ký tự!'});
      await tester.pumpWidget(MaterialApp(home: ContactScreen(repository: repo, user: user)));
      expect(find.text('Gửi từ tài khoản: Bình Trần (binh@x.vn)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Họ và tên'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'Nội dung'), 'Xin chào');
      await tester.ensureVisible(find.text('Gửi liên hệ'));
      await tester.tap(find.text('Gửi liên hệ'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung tối đa 5000 ký tự!'), findsOneWidget);

      repo.error = null;
      await tester.ensureVisible(find.text('Gửi liên hệ'));
      await tester.tap(find.text('Gửi liên hệ'));
      await tester.pumpAndSettle();
      expect(repo.contacts.single['fullName'], isNull);
      expect(repo.contacts.single['email'], isNull);
    });
  });
}
