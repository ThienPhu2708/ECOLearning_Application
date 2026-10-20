import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Lớp gọi API dùng chung cho cả app (khung chung T-0, Task_Tuan10.docx).
///
/// - Tự gắn `Authorization: Bearer <token>` khi đã đăng nhập.
/// - Tự mở khung phản hồi chung `{ success, message, data }`: thành công trả về `data`,
///   thất bại ném [ApiException] (có `message` tiếng Việt để hiện cho người dùng).
/// - Server trả 401 cho request có token (token hết hạn / bị thu hồi) thì gọi [onUnauthorized]
///   (main.dart gán: xóa phiên, quay về màn Đăng nhập).
///
/// Màn hình không gọi trực tiếp lớp này, mà gọi qua các repository trong `lib/data/repositories`.
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = TokenStorage.instance.token;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;

  /// Gọi khi phiên đăng nhập hết hạn (401 trên request có token)
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => _dio.post(path, data: data, queryParameters: _clean(query)));

  Future<dynamic> put(String path, {Object? data}) => _send(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) => _send(() => _dio.delete(path, data: data));

  /// Gửi file dạng multipart/form-data (vd: đổi ảnh đại diện A10)
  Future<dynamic> upload(String path, {required String filePath, String field = 'file'}) async {
    final form = FormData.fromMap({field: await MultipartFile.fromFile(filePath)});
    return _send(() => _dio.post(path, data: form));
  }

  /// "Bắn và quên": không chờ, không báo lỗi cho người dùng (vd: ghi nhận click B6)
  void fireAndForget(String path, {Object? data}) {
    unawaited(post(path, data: data).then((_) {}, onError: (_) {}));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return _unwrap(response.data, response.statusCode);
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      final hadToken = e.requestOptions.headers['Authorization'] != null;
      if (error.isUnauthorized && hadToken) {
        onUnauthorized?.call();
      }
      throw error;
    }
  }

  static dynamic _unwrap(dynamic body, int? status) {
    if (body is Map && body.containsKey('success')) {
      if (body['success'] == true) return body['data'];
      throw ApiException(
        statusCode: status,
        code: (body['code'] ?? 'UNKNOWN').toString(),
        message: (body['message'] ?? ApiException.defaultMessage(status)).toString(),
      );
    }
    return body;
  }

  /// Bỏ tham số null / rỗng khỏi query (vd: không lọc theo danh mục thì không gửi `categoryId`)
  static Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, dynamic>{};
    query.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      if (v is List && v.isEmpty) return;
      result[k] = v;
    });
    return result;
  }
}
