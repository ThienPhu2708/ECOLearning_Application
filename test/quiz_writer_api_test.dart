import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/core/config/api_config.dart';
import 'package:ecolearning_app/core/network/api_client.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'api_learning_contract_test.dart' show Transport;

void main() {
  test(
    'quiz writer token is sent on saves and submit, takeover is explicit',
    () async {
      final transport = Transport()
        ..data = {'attemptId': 42, 'writerToken': 'first'};
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = transport;
      final repo = QuizRepository(
        client: ApiClient(dio: dio, tokenProvider: () => 'token'),
      );
      await repo.start('c');
      final first = Map<String, dynamic>.from(transport.calls.last.data as Map);
      expect(first['takeover'], false);
      expect(first['clientKey'], matches(RegExp(r'^[a-f0-9]{32}$')));
      transport.data = {'saved': true};
      await repo.saveDraft(42, [1, -1]);
      expect(transport.calls.last.data, {
        'answers': [1, -1],
        'writerToken': 'first',
      });
      transport.data = {'attemptId': 42, 'writerToken': 'second'};
      await repo.takeOver('c');
      expect((transport.calls.last.data as Map)['takeover'], true);
      expect(
        (transport.calls.last.data as Map)['clientKey'],
        first['clientKey'],
      );
      transport.data = {'score': 10};
      await repo.submit(42, [1, 2]);
      expect((transport.calls.last.data as Map)['writerToken'], 'second');
    },
  );
}
