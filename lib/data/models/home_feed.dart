import '../../core/utils/json_utils.dart';
import 'course.dart';

/// Khóa học trong một mục của Trang chủ, kèm nhãn và ghi chú server gắn
/// (vd: "Bán chạy" / "3 lượt đăng ký tuần này").
class HomeCourseItem {
  final Course course;
  final String? badge;
  final String? note;

  const HomeCourseItem({required this.course, this.badge, this.note});

  factory HomeCourseItem.fromJson(Map<String, dynamic> json) => HomeCourseItem(
    course: Course.fromJson(json),
    badge: JsonUtils.asStringOrNull(json['badge']),
    note: JsonUtils.asStringOrNull(json['note']),
  );
}

/// Một khóa đang học dở trong mục "Tiếp tục học".
class HomeContinueItem {
  final String courseId;
  final String title;
  final String imageUrl;
  final String instructor;
  final double progress; // 0 - 100
  final int completedLessons;
  final int totalLessons;
  final String lessonTitle;
  final int lessonNumber;
  final bool isStarted;

  const HomeContinueItem({
    required this.courseId,
    required this.title,
    required this.imageUrl,
    required this.instructor,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.lessonTitle,
    required this.lessonNumber,
    required this.isStarted,
  });

  factory HomeContinueItem.fromJson(Map<String, dynamic> json) =>
      HomeContinueItem(
        courseId: JsonUtils.asString(json['courseId']),
        title: JsonUtils.asString(json['title']),
        imageUrl: JsonUtils.asString(json['imageUrl']),
        instructor: JsonUtils.asString(json['instructor']),
        progress: JsonUtils.asDouble(json['progress']),
        completedLessons: JsonUtils.asInt(json['completedLessons']),
        totalLessons: JsonUtils.asInt(json['totalLessons']),
        lessonTitle: JsonUtils.asString(json['lessonTitle']),
        lessonNumber: JsonUtils.asInt(json['lessonNumber']),
        isStarted: JsonUtils.asBool(json['isStarted']),
      );

  /// Khóa học tối thiểu để mở màn học (màn học tự tải phần còn lại từ API).
  Course toCourse() => Course.fromJson({
    'id': courseId,
    'title': title,
    'imageUrl': imageUrl,
    'instructor': instructor,
    'progress': progress,
    'isEnrolled': true,
  });
}

/// Giáo viên nổi bật.
class HomeTeacher {
  final String id;
  final String fullName;
  final String avatarUrl;
  final String specialty;
  final int coursesCount;
  final int studentsCount;

  const HomeTeacher({
    required this.id,
    required this.fullName,
    required this.avatarUrl,
    required this.specialty,
    required this.coursesCount,
    required this.studentsCount,
  });

  factory HomeTeacher.fromJson(Map<String, dynamic> json) => HomeTeacher(
    id: JsonUtils.asString(json['id']),
    fullName: JsonUtils.asString(json['fullName']),
    avatarUrl: JsonUtils.asString(json['avatarUrl']),
    specialty: JsonUtils.asString(json['specialty']),
    coursesCount: JsonUtils.asInt(json['coursesCount']),
    studentsCount: JsonUtils.asInt(json['studentsCount']),
  );

  /// Khóa học tối thiểu mang thông tin giảng viên để mở hồ sơ giảng viên.
  Course toCourse() => Course.fromJson({
    'id': '',
    'instructor': fullName,
    'instructorAvatar': avatarUrl,
    'instructorInfo': {'id': id, 'title': specialty},
  });
}

/// Một mục của Trang chủ: `continue`, `courses` hoặc `teachers`.
class HomeSection {
  final String key;
  final String type;
  final String title;
  final String subtitle;
  final List<HomeCourseItem> courses;
  final List<HomeContinueItem> continues;
  final List<HomeTeacher> teachers;

  const HomeSection({
    required this.key,
    required this.type,
    required this.title,
    required this.subtitle,
    this.courses = const [],
    this.continues = const [],
    this.teachers = const [],
  });

  bool get isEmpty =>
      courses.isEmpty && continues.isEmpty && teachers.isEmpty;

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final type = JsonUtils.asString(json['type']);
    final items = JsonUtils.asMapList(json['items']);
    return HomeSection(
      key: JsonUtils.asString(json['key']),
      type: type,
      title: JsonUtils.asString(json['title']),
      subtitle: JsonUtils.asString(json['subtitle']),
      courses: type == 'courses'
          ? items.map(HomeCourseItem.fromJson).toList()
          : const [],
      continues: type == 'continue'
          ? items.map(HomeContinueItem.fromJson).toList()
          : const [],
      teachers: type == 'teachers'
          ? items.map(HomeTeacher.fromJson).toList()
          : const [],
    );
  }
}

/// Dữ liệu Trang chủ từ `GET /home`; khách chưa đăng nhập vẫn nhận được các
/// mục chung (bán chạy, mới ra mắt...).
class HomeFeed {
  final bool isPersonalized;
  final List<HomeSection> sections;

  const HomeFeed({required this.isPersonalized, required this.sections});

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
    isPersonalized: JsonUtils.asBool(json['isPersonalized']),
    sections: JsonUtils.asMapList(json['sections'])
        .map(HomeSection.fromJson)
        .where((s) => !s.isEmpty)
        .toList(),
  );

  HomeSection? section(String key) {
    for (final s in sections) {
      if (s.key == key) return s;
    }
    return null;
  }
}
