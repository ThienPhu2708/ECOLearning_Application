import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/json_utils.dart';
import '../models/course.dart';

/// Một tin nhắn trong cuộc trò chuyện: [fromUser] = người dùng hỏi, ngược lại là trợ lý trả lời.
class ChatMessage {
  final bool fromUser;
  final String content;

  /// Khóa học trợ lý gợi ý kèm câu trả lời (chỉ có ở câu trả lời vừa nhận, lịch sử không lưu)
  final List<Course> courses;

  const ChatMessage({
    required this.fromUser,
    required this.content,
    this.courses = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    fromUser: JsonUtils.asString(json['role']) == 'user',
    content: JsonUtils.asString(json['content']),
  );
}

/// Nhóm K: Trợ lý Elearning (cùng chatbot Gemini với website).
/// Server tắt trợ lý (`Chatbot:Enabled`) thì mọi API trả 404 `CHATBOT_DISABLED`.
class ChatbotRepository {
  ChatbotRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  static const disabledCode = 'CHATBOT_DISABLED';
  static const maxQuestionLength = 500;

  /// Kết quả kiểm tra server có bật trợ lý không, nhớ trong phiên chạy app
  static bool? _available;

  /// Server có bật trợ lý không (để hiện / ẩn lối vào).
  /// 404 (tắt trợ lý, hoặc server chưa có API này) thì nhớ là không có; lỗi khác coi như chưa biết, lần sau hỏi lại.
  Future<bool> isAvailable() async {
    final known = _available;
    if (known != null) return known;
    try {
      await _api.get('/chatbot/history');
      return _available = true;
    } on ApiException catch (e) {
      if (e.isNotFound) return _available = false;
      return false;
    }
  }

  @visibleForTesting
  static void resetAvailability() => _available = null;

  /// K1. Hỏi trợ lý. Lỗi 429 khi hỏi quá nhiều, 503 `CHATBOT_QUOTA` / `CHATBOT_BUSY` / `CHATBOT_UNAVAILABLE` khi Gemini lỗi.
  Future<ChatMessage> ask(String question) async {
    final data = JsonUtils.asMap(
      await _api.post('/chatbot/ask', data: {'question': question.trim()}),
    );
    return ChatMessage(
      fromUser: false,
      content: JsonUtils.asString(data['reply']),
      courses: JsonUtils.asMapList(data['courses'])
          .map(
            (c) => Course.fromJson({
              ...c,
              'imageUrl': c['thumbnail'],
            }),
          )
          .toList(),
    );
  }

  /// K2. Lịch sử của tài khoản (khách: luôn rỗng)
  Future<List<ChatMessage>> history() async => JsonUtils.asMapList(
    JsonUtils.asMap(await _api.get('/chatbot/history'))['messages'],
  ).map(ChatMessage.fromJson).toList();

  /// K3. Xóa lịch sử, bắt đầu cuộc trò chuyện mới
  Future<void> clearHistory() async {
    await _api.delete('/chatbot/history');
  }
}
