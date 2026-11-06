import '../../core/config/api_config.dart';
import '../../core/utils/json_utils.dart';
import 'course.dart';

class InstructorProfile {
  final String id, name, avatarUrl, specialty, experience;
  final int coursesCount, studentsCount, reviewCount;
  final double rating;
  final List<Course> courses;
  const InstructorProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.specialty,
    required this.experience,
    required this.coursesCount,
    required this.studentsCount,
    required this.reviewCount,
    required this.rating,
    required this.courses,
  });

  factory InstructorProfile.fromJson(
    Map<String, dynamic> json,
  ) => InstructorProfile(
    id: JsonUtils.asString(json['id']),
    name: JsonUtils.asString(json['fullName']),
    avatarUrl: ApiConfig.resolveMediaUrl(JsonUtils.asString(json['avatarUrl'])),
    specialty: JsonUtils.asString(json['specialty']),
    experience: JsonUtils.asString(json['experience']),
    coursesCount: JsonUtils.asInt(json['coursesCount']),
    studentsCount: JsonUtils.asInt(json['studentsCount']),
    reviewCount: JsonUtils.asInt(json['reviewCount']),
    rating: JsonUtils.asDouble(json['rating']),
    courses: JsonUtils.asMapList(json['courses']).map(Course.fromJson).toList(),
  );
}
