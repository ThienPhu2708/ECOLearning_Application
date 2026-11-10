import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/certificate_screen.dart';
import 'package:ecolearning_app/presentation/screens/my_courses/web_certificate_canvas.dart';

const sampleCertificate = <String, dynamic>{
  'code': 'CERT-SERVER-12345',
  'studentName': 'Phạm Ánh Ngọc',
  'courseTitle': 'Lập trình C# từ cơ bản đến nâng cao',
  'instructor': 'Trần Minh Khoa',
  'issuedAt': '2026-10-20T00:05:00+14:00',
  'durationSeconds': 21600,
};

class ExistingCertificateRepository extends QuizRepository {
  int reads = 0;
  int claims = 0;
  @override
  Future<Map<String, dynamic>> certificate(String courseId) async {
    reads++;
    return Map.of(certificateData);
  }

  static const certificateData = sampleCertificate;
  @override
  Future<Map<String, dynamic>> claimCertificate(String courseId) async {
    claims++;
    return Map.of(certificateData);
  }
}

class MissingCertificateRepository extends QuizRepository {
  @override
  Future<Map<String, dynamic>> certificate(String courseId) async {
    throw const ApiException(
      statusCode: 404,
      code: 'CERTIFICATE_NOT_FOUND',
      message: 'Bạn chưa có chứng chỉ của khóa học này.',
    );
  }
}

void main() {
  test('issued date uses the device time zone', () {
    final date = DateTime.parse(
      sampleCertificate['issuedAt'] as String,
    ).toLocal();
    expect(
      WebCertificateCanvas.issuedDate(sampleCertificate['issuedAt']),
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}',
    );
    expect(WebCertificateCanvas.issuedDate(null), '—');
  });
  testWidgets('a missing certificate shows eligibility guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CertificateScreen(
          courseId: 'course',
          quizAvailable: false,
          repository: MissingCertificateRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có chứng chỉ'), findsOneWidget);
    expect(find.byType(WebCertificateCanvas), findsNothing);
  });
  testWidgets(
    'certificate matches web title, indigo border, seal and both signatures',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: CertificateScreen(certificate: sampleCertificate),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CHỨNG NHẬN TỐT NGHIỆP'), findsOneWidget);
      expect(
        find.text('HỆ THỐNG ĐÀO TẠO TRỰC TUYẾN E-LEARNING'),
        findsOneWidget,
      );
      expect(find.text('PHẠM ÁNH NGỌC'), findsOneWidget);
      expect(find.text('E-Learning Board'), findsOneWidget);
      expect(find.text('Hội đồng Học thuật'), findsOneWidget);
      expect(find.text('Giảng viên phụ trách'), findsOneWidget);
      expect(find.text('★ VERIFIED ★'), findsOneWidget);
      expect(
        find.text(
          WebCertificateCanvas.issuedDate(sampleCertificate['issuedAt']),
        ),
        findsOneWidget,
      );
      expect(find.text('CHỨNG NHẬN HOÀN THÀNH'), findsNothing);
      final frames = tester.widgetList<Container>(find.byType(Container)).where(
        (c) {
          final d = c.decoration;
          return d is BoxDecoration &&
              d.border is Border &&
              (d.border as Border).top.color == const Color(0xFF1E1B4B);
        },
      );
      expect(frames, hasLength(1));
      expect(
        ((frames.single.decoration as BoxDecoration).border as Border)
            .top
            .width,
        12,
      );
      expect(
        tester.getCenter(find.text('Trần Minh Khoa').last).dx,
        lessThan(tester.getCenter(find.text('OFFICIAL')).dx),
      );
      expect(
        tester.getCenter(find.text('OFFICIAL')).dx,
        lessThan(tester.getCenter(find.text('Hội đồng Học thuật')).dx),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Phóng to chứng chỉ'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Phóng to chứng chỉ'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('CERT-SERVER-12345'), findsNothing);
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .maxScale,
        4,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'viewing an existing certificate never creates another certificate',
    (tester) async {
      final repo = ExistingCertificateRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: CertificateScreen(
            course: Course.fromJson({'id': 'course'}),
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.reads, 1);
      expect(repo.claims, 0);
      expect(find.text('CERT-SERVER-12345'), findsOneWidget);
    },
  );
  testWidgets('copy uses the exact server certificate code', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: CertificateScreen(certificate: sampleCertificate),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Sao chép mã'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sao chép mã'));
    await tester.pumpAndSettle();
    expect(copied, sampleCertificate['code']);
  });
}
