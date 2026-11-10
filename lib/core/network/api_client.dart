import 'dart:async';
import 'dart:convert';

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
  ApiClient({Dio? dio, String? Function()? tokenProvider}) {
    _tokenProvider = tokenProvider ?? (() => TokenStorage.instance.token);
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            responseType: ResponseType.json,
            headers: const {'Accept': 'application/json'},
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient();

  late final Dio _dio;
  late final String? Function() _tokenProvider;

  /// Gọi khi phiên đăng nhập hết hạn (401 trên request có token)
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) =>
      _send(() => _dio.post(path, data: data, queryParameters: _clean(query)));

  Future<dynamic> put(String path, {Object? data}) =>
      _send(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) =>
      _send(() => _dio.delete(path, data: data));

  /// Private resources are fetched only from the API origin, without redirects.
  Future<List<int>> privateBytes(String path) async {
    final uri = Uri.parse(path);
    final base = Uri.parse(ApiConfig.baseUrl);
    if (uri.hasAuthority && uri.origin != base.origin) {
      throw const ApiException(message: 'Đường dẫn tài nguyên không hợp lệ.');
    }
    final data = await _send(
      () => _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      ),
    );
    return List<int>.from(data as List);
  }

  Future<dynamic> postMultipart(String path, Map<String, dynamic> fields) =>
      _send(() => _dio.post(path, data: FormData.fromMap(fields)));

  /// Private chat media stays on the API origin; never forward the bearer token to redirects.
  Future<List<int>> chatImage(int messageId) async {
    final bytes = await _send(
      () => _dio.get<List<int>>(
        '/chat/messages/$messageId/image',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      ),
    );
    return List<int>.from(bytes as List);
  }

  Future<List<int>> downloadDocument(String id) async {
    final result = await _send(() async {
      try {
        final response = await _dio.get<List<int>>(
          '/documents/${Uri.encodeComponent(id)}/download',
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) =>
                status != null && (status < 300 || status == 302),
          ),
        );
        if (response.statusCode == 302) {
          final location = response.headers.value('location');
          final target = location == null
              ? null
              : response.realUri.resolve(location);
          if (target == null || !['https', 'http'].contains(target.scheme)) {
            throw const ApiException(
              message: 'Liên kết tài liệu không hợp lệ.',
            );
          }
          // A separate client prevents sending the account token to external storage.
          final external = Dio(
            BaseOptions(
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ),
          );
          try {
            return await external.get<List<int>>(
              target.toString(),
              options: Options(responseType: ResponseType.bytes),
            );
          } finally {
            external.close();
          }
        }
        if (response.headers
                .value('content-type')
                ?.contains('application/json') ==
            true) {
          return Response<dynamic>(
            requestOptions: response.requestOptions,
            statusCode: response.statusCode,
            data: jsonDecode(utf8.decode(response.data!)),
          );
        }
        return response;
      } on DioException catch (e) {
        if (e.response?.data is List<int>) {
          try {
            e.response!.data = jsonDecode(
              utf8.decode(e.response!.data as List<int>),
            );
          } catch (_) {
            /* Non-JSON HTTP error. */
          }
        }
        rethrow;
      }
    });
    if (result is! List<int> || result.isEmpty) {
      throw const ApiException(message: 'Không tải được nội dung tài liệu.');
    }
    return result;
  }

  /// Gửi file dạng multipart/form-data (vd: đổi ảnh đại diện A10)
  Future<dynamic> upload(
    String path, {
    required String filePath,
    String field = 'file',
  }) async {
    final extension = filePath.toLowerCase().split('.').last;
    const imageTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    final type = imageTypes[extension];
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(
        filePath,
        contentType: type == null ? null : DioMediaType.parse(type),
      ),
    });
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
        message: (body['message'] ?? ApiException.defaultMessage(status))
            .toString(),
        errors: body['errors'] is Map
            ? (body['errors'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is List ? value.join(' ') : value.toString(),
                ),
              )
            : const {},
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
