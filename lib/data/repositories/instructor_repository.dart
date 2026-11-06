import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/json_utils.dart';
import '../models/instructor_profile.dart';

class InstructorRepository {
  InstructorRepository({ApiClient? client})
    : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  Future<InstructorProfile> profile(String id) async =>
      InstructorProfile.fromJson(
        JsonUtils.asMap(await _api.get('/teachers/${Uri.encodeComponent(id)}')),
      );

  /// Only accept a unique exact name when the source has no teacher or course ID.
  Future<String> findId(String name) async {
    final data = JsonUtils.asMap(
      await _api.get('/teachers/search', query: {'q': name, 'limit': 20}),
    );
    final exact = JsonUtils.asMapList(data['items'])
        .where(
          (item) =>
              JsonUtils.asString(item['fullName']).trim().toLowerCase() ==
              name.trim().toLowerCase(),
        )
        .toList();
    if (exact.length != 1 || JsonUtils.asString(exact.single['id']).isEmpty) {
      throw const ApiException(
        message:
            'Không xác định được giáo viên. Vui lòng mở từ trang chi tiết khóa học.',
      );
    }
    return JsonUtils.asString(exact.single['id']);
  }
}
