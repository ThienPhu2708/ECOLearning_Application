import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

class DiscussionComment {
  DiscussionComment.fromJson(Map<String, dynamic> json)
    : id = JsonUtils.asInt(json['id']),
      name = JsonUtils.asString(json['authorName'], fallback: 'Học viên'),
      avatar = JsonUtils.asStringOrNull(json['authorAvatar']),
      content = JsonUtils.asString(json['content']),
      createdAt = DateTime.tryParse(JsonUtils.asString(json['createdAt'])),
      parentId = json['parentId'] == null
          ? null
          : JsonUtils.asInt(json['parentId']),
      replyToAuthor = JsonUtils.asStringOrNull(json['replyToAuthor']),
      replyToContent = JsonUtils.asStringOrNull(json['replyToContent']),
      isMine = JsonUtils.asBool(json['isMine']),
      isTeacher = JsonUtils.asBool(json['isTeacher']),
      hasImage = JsonUtils.asBool(json['hasImage']),
      liked = JsonUtils.asBool(json['likedByMe']),
      likes = JsonUtils.asInt(json['likeCount']),
      replies = JsonUtils.asMapList(
        json['replies'],
      ).map(DiscussionComment.fromJson).toList();
  final int id;
  final int? parentId;
  final String name, content;
  final String? avatar;
  final String? replyToAuthor, replyToContent;
  final DateTime? createdAt;
  final bool isTeacher, hasImage, isMine;
  bool liked;
  int likes;
  final List<DiscussionComment> replies;
}

class DiscussionPage {
  DiscussionPage.fromJson(Map<String, dynamic> json)
    : items = JsonUtils.asMapList(
        json['items'],
      ).map(DiscussionComment.fromJson).toList(),
      page = JsonUtils.asInt(json['page'], fallback: 1),
      totalPages = JsonUtils.asInt(json['totalPages']),
      totalComments = JsonUtils.asInt(json['totalComments']);
  final List<DiscussionComment> items;
  final int page, totalPages, totalComments;
}

class LessonDiscussionRepository {
  LessonDiscussionRepository({ApiClient? client})
    : _api = client ?? ApiClient.instance;
  final ApiClient _api;
  String _path(String course, String lesson) =>
      '/learning/${Uri.encodeComponent(course)}/lessons/${Uri.encodeComponent(lesson)}/discussions';
  Future<DiscussionPage> list(
    String course,
    String lesson, {
    int page = 1,
  }) async => DiscussionPage.fromJson(
    JsonUtils.asMap(
      await _api.get(
        _path(course, lesson),
        query: {'page': page, 'pageSize': 20},
      ),
    ),
  );
  Future<DiscussionPage> timeline(
    String course,
    String lesson, {
    int page = 1,
  }) async => DiscussionPage.fromJson(
    JsonUtils.asMap(
      await _api.get(
        '${_path(course, lesson)}/timeline',
        query: {'page': page, 'pageSize': 30},
      ),
    ),
  );
  Future<void> send(
    String course,
    String lesson,
    String content,
    int? parentId, {
    List<int>? image,
    String? filename,
  }) async {
    final path = _path(course, lesson);
    if (image == null) {
      await _api.post(path, data: {'content': content, 'parentId': parentId});
    } else {
      final png = filename?.toLowerCase().endsWith('.png') == true;
      await _api.postMultipart('$path/image', {
        'image': MultipartFile.fromBytes(
          image,
          filename: filename ?? 'image.jpg',
          contentType: DioMediaType.parse(png ? 'image/png' : 'image/jpeg'),
        ),
        'content': content,
        'parentId': ?parentId,
      });
    }
  }

  Future<Map<String, dynamic>> toggle(
    String course,
    String lesson,
    int id,
  ) async => JsonUtils.asMap(
    await _api.post('${_path(course, lesson)}/$id/likes/toggle'),
  );
  Future<List<int>> image(String course, String lesson, int id) =>
      _api.privateBytes('${_path(course, lesson)}/$id/image');
}
