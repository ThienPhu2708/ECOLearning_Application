import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/preview_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'issued certificate, quiz result and owned-course flag survive restarting preview',
    () async {
      final first = PreviewQuizRepository(persistent: true);
      final started = await first.start('preview-csharp');
      await first.submit(
        started['attemptId'] as int,
        List.generate(10, (i) => i % 4),
      );
      final certificate = await first.claimCertificate('preview-csharp');
      final restarted = PreviewQuizRepository(persistent: true);
      expect((await restarted.certificates()).length, 1);
      expect(await restarted.certificate('preview-csharp'), certificate);
      expect(
        (await restarted.info('preview-csharp'))['lastResult']['passed'],
        true,
      );
      expect((await restarted.info('preview-csharp'))['canStart'], false);
      final learning = PreviewLearningRepository(quiz: restarted);
      expect(
        (await learning.myCourses(
          status: 'completed',
        )).items.single.hasCertificate,
        true,
      );
    },
  );
  test('a passing quiz without claiming never adds a certificate', () async {
    final first = PreviewQuizRepository(persistent: true);
    final started = await first.start('preview-csharp');
    await first.submit(
      started['attemptId'] as int,
      List.generate(10, (i) => i % 4),
    );
    expect(
      await PreviewQuizRepository(persistent: true).certificates(),
      isEmpty,
    );
  });
}
