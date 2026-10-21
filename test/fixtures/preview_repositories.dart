import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecolearning_app/core/network/api_exception.dart';
import 'package:ecolearning_app/core/network/paged_result.dart';
import 'package:ecolearning_app/data/models/course.dart';
import 'package:ecolearning_app/data/models/category.dart';
import 'mock_data.dart';
import 'package:ecolearning_app/data/repositories/recommendation_repository.dart';
import 'package:ecolearning_app/data/models/lesson.dart';
import 'package:ecolearning_app/data/repositories/favorite_repository.dart';
import 'package:ecolearning_app/data/repositories/learning_repository.dart';
import 'package:ecolearning_app/data/repositories/order_repository.dart';
import 'package:ecolearning_app/data/repositories/quiz_repository.dart';
import 'package:ecolearning_app/data/repositories/course_repository.dart';
import 'package:ecolearning_app/data/repositories/review_repository.dart';

// Only the separate preview entry point imports this file. Production never falls back to samples.
Future<void> _delay() =>
    Future<void>.delayed(const Duration(milliseconds: 250));
PagedResult<T> _page<T>(List<T> data, int page) {
  const size = 3;
  final start = ((page - 1) * size).clamp(0, data.length);
  return PagedResult(
    items: data.skip(start).take(size).toList(),
    page: page,
    pageSize: size,
    total: data.length,
    totalPages: (data.length / size).ceil(),
  );
}

Course previewCourse(String id, String title, {double progress = 0}) =>
    Course.fromJson({
      'id': id,
      'title': title,
      'category': 'Lập trình',
      'instructor': 'Trần Minh Khoa',
      'imageUrl': '',
      'price': 349000,
      'rating': 4.8,
      'reviewCount': 24,
      'lessonsCount': 6,
      'progress': progress,
      'isEnrolled': progress > 0,
    });

class PreviewLearningRepository extends LearningRepository {
  final PreviewQuizRepository? quiz;
  final bool publicVideo;
  PreviewLearningRepository({this.quiz, this.publicVideo = false});
  Course? _publicCourse;
  final ongoing = [
    previewCourse(
      'preview-flutter',
      'Xây dựng ứng dụng với Flutter',
      progress: 50,
    ),
  ];
  final completed = [
    previewCourse(
      'preview-csharp',
      'Lập trình C# từ cơ bản đến nâng cao',
      progress: 100,
    ),
  ];
  @override
  Future<PagedResult<Course>> myCourses({
    String status = MyCourseStatus.inProgress,
    int page = 1,
  }) async {
    await quiz?.ready();
    await _delay();
    return _page(
      (status == MyCourseStatus.completed ? completed : ongoing)
          .map(
            (course) => course.copyWith(
              hasCertificate: quiz == null
                  ? course.hasCertificate
                  : quiz!._certificates.containsKey(course.id),
            ),
          )
          .toList(),
      page,
    );
  }

  @override
  Future<LearningOverview> overview(String courseId) async {
    await _delay();
    if (publicVideo && courseId == 'preview-csharp') {
      await quiz?.ready();
      final data = _publicCourse ??= await CourseRepository().detail('DMKH01');
      final certified = quiz?._certificates.containsKey(courseId) ?? false;
      return LearningOverview(
        courseId: courseId,
        title: data.title,
        progress: 100,
        currentLessonId: data.chapters
            .expand((c) => c.lessons)
            .where((l) => l.isFree)
            .firstOrNull
            ?.id,
        chapters: data.chapters
            .map(
              (chapter) => Chapter(
                id: chapter.id,
                title: chapter.title,
                lessons: chapter.lessons
                    .map((lesson) => lesson.copyWith(isCompleted: true))
                    .toList(),
              ),
            )
            .toList(),
        quizAvailable: true,
        quizPassed: certified,
        certificateIssued: certified,
        canReview: certified,
      );
    }
    return LearningOverview(
      courseId: courseId,
      title: 'Khóa học mẫu',
      progress: 50,
      currentLessonId: 'lesson-2',
      chapters: [
        Chapter(
          id: 'chapter-1',
          title: 'Làm quen với Flutter',
          lessons: [
            Lesson(
              id: 'lesson-1',
              title: 'Cài đặt môi trường phát triển',
              duration: '07:00',
              durationSeconds: 420,
              isCompleted: true,
            ),
            Lesson(
              id: 'lesson-2',
              title: 'Widget và bố cục cơ bản',
              duration: '12:00',
              durationSeconds: 720,
              lastPositionSeconds: 120,
            ),
          ],
        ),
      ],
      quizAvailable: false,
      quizPassed: false,
      certificateIssued: false,
      canReview: false,
    );
  }

  @override
  Future<Lesson> lesson(String courseId, String lessonId) async {
    final data = await overview(courseId);
    final lesson = data.chapters
        .expand((c) => c.lessons)
        .firstWhere((l) => l.id == lessonId);
    if (publicVideo && courseId == 'preview-csharp' && lesson.isFree) {
      final preview = await CourseRepository().preview('DMKH01', lessonId);
      return lesson.copyWith(
        videoUrl: preview['videoUrl'] as String?,
        videoSummary:
            'Video xem thử công khai từ khóa C#. Tiến độ tại đây là dữ liệu thử.',
      );
    }
    return lesson;
  }

  @override
  Future<ProgressResult> saveProgress(
    String courseId,
    String lessonId, {
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    await _delay();
    return ProgressResult(
      lessonCompleted:
          courseId == 'preview-csharp' ||
          (durationSeconds > 0 && positionSeconds >= durationSeconds * .8),
      courseProgress: courseId == 'preview-csharp' ? 100 : 50,
    );
  }
}

class PreviewFavoriteRepository extends FavoriteRepository {
  PreviewFavoriteRepository({this.catalogue = const []}) {
    for (final c in courses) {
      c.isFavorite = true;
    }
  }
  final List<Course> catalogue;
  final courses = [
    previewCourse('favorite-flutter', 'Flutter: xây dựng ứng dụng di động'),
    previewCourse('favorite-design', 'Thiết kế giao diện UI/UX cho người mới'),
    previewCourse('favorite-sql', 'SQL Server từ cơ bản đến nâng cao'),
    previewCourse('favorite-web', 'Xây dựng website với ASP.NET Core'),
  ];
  @override
  Future<PagedResult<Course>> list({int page = 1}) async {
    await _delay();
    return _page(courses.where((c) => !c.isEnrolled).toList(), page);
  }

  @override
  Future<bool> toggle(String courseId) async {
    await _delay();
    final existing = courses.where((c) => c.id == courseId).firstOrNull;
    if (existing != null) {
      courses.removeWhere((c) => c.id == courseId);
      existing.isFavorite = false;
      return false;
    }
    final course = [
      ...catalogue,
      MockData.topMatchCourse,
      ...MockData.allCourses,
    ].where((c) => c.id == courseId).firstOrNull;
    if (course == null) {
      throw const ApiException(message: 'Không tìm thấy khóa học.');
    }
    if (course.isEnrolled) {
      throw const ApiException(
        message: 'Khóa học này đã có trong Khóa học của tôi.',
      );
    }
    course.isFavorite = true;
    courses.add(course);
    return true;
  }
}

class PreviewOrderRepository extends OrderRepository {
  final _orders = [
    for (int i = 0; i < 6; i++)
      {
        'orderId': 'DH26102010${(i + 1).toString().padLeft(4, '0')}',
        'status': [
          'paid',
          'pending',
          'failed',
          'expired',
          'cancelled',
          'paid',
        ][i],
        'total': i == 5 ? 0 : 349000,
        'discount': 0,
        'itemsCount': 1,
        'createdAt': DateTime(2026, 10, 20 - i, 10, 30).toIso8601String(),
        'paidAt': i == 0 || i == 5
            ? DateTime(2026, 10, 20 - i, 10, 35).toIso8601String()
            : null,
        'paymentMethod': 'Thẻ ATM nội địa',
        'transactionNo': i == 0 ? 'VNP26001020' : null,
        'items': [
          {
            'id': 'preview-csharp',
            'title': 'Lập trình C# từ cơ bản đến nâng cao',
            'price': 349000,
          },
        ],
      },
  ];
  @override
  Future<PagedResult<Map<String, dynamic>>> orders({int page = 1}) async {
    await _delay();
    return _page(_orders, page);
  }

  @override
  Future<Map<String, dynamic>> order(String orderId) async {
    await _delay();
    return Map.of(_orders.firstWhere((o) => o['orderId'] == orderId));
  }
}

class _Attempt {
  _Attempt(this.id, this.courseId, {DateTime? expiry})
    : expiry = expiry ?? DateTime.now().add(const Duration(minutes: 30));
  final int id;
  final String courseId;
  final DateTime expiry;
  List<int> answers = List.filled(10, -1);
  Map<String, dynamic>? result;
}

class PreviewQuizRepository extends QuizRepository {
  final bool persistent;
  PreviewQuizRepository({this.persistent = false});
  static const storageKey = 'learning_preview_quiz_v1';
  Future<void>? _restoring;
  Future<void> _writes = Future.value();
  Future<void> ready() =>
      persistent ? (_restoring ??= _restore()) : Future.value();
  Future<void> _restore() async {
    final raw = (await SharedPreferences.getInstance()).getString(storageKey);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    for (final item in (data['attempts'] as List? ?? [])) {
      final a = _Attempt(
        item['id'] as int,
        item['courseId'] as String,
        expiry: DateTime.parse(item['expiry'] as String),
      );
      a.answers = List<int>.from(item['answers'] as List);
      a.result = item['result'] == null
          ? null
          : Map<String, dynamic>.from(item['result'] as Map);
      _attempts[a.id] = a;
    }
    final certificates = data['certificates'] as Map? ?? {};
    certificates.forEach(
      (key, value) => _certificates[key as String] = Map<String, dynamic>.from(
        value as Map,
      ),
    );
  }

  Future<void> _persist() {
    if (!persistent) return Future.value();
    final snapshot = jsonEncode({
      'certificates': _certificates,
      'attempts': [
        for (final a in _attempts.values)
          {
            'id': a.id,
            'courseId': a.courseId,
            'expiry': a.expiry.toIso8601String(),
            'answers': a.answers,
            'result': a.result,
          },
      ],
    });
    final write = _writes.then((_) async {
      if (!await (await SharedPreferences.getInstance()).setString(
        storageKey,
        snapshot,
      )) {
        throw const ApiException(
          message: 'Chưa lưu được dữ liệu thử trên máy. Vui lòng thử lại.',
        );
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  final Map<int, _Attempt> _attempts = {};
  final Map<String, Map<String, dynamic>> _certificates = {};
  final _questions = <Map<String, dynamic>>[
    {
      'text': 'Từ khóa nào dùng để khai báo lớp trong C#?',
      'options': ['class', 'table', 'select', 'function'],
    },
    {
      'text': 'Kiểu dữ liệu nào lưu giá trị đúng hoặc sai?',
      'options': ['int', 'bool', 'string', 'char'],
    },
    {
      'text': 'Câu lệnh nào in một dòng văn bản ra console?',
      'options': [
        'Console.Read()',
        'print()',
        'Console.WriteLine()',
        'write()',
      ],
    },
    {
      'text': 'Toán tử nào dùng để so sánh hai giá trị bằng nhau?',
      'options': ['=', '!=', '>=', '=='],
    },
    {
      'text': 'Chỉ số phần tử đầu tiên của mảng C# là bao nhiêu?',
      'options': ['0', '1', '-1', '2'],
    },
    {
      'text': 'Thành viên private được truy cập trực tiếp ở đâu?',
      'options': [
        'Mọi lớp',
        'Trong chính lớp khai báo',
        'Mọi assembly',
        'Chỉ lớp kế thừa',
      ],
    },
    {
      'text': 'Từ khóa nào ghi đè phương thức virtual của lớp cha?',
      'options': ['new', 'static', 'override', 'sealed'],
    },
    {
      'text': 'Khối nào bắt và xử lý ngoại lệ từ khối try?',
      'options': ['finally', 'using', 'throw', 'catch'],
    },
    {
      'text': 'Từ khóa nào dùng để tạo một đối tượng?',
      'options': ['new', 'this', 'base', 'void'],
    },
    {
      'text': 'Từ khóa nào duyệt lần lượt các phần tử trong collection?',
      'options': ['if', 'foreach', 'switch', 'return'],
    },
  ];
  @override
  Future<Map<String, dynamic>> info(String courseId) async {
    await ready();
    await _delay();
    final attempts = _attempts.values
        .where((a) => a.courseId == courseId)
        .toList();
    final active = attempts.where((a) => a.result == null).firstOrNull;
    final last = attempts.where((a) => a.result != null).lastOrNull;
    final passed = attempts.any((a) => a.result?['passed'] == true);
    return {
      'title': 'Quiz cuối khóa',
      'questionCount': 10,
      'minutes': 30,
      'passPercent': 80,
      'attemptsUsed': attempts.length,
      'attemptsAllowed': 3,
      'canStart': !passed && attempts.length < 3,
      'reason': passed
          ? 'Bạn đã đạt quiz của khóa học này.'
          : 'Bạn đã dùng hết số lượt làm bài.',
      'activeAttemptId': active?.id,
      'lastResult': last?.result,
    };
  }

  @override
  Future<Map<String, dynamic>> start(String courseId) async {
    await ready();
    await _delay();
    final list = _attempts.values.where((a) => a.courseId == courseId).toList();
    var attempt = list.where((a) => a.result == null).firstOrNull;
    if (attempt == null) {
      if (list.length >= 3 || list.any((a) => a.result?['passed'] == true)) {
        throw const ApiException(message: 'Bạn không còn lượt làm quiz.');
      }
      attempt = _Attempt(_attempts.length + 1, courseId);
      _attempts[attempt.id] = attempt;
    }
    await _persist();
    return {
      'attemptId': attempt.id,
      'expiresAt': attempt.expiry.toIso8601String(),
      'questions': [
        for (int i = 0; i < _questions.length; i++)
          {..._questions[i], 'index': i},
      ],
      'answers': List.of(attempt.answers),
    };
  }

  @override
  Future<bool> saveDraft(int attemptId, List<int> answers) async {
    await ready();
    await _delay();
    final attempt = _attempts[attemptId]!;
    if (!attempt.expiry.isAfter(DateTime.now()) || attempt.result != null) {
      return false;
    }
    attempt.answers = List.of(answers);
    await _persist();
    return true;
  }

  @override
  Future<Map<String, dynamic>> submit(int attemptId, List<int> answers) async {
    await ready();
    await _delay();
    final attempt = _attempts[attemptId]!;
    if (attempt.result != null) return attempt.result!;
    final timedOut = !attempt.expiry.isAfter(DateTime.now());
    final selected = timedOut ? attempt.answers : answers;
    int correct = 0;
    for (int i = 0; i < 10; i++) {
      if (selected[i] == i % 4) correct++;
    }
    attempt.result = {
      'score': correct.toDouble(),
      'correct': correct,
      'total': 10,
      'passed': correct >= 8,
      'passPercent': 80,
      'timedOut': timedOut,
    };
    await _persist();
    return attempt.result!;
  }

  @override
  Future<Map<String, dynamic>> claimCertificate(String courseId) async {
    await ready();
    await _delay();
    if (!_attempts.values.any(
      (a) => a.courseId == courseId && a.result?['passed'] == true,
    )) {
      throw const ApiException(
        message: 'Bạn cần đạt quiz trước khi nhận chứng chỉ.',
      );
    }
    final certificate = _certificates.putIfAbsent(
      courseId,
      () => {
        'code': 'CERT-PREVIEW-2026',
        'studentName': MockData.currentUser.fullName,
        'courseTitle': 'Lập trình C# từ cơ bản đến nâng cao',
        'instructor': 'Trần Minh Khoa',
        'issuedAt': DateTime.now().toIso8601String(),
        'durationSeconds': 21600,
      },
    );
    await _persist();
    return certificate;
  }

  @override
  Future<Map<String, dynamic>> certificate(String courseId) async {
    await ready();
    await _delay();
    final value = _certificates[courseId];
    if (value == null) {
      throw const ApiException(
        message: 'Bạn chưa nhận chứng chỉ cho khóa học này.',
      );
    }
    return value;
  }

  @override
  Future<List<Map<String, dynamic>>> certificates() async {
    await ready();
    await _delay();
    return _certificates.values.toList();
  }
}

class PreviewCourseRepository extends CourseRepository {
  @override
  Future<({List<String> keywords, List<Course> courses})> suggest(
    String q,
  ) async => (keywords: <String>[], courses: <Course>[]);

  final PreviewLearningRepository learning;
  final PreviewQuizRepository quiz;
  PreviewCourseRepository(this.learning, this.quiz);
  @override
  Future<List<Category>> categories() async => MockData.categories;
  @override
  Future<PagedResult<Course>> courses({
    String? q,
    String? categoryId,
    String? level,
    String? price,
    double? minRating,
    String? sort,
    int page = 1,
    int pageSize = 12,
  }) async {
    final values = [MockData.topMatchCourse, ...MockData.allCourses];
    return PagedResult(
      items: values,
      page: 1,
      pageSize: values.length,
      total: values.length,
      totalPages: 1,
    );
  }

  @override
  Future<Course> detail(String courseId) async {
    await _delay();
    final course = [
      ...learning.ongoing,
      ...learning.completed,
    ].where((c) => c.id == courseId).firstOrNull;
    if (course == null) {
      throw const ApiException(message: 'Không tìm thấy khóa học.');
    }
    await quiz.ready();
    final certified = quiz._certificates.containsKey(courseId);
    return course.copyWith(
      canReview: certified && course.progress >= 100,
      hasCertificate: certified,
    );
  }
}

class PreviewReviewRepository extends ReviewRepository {
  final PreviewLearningRepository learning;
  final PreviewQuizRepository quiz;
  PreviewReviewRepository(this.learning, this.quiz);
  @override
  Future<Map<String, dynamic>> submit(
    String courseId, {
    required int rating,
    String? comment,
  }) async {
    final course = [
      ...learning.ongoing,
      ...learning.completed,
    ].where((c) => c.id == courseId).firstOrNull;
    if (course == null ||
        course.progress < 100 ||
        !quiz._certificates.containsKey(courseId)) {
      throw const ApiException(
        message: 'Bạn cần học đủ bài và đạt quiz trước khi đánh giá.',
      );
    }
    if (rating < 1 || rating > 5) {
      throw const ApiException(message: 'Vui lòng chọn từ 1 đến 5 sao.');
    }
    await _delay();
    course.myReviewRating = rating.toDouble();
    course.myReviewComment = comment?.trim();
    return {'rating': rating, 'comment': comment?.trim()};
  }
}

class PreviewRecommendationRepository extends RecommendationRepository {
  @override
  Future<RecommendationResult> recommendations({int limit = 10}) async =>
      RecommendationResult(type: 'popular', items: [MockData.topMatchCourse]);
}
