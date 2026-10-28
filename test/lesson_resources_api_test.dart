import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/lesson_resources_repository.dart';
import 'api_learning_contract_test.dart' show Transport;

class BinaryTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    expect(options.headers['Authorization'], 'Bearer test-token');
    expect(options.path, '/documents/doc1/download');
    expect(options.followRedirects, false);
    return ResponseBody.fromBytes(
      [37, 80, 68, 70],
      200,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('notes CRUD and documents follow week 11 API contract', () async {
    final transport = Transport();
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..httpClientAdapter = transport;
    final repo = LessonResourcesRepository(
      client: ApiClient(dio: dio, tokenProvider: () => 'token'),
    );
    final note = {'id': 12, 'positionSeconds': 75, 'content': 'MVC'};
    transport.data = {
      'items': [note],
      'total': 1,
    };
    expect((await repo.notes('c', 'l')).single['id'], 12);
    expect(transport.calls.last.path, '/learning/c/lessons/l/notes');
    expect(transport.calls.last.headers['Authorization'], 'Bearer token');
    transport.data = note;
    await repo.saveNote('c', 'l', 'MVC', 75);
    expect(transport.calls.last.method, 'POST');
    expect(transport.calls.last.data, {
      'content': 'MVC',
      'positionSeconds': 75,
    });
    await repo.saveNote('c', 'l', 'Edit', 80, id: 12);
    expect(transport.calls.last.path, '/notes/12');
    expect(transport.calls.last.method, 'PUT');
    await repo.deleteNote(12);
    expect(transport.calls.last.method, 'DELETE');
    transport.data = {
      'items': [
        {'id': 'doc1', 'isAvailable': false},
      ],
    };
    expect((await repo.documents('c', 'l')).single['isAvailable'], false);
    expect(transport.calls.last.path, '/learning/c/lessons/l/documents');
    transport.status = 503;
    transport.raw = {
      'success': false,
      'code': 'NOTES_NOT_INSTALLED',
      'message': 'Chưa cài đặt ghi chú',
    };
    await expectLater(
      repo.notes('c', 'l'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'NOTES_NOT_INSTALLED',
        ),
      ),
    );
  });
  test('document binary download carries token and preserves bytes', () async {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..httpClientAdapter = BinaryTransport();
    final api = ApiClient(dio: dio, tokenProvider: () => 'test-token');
    expect(await api.downloadDocument('doc1'), [37, 80, 68, 70]);
  });
  test('binary download decodes JSON 401 and expires the session', () async {
    final transport = Transport()
      ..status = 401
      ..raw = {
        'success': false,
        'code': 'UNAUTHORIZED',
        'message': 'Đăng nhập lại',
      };
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
      ..httpClientAdapter = transport;
    var expired = false;
    final api = ApiClient(dio: dio, tokenProvider: () => 'token')
      ..onUnauthorized = () => expired = true;
    await expectLater(
      api.downloadDocument('doc1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Đăng nhập lại',
        ),
      ),
    );
    expect(expired, true);
  });
}
