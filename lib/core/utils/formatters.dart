import 'package:intl/intl.dart';

/// Các tiện ích định dạng tiền tệ và thời lượng bài giảng
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Định dạng tiền tệ Việt Nam Đồng (VD: 1.190.000 đ hoặc Miễn phí)
  static String formatCurrency(double amount) {
    if (amount <= 0) {
      return 'Miễn phí';
    }
    return _currencyFormatter.format(amount).trim();
  }

  /// Định dạng số giây sang dạng mm:ss (VD: 05:20)
  static String formatDurationFromSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  /// Tổng thời lượng khóa học (VD: 19200 giây -> "5 giờ 20 phút", 2700 -> "45 phút")
  static String formatTotalDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes == 0 ? 1 : minutes} phút';
    return minutes == 0 ? '$hours giờ' : '$hours giờ $minutes phút';
  }

  /// Định dạng số đếm gọn (VD: 12.500 -> 12.5K)
  static String formatCompactNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
