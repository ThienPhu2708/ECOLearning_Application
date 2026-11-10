import 'package:flutter/widgets.dart';

/// Bắt các lỗi lọt lưới (không có try/catch nào bắt) ở một chỗ duy nhất:
/// - lỗi khi dựng giao diện (FlutterError.onError): giữ hành vi mặc định (màn đỏ khi debug) rồi ghi log;
/// - lỗi bất đồng bộ chưa được bắt (Future không await, callback...): ghi log và coi như đã xử lý để app không văng.
/// Muốn gửi lỗi về server sau này thì chỉ cần sửa [ErrorReporter].
void installErrorReporting({void Function(String message)? log}) {
  final reporter = ErrorReporter(log ?? debugPrint);
  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    presentError?.call(details);
    reporter.flutterError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = reporter.asyncError;
}

class ErrorReporter {
  ErrorReporter(this._log);
  final void Function(String message) _log;

  void flutterError(FlutterErrorDetails details) =>
      _log('[Lỗi giao diện] ${details.exceptionAsString()}');

  /// Dùng làm PlatformDispatcher.onError: trả true = đã xử lý, không để engine coi là lỗi nghiêm trọng
  bool asyncError(Object error, StackTrace stack) {
    _log('[Lỗi bất đồng bộ chưa được bắt] $error\n$stack');
    return true;
  }
}
