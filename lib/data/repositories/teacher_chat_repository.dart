import 'dart:typed_data';
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';

class TeacherConversation {
  final int id;
  final String courseId,
      courseName,
      participantName,
      avatarUrl,
      lastMessage,
      status;
  final int unreadCount;
  final String participantRole;
  final DateTime? lastMessageAt;
  const TeacherConversation({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.participantName,
    this.avatarUrl = '',
    this.lastMessage = '',
    this.status = 'Mo',
    this.unreadCount = 0,
    this.participantRole = '',
    this.lastMessageAt,
  });
  bool get readOnly => status != 'Mo';
  String get participantRoleLabel => switch (participantRole) {
    'GiaoVien' => 'Giáo viên',
    'HocVien' => 'Học viên',
    _ => '',
  };
  factory TeacherConversation.fromJson(Map<String, dynamic> json) {
    final participant = JsonUtils.asMap(json['participant']);
    return TeacherConversation(
      id: JsonUtils.asInt(json['id']),
      courseId: JsonUtils.asString(json['courseId']),
      courseName: JsonUtils.asString(json['courseName']),
      participantName: JsonUtils.asString(
        participant['fullName'],
        fallback: 'Giáo viên',
      ),
      avatarUrl: JsonUtils.asString(participant['avatarUrl']),
      participantRole: JsonUtils.asString(participant['role']),
      lastMessage: JsonUtils.asString(json['lastMessage']),
      status: JsonUtils.asString(json['status'], fallback: 'Mo'),
      unreadCount: JsonUtils.asInt(json['unreadCount']),
      lastMessageAt: JsonUtils.asDate(json['lastMessageAt']),
    );
  }
}

class TeacherChatMessage {
  final int id;
  final String content;
  final String? imageUrl;
  final bool isMine, recalled, canRecall;
  final DateTime? sentAt;
  final DateTime recallDeadline;
  TeacherChatMessage({
    required this.id,
    required this.content,
    this.imageUrl,
    this.isMine = false,
    this.recalled = false,
    this.canRecall = false,
    this.sentAt,
    required this.recallDeadline,
  });
  bool get recallAvailable =>
      isMine &&
      !recalled &&
      canRecall &&
      DateTime.now().isBefore(recallDeadline);
  factory TeacherChatMessage.fromJson(Map<String, dynamic> json) =>
      TeacherChatMessage(
        id: JsonUtils.asInt(json['id']),
        content: JsonUtils.asString(json['content']),
        imageUrl: JsonUtils.asStringOrNull(json['imageUrl']),
        isMine: JsonUtils.asBool(json['isMine']),
        recalled: JsonUtils.asBool(json['recalled']),
        canRecall: JsonUtils.asBool(json['canRecall']),
        sentAt: JsonUtils.asDate(json['sentAt']),
        recallDeadline: DateTime.now().add(
          Duration(seconds: JsonUtils.asInt(json['recallSeconds'])),
        ),
      );
}

class TeacherChatPage {
  final TeacherConversation conversation;
  final List<TeacherChatMessage> messages;
  TeacherChatPage(this.conversation, this.messages);
}

class TeacherChatSendResult {
  final TeacherChatMessage message;
  final bool externalPaymentWarning;
  TeacherChatSendResult(this.message, this.externalPaymentWarning);
}

class TeacherChatRepository {
  TeacherChatRepository({ApiClient? client})
    : _api = client ?? ApiClient.instance;
  final ApiClient _api;
  Future<List<TeacherConversation>> conversations({
    String? courseId,
    bool unreadOnly = false,
  }) async => JsonUtils.asMapList(
    await _api.get(
      '/chat/conversations',
      query: {'courseId': courseId, 'status': unreadOnly ? 'unread' : 'all'},
    ),
  ).map(TeacherConversation.fromJson).toList();
  Future<TeacherConversation> open(String courseId) async =>
      TeacherConversation.fromJson(
        JsonUtils.asMap(
          await _api.post(
            '/chat/courses/${Uri.encodeComponent(courseId)}/conversation',
          ),
        ),
      );
  Future<TeacherChatPage> messages(int id, {int? beforeId}) async {
    final json = JsonUtils.asMap(
      await _api.get(
        '/chat/conversations/$id/messages',
        query: {'beforeId': beforeId, 'limit': 50},
      ),
    );
    return TeacherChatPage(
      TeacherConversation.fromJson(JsonUtils.asMap(json['conversation'])),
      JsonUtils.asMapList(
        json['items'],
      ).map(TeacherChatMessage.fromJson).toList(),
    );
  }

  TeacherChatSendResult _sent(dynamic value) {
    final json = JsonUtils.asMap(value);
    return TeacherChatSendResult(
      TeacherChatMessage.fromJson(JsonUtils.asMap(json['message'])),
      JsonUtils.asBool(json['externalPaymentWarning']),
    );
  }

  Future<TeacherChatSendResult> send(int id, String content) async => _sent(
    await _api.post(
      '/chat/conversations/$id/messages',
      data: {'content': content.trim()},
    ),
  );
  Future<TeacherChatSendResult> sendImage(int id, String path) async => _sent(
    await _api.upload(
      '/chat/conversations/$id/image',
      filePath: path,
      field: 'image',
    ),
  );
  Future<void> markRead(int id) async {
    await _api.post('/chat/conversations/$id/read');
  }

  Future<void> recall(int id, int messageId) async {
    await _api.post('/chat/conversations/$id/messages/$messageId/recall');
  }

  Future<void> report(int id, String reason) async {
    await _api.post(
      '/chat/conversations/$id/report',
      data: {'reason': reason.trim()},
    );
  }

  Future<int> unreadCount() async => JsonUtils.asInt(
    JsonUtils.asMap(await _api.get('/chat/unread-count'))['count'],
  );
  Future<Uint8List> image(int messageId) async =>
      Uint8List.fromList(await _api.chatImage(messageId));
}
