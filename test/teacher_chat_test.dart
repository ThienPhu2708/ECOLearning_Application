import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/teacher_chat_repository.dart';
import 'package:ecolearning_app/presentation/screens/messages/conversation_screen.dart';

const room = TeacherConversation(
  id: 4,
  courseId: 'KH1',
  courseName: 'Khóa học C#',
  participantName: 'Cô An',
);
Map<String, dynamic> messageJson(int id) => {
  'id': id,
  'content': 'Câu hỏi $id',
  'isMine': true,
  'canRecall': true,
  'recallSeconds': 120,
  'sentAt': '2026-11-04T09:00:00+07:00',
};
Map<String, dynamic> roomJson() => {
  'id': 4,
  'courseId': 'KH1',
  'courseName': 'Khóa học C#',
  'participant': {'fullName': 'Cô An'},
  'status': 'Mo',
  'unreadCount': 2,
};

class ChatTransport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Object? payload;
  bool media = false;
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    await body?.drain<void>();
    calls.add(options);
    if (media) {
      return ResponseBody.fromBytes(
        [1, 2, 3],
        status,
        headers: {
          'content-type': ['image/jpeg'],
          'location': ['https://example.invalid/image'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': payload}),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class ChatFixture extends TeacherChatRepository {
  ChatFixture({this.conversation = room});
  final TeacherConversation conversation;
  bool failSend = false;
  int reads = 0, sends = 0;
  final rows = <TeacherChatMessage>[];
  @override
  Future<TeacherChatPage> messages(int id, {int? beforeId}) async =>
      TeacherChatPage(conversation, List.of(rows));
  @override
  Future<void> markRead(int id) async {
    reads++;
  }

  @override
  Future<TeacherChatSendResult> send(int id, String content) async {
    sends++;
    if (failSend) throw const ApiException(message: 'Mạng gián đoạn');
    final message = TeacherChatMessage(
      id: 9,
      content: content,
      isMine: true,
      recallDeadline: DateTime.now(),
    );
    rows.add(message);
    return TeacherChatSendResult(message, false);
  }
}

void main() {
  test(
    'mixed teaching and learning conversations use each participant role',
    () async {
      final transport = ChatTransport();
      final repository = TeacherChatRepository(
        client: ApiClient(
          dio: Dio(
            BaseOptions(baseUrl: 'https://ecolearning.runasp.net/api/v1'),
          )..httpClientAdapter = transport,
          tokenProvider: () => 'teacher-account-token',
        ),
      );
      final learningRoom = roomJson()
        ..['participant'] = {'fullName': 'Cô An', 'role': 'GiaoVien'};
      final teachingRoom = roomJson()
        ..['id'] = 5
        ..['participant'] = {'fullName': 'Bạn Bình', 'role': 'HocVien'};
      transport.payload = [learningRoom, teachingRoom];
      final conversations = await repository.conversations();
      expect(conversations.map((room) => room.participantRoleLabel), [
        'Giáo viên',
        'Học viên',
      ]);
      transport.payload = learningRoom;
      expect((await repository.open('KH1')).participantRoleLabel, 'Giáo viên');
      expect(transport.calls.last.path, '/chat/courses/KH1/conversation');
      expect(TeacherConversation.fromJson(roomJson()).participantRoleLabel, '');
    },
  );
  test('chat API contract, auth header and cursor pagination', () async {
    final transport = ChatTransport();
    final api = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://ecolearning.runasp.net/api/v1'))
        ..httpClientAdapter = transport,
      tokenProvider: () => 'test-token',
    );
    final repository = TeacherChatRepository(client: api);
    transport.payload = [roomJson()];
    expect(
      (await repository.conversations(
        courseId: 'KH1',
        unreadOnly: true,
      )).single.unreadCount,
      2,
    );
    expect(
      transport.calls.last.queryParameters,
      containsPair('status', 'unread'),
    );
    transport.payload = roomJson();
    expect((await repository.open('KH1')).id, 4);
    expect(transport.calls.last.method, 'POST');
    transport.payload = {
      'conversation': roomJson(),
      'items': [messageJson(3)],
    };
    expect((await repository.messages(4, beforeId: 10)).messages.single.id, 3);
    expect(transport.calls.last.queryParameters['beforeId'], 10);
    transport.payload = {
      'message': messageJson(5),
      'externalPaymentWarning': true,
    };
    expect(
      (await repository.send(4, '  Chào cô  ')).externalPaymentWarning,
      isTrue,
    );
    expect(transport.calls.last.data, {'content': 'Chào cô'});
    await repository.markRead(4);
    expect(transport.calls.last.path, '/chat/conversations/4/read');
    await repository.recall(4, 5);
    expect(
      transport.calls.last.path,
      '/chat/conversations/4/messages/5/recall',
    );
    await repository.report(4, ' Lý do ');
    expect(transport.calls.last.data, {'reason': 'Lý do'});
    transport.payload = {'count': 7};
    expect(await repository.unreadCount(), 7);
    for (final call in transport.calls) {
      expect(call.headers['Authorization'], 'Bearer test-token');
    }
  });
  test('private media uses authenticated API and rejects redirects', () async {
    final transport = ChatTransport()..media = true;
    final api = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://ecolearning.runasp.net/api/v1'))
        ..httpClientAdapter = transport,
      tokenProvider: () => 'private-token',
    );
    final repository = TeacherChatRepository(client: api);
    expect(await repository.image(5), [1, 2, 3]);
    expect(transport.calls.last.path, '/chat/messages/5/image');
    expect(transport.calls.last.followRedirects, isFalse);
    expect(
      transport.calls.last.headers['Authorization'],
      'Bearer private-token',
    );
    transport.status = 302;
    await expectLater(repository.image(5), throwsA(isA<ApiException>()));
  });
  test('image upload uses the multipart field expected by chat API', () async {
    final directory = await Directory.systemTemp.createTemp('eco-chat-test-');
    final file = File('${directory.path}/fixture.jpg');
    try {
      await file.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
      final transport = ChatTransport()
        ..payload = {
          'message': {
            ...messageJson(8),
            'imageUrl': '/api/v1/chat/messages/8/image',
          },
        };
      final api = ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://ecolearning.runasp.net/api/v1'))
          ..httpClientAdapter = transport,
        tokenProvider: () => 'test-token',
      );
      final sent = await TeacherChatRepository(
        client: api,
      ).sendImage(4, file.path);
      expect(sent.message.imageUrl, isNotNull);
      final request = transport.calls.single;
      expect(request.path, '/chat/conversations/4/image');
      expect((request.data as FormData).files.single.key, 'image');
      expect(
        (request.data as FormData).files.single.value.contentType.toString(),
        'image/jpeg',
      );
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
      await directory.delete();
    }
  });
  test('recall availability respects server ownership and expiration', () {
    expect(TeacherChatMessage.fromJson(messageJson(1)).recallAvailable, isTrue);
    expect(
      TeacherChatMessage.fromJson({
        ...messageJson(1),
        'isMine': false,
      }).recallAvailable,
      isFalse,
    );
    expect(
      TeacherChatMessage.fromJson({
        ...messageJson(1),
        'recalled': true,
      }).recallAvailable,
      isFalse,
    );
    expect(
      TeacherChatMessage.fromJson({
        ...messageJson(1),
        'recallSeconds': 0,
      }).recallAvailable,
      isFalse,
    );
  });
  testWidgets('failed send preserves draft; successful retry updates thread', (
    tester,
  ) async {
    final repository = ChatFixture()..failSend = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(conversation: room, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.reads, 1);
    await tester.enterText(find.byType(TextField), 'Cô giải thích giúp em');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(find.text('Mạng gián đoạn'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Cô giải thích giúp em',
    );
    repository.failSend = false;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(repository.sends, 2);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Cô giải thích giúp em'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('composer fits narrow screens with keyboard', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(conversation: room, repository: ChatFixture()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('read-only conversation cannot send new messages', (
    tester,
  ) async {
    const closed = TeacherConversation(
      id: 4,
      courseId: 'KH1',
      courseName: 'Khóa học C#',
      participantName: 'Cô An',
      status: 'ChiDoc',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          conversation: closed,
          repository: ChatFixture(conversation: closed),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Hội thoại hiện chỉ cho phép xem.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
