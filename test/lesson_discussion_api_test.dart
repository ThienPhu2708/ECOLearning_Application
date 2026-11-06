import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/data/repositories/lesson_discussion_repository.dart';
import 'api_learning_contract_test.dart' show Transport;

void main() {
  test(
    'discussion requests preserve lesson, pagination, parent and bearer',
    () async {
      final transport = Transport();
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = transport;
      final repo = LessonDiscussionRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      transport.data = {
        'page': 2,
        'totalPages': 3,
        'totalComments': 5,
        'items': [
          {
            'id': 10,
            'authorName': 'Học viên',
            'replies': [
              {'id': 11},
            ],
          },
        ],
      };
      final result = await repo.list('course', 'lesson', page: 2);
      expect(result.totalComments, 5);
      expect(result.items.single.replies.single.id, 11);
      expect(
        transport.calls.last.path,
        '/learning/course/lessons/lesson/discussions',
      );
      expect(transport.calls.last.queryParameters['page'], 2);
      expect(transport.calls.last.headers['Authorization'], 'Bearer token');
      transport.data = {
        'page': 1,
        'totalPages': 1,
        'totalComments': 2,
        'items': [
          {
            'id': 12,
            'parentId': 10,
            'replyToAuthor': 'Học viên',
            'replyToContent': 'Câu hỏi',
            'isMine': true,
            'createdAt': '2026-11-06T05:02:00Z',
          },
        ],
      };
      final timeline = await repo.timeline('course', 'lesson');
      expect(
        transport.calls.last.path,
        '/learning/course/lessons/lesson/discussions/timeline',
      );
      expect(transport.calls.last.queryParameters['pageSize'], 30);
      expect(timeline.items.single.parentId, 10);
      expect(timeline.items.single.replyToAuthor, 'Học viên');
      expect(timeline.items.single.isMine, isTrue);
      expect(timeline.items.single.createdAt!.isUtc, isTrue);
      await repo.send('course', 'lesson', 'Xin chào', 10);
      expect(transport.calls.last.data, {
        'content': 'Xin chào',
        'parentId': 10,
      });
      await repo.toggle('course', 'lesson', 10);
      expect(
        transport.calls.last.path,
        '/learning/course/lessons/lesson/discussions/10/likes/toggle',
      );
    },
  );
}
