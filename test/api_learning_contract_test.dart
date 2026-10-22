import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/data/repositories/profile_repository.dart';
import 'package:ecolearning_app/data/repositories/favorite_repository.dart';
import 'package:ecolearning_app/data/repositories/order_repository.dart';

class Transport implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Object? data;
  int status = 200;
  Map<String, dynamic>? raw;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    calls.add(options);
    expect(options.uri.host, 'ecolearning.runasp.net');
    expect(options.uri.path, startsWith('/api/v1/'));
    return ResponseBody.fromString(
      jsonEncode(raw ?? {'success': true, 'data': data}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Transport transport;
  late ApiClient api;
  String? token;
  setUp(() {
    transport = Transport();
    token = 'test-session';
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    dio.httpClientAdapter = transport;
    api = ApiClient(dio: dio, tokenProvider: () => token);
  });
  Map<String, dynamic> page(List<Map<String, dynamic>> items) => {
    'items': items,
    'page': 2,
    'pageSize': 12,
    'total': 13,
    'totalPages': 2,
  };
  test(
    'owned courses send paging/status with current shared session and parse certificate/review flags',
    () async {
      transport.data = page([
        {
          'id': 'DMKH01',
          'title': 'C#',
          'progress': 100,
          'hasCertificate': true,
          'lastLessonId': 'BH1',
          'myReview': {'rating': 4},
        },
      ]);
      final owned = await LearningRepository(
        client: api,
      ).myCourses(status: MyCourseStatus.completed, page: 2);
      expect(transport.calls.last.queryParameters, {
        'status': 'completed',
        'page': 2,
      });
      expect(
        transport.calls.last.headers['Authorization'],
        'Bearer test-session',
      );
      expect(owned.items.single.hasCertificate, true);
      expect(owned.items.single.myReviewRating, 4);
      token = 'new-session';
      await LearningRepository(client: api).myCourses();
      expect(
        transport.calls.last.headers['Authorization'],
        'Bearer new-session',
      );
    },
  );
  test(
    'learning resumes server lesson, parses eligibility and posts progress against correct lesson',
    () async {
      final repo = LearningRepository(client: api);
      transport.data = {
        'courseId': 'DMKH01',
        'title': 'C#',
        'progress': 100,
        'currentLessonId': 'BH1',
        'chapters': [
          {
            'id': 'chapter',
            'title': 'Chương 1',
            'lessons': [
              {'id': 'BH1', 'durationSeconds': 600, 'isCompleted': true},
            ],
          },
        ],
        'quiz': {'available': true, 'passed': true},
        'certificate': {'issued': true},
        'canReview': true,
      };
      final overview = await repo.overview('DMKH01');
      expect(overview.currentLessonId, 'BH1');
      expect(
        overview.canReview && overview.quizPassed && overview.certificateIssued,
        true,
      );
      transport.data = {
        'id': 'BH1',
        'videoUrl': '/Uploads/video.mp4',
        'lastPositionSeconds': 150,
        'durationSeconds': 600,
      };
      final lesson = await repo.lesson('DMKH01', 'BH1');
      expect(
        lesson.videoUrl,
        'https://ecolearning.runasp.net/Uploads/video.mp4',
      );
      expect(lesson.lastPositionSeconds, 150);
      transport.data = {'lessonCompleted': true, 'courseProgress': 100};
      await repo.saveProgress(
        'DMKH01',
        'BH1',
        positionSeconds: 480,
        durationSeconds: 600,
      );
      expect(transport.calls.last.method, 'POST');
      expect(transport.calls.last.data, {
        'positionSeconds': 480,
        'durationSeconds': 600,
      });
      expect(
        transport.calls.last.uri.path,
        '/api/v1/learning/DMKH01/lessons/BH1/progress',
      );
    },
  );
  test(
    'quiz draft/submit and certificate endpoints follow Postman contract',
    () async {
      final repo = QuizRepository(client: api);
      transport.data = {'saved': true};
      expect(await repo.saveDraft(45, [0, -1, 2]), true);
      expect(transport.calls.last.method, 'PUT');
      expect(transport.calls.last.data, {
        'answers': [0, -1, 2],
      });
      transport.data = {'score': 8, 'passed': true};
      expect((await repo.submit(45, [0, 1]))['passed'], true);
      expect(transport.calls.last.uri.path, '/api/v1/quiz-attempts/45/submit');
      transport.data = {'code': 'CERT-X'};
      await repo.claimCertificate('DMKH01');
      expect(
        transport.calls.last.uri.path,
        '/api/v1/courses/DMKH01/certificate',
      );
      expect(transport.calls.last.method, 'POST');
      await repo.certificate('DMKH01');
      expect(transport.calls.last.method, 'GET');
      expect(transport.calls.last.uri.path, '/api/v1/certificates/DMKH01');
      transport.data = [
        {'code': 'CERT-X'},
      ];
      expect((await repo.certificates()).length, 1);
    },
  );
  test(
    'profile updates and avatar use authenticated API without mock state',
    () async {
      final repo = ProfileRepository(client: api);
      transport.data = {
        'id': '42',
        'fullName': 'Tên từ API',
        'email': 'test@example.com',
        'avatarUrl': '/Uploads/avatar.png',
        'completedCount': 7,
        'inProgressCount': 3,
      };
      final user = await repo.me();
      expect(user.fullName, 'Tên từ API');
      expect(user.completedCoursesCount, 7);
      expect(
        user.avatarUrl,
        'https://ecolearning.runasp.net/Uploads/avatar.png',
      );
      await repo.updateMe(
        fullName: ' Tên mới ',
        phone: '0987654321',
        gender: 'Nữ',
        birthDate: DateTime(2004, 5, 6),
      );
      expect(transport.calls.last.method, 'PUT');
      expect((transport.calls.last.data as Map)['birthDate'], '2004-05-06');
      expect((transport.calls.last.data as Map)['fullName'], 'Tên mới');
      transport.data = {};
      await repo.changePassword(
        currentPassword: 'old password',
        newPassword: 'new password',
      );
      expect(transport.calls.last.uri.path, '/api/v1/me/change-password');
      final dir = await Directory.systemTemp.createTemp('avatar-contract-');
      final image = File('${dir.path}/avatar.png');
      await image.writeAsBytes([137, 80, 78, 71]);
      try {
        transport.data = {'avatarUrl': '/Uploads/new.png'};
        expect(
          await repo.uploadAvatar(image.path),
          'https://ecolearning.runasp.net/Uploads/new.png',
        );
        final form = transport.calls.last.data as FormData;
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.contentType.toString(), 'image/png');
      } finally {
        await image.delete();
        await dir.delete();
      }
    },
  );
  test('favorites and order history read server paging and status', () async {
    transport.data = page([
      {'id': 'DMKH01', 'title': 'C#'},
    ]);
    expect((await FavoriteRepository(client: api).list(page: 2)).total, 13);
    transport.data = {'isFavorite': false};
    expect(await FavoriteRepository(client: api).toggle('DMKH01'), false);
    transport.data = page([
      {'orderId': 'ORDER1', 'status': 'paid', 'total': 499000},
    ]);
    final orders = await OrderRepository(client: api).orders(page: 2);
    expect(orders.items.single['status'], 'paid');
    expect(transport.calls.last.uri.path, '/api/v1/orders');
  });
  test(
    'API field errors are preserved, denied requests never become fake success',
    () async {
      transport.raw = {
        'success': false,
        'message': 'Dữ liệu chưa hợp lệ',
        'errors': {
          'fullName': ['Vui lòng nhập họ tên.'],
        },
      };
      await expectLater(
        api.put('/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errors['fullName'],
            'field error',
            'Vui lòng nhập họ tên.',
          ),
        ),
      );
      int expired = 0;
      api.onUnauthorized = () => expired++;
      transport.status = 401;
      transport.raw = {
        'success': false,
        'code': 'UNAUTHORIZED',
        'message': 'Phiên hết hạn',
      };
      await expectLater(
        api.get('/me'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'unauthorized',
            true,
          ),
        ),
      );
      expect(expired, 1);
      token = null;
      await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
      expect(expired, 1);
    },
  );
}
