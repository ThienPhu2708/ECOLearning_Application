import '../../core/utils/json_utils.dart';

/// Model Thông tin tài khoản Học viên (đối tượng User, mục 5.5 Task_Tuan10.docx)
class User {
  final String id;
  String fullName;
  String email;
  String avatarUrl;
  final String role; // "Học viên"
  String phone;
  String? gender; // "Nam" / "Nữ" / "Khác"
  DateTime? birthDate;
  int completedCoursesCount;
  int inProgressCoursesCount;
  int certificateCount;
  final String joinDate;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.role = 'Học viên',
    this.phone = '0987 654 321',
    this.gender,
    this.birthDate,
    this.completedCoursesCount = 1,
    this.inProgressCoursesCount = 2,
    this.certificateCount = 0,
    this.joinDate = 'Tháng 01/2026',
  });

  static const Map<String, String> _roleNames = {
    'HocVien': 'Học viên',
    'GiaoVien': 'Giáo viên',
  };

  /// A1, A4 (trong `user`), A8, A9
  factory User.fromJson(Map<String, dynamic> json) {
    final role = JsonUtils.asString(json['role'], fallback: 'HocVien');
    final joined = JsonUtils.asDate(json['joinDate']);
    return User(
      id: JsonUtils.asString(json['id']),
      fullName: JsonUtils.asString(json['fullName']),
      email: JsonUtils.asString(json['email']),
      avatarUrl: JsonUtils.asString(json['avatarUrl']),
      role: _roleNames[role] ?? role,
      phone: JsonUtils.asString(json['phone']),
      gender: JsonUtils.asStringOrNull(json['gender']),
      birthDate: JsonUtils.asDate(json['birthDate']),
      completedCoursesCount: JsonUtils.asInt(json['completedCount']),
      inProgressCoursesCount: JsonUtils.asInt(json['inProgressCount']),
      certificateCount: JsonUtils.asInt(json['certificateCount']),
      joinDate: joined == null
          ? ''
          : 'Tháng ${joined.month.toString().padLeft(2, '0')}/${joined.year}',
    );
  }
}
