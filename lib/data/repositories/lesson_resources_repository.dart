import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

class LessonResourcesRepository {
  LessonResourcesRepository({ApiClient? client})
    : _api = client ?? ApiClient.instance;
  final ApiClient _api;
  String _path(String course, String lesson) =>
      '/learning/${Uri.encodeComponent(course)}/lessons/${Uri.encodeComponent(lesson)}';
  List<Map<String, dynamic>> _items(dynamic data) =>
      JsonUtils.asMapList(data is List ? data : JsonUtils.asMap(data)['items']);
  Future<List<Map<String, dynamic>>> notes(
    String course,
    String lesson,
  ) async => _items(await _api.get('${_path(course, lesson)}/notes'));
  Future<Map<String, dynamic>> saveNote(
    String course,
    String lesson,
    String content,
    int seconds, {
    int? id,
  }) async {
    final body = {'content': content, 'positionSeconds': seconds};
    return JsonUtils.asMap(
      id == null
          ? await _api.post('${_path(course, lesson)}/notes', data: body)
          : await _api.put('/notes/$id', data: body),
    );
  }

  Future<void> deleteNote(int id) async {
    await _api.delete('/notes/$id');
  }

  Future<List<Map<String, dynamic>>> documents(
    String course,
    String lesson,
  ) async => _items(await _api.get('${_path(course, lesson)}/documents'));
  Future<List<int>> download(String id) => _api.downloadDocument(id);
}
