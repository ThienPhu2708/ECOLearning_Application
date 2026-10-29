import 'package:flutter/material.dart';

/// Màu của bong bóng / cửa sổ Trợ lý Elearning, lấy đúng biến CSS của website (assets/css/chat-bubble.css)
class ChatbotColors {
  ChatbotColors._();
  static const blue = Color(0xFF434CE8);
  static const blue2 = Color(0xFF6D74F2);
  static const blueDark = Color(0xFF353EC4);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const logBackground = Color(0xFFF8FAFC);
  static const online = Color(0xFF22C55E);
  static const statusDot = Color(0xFF4ADE80);
  static const eye = Color(0xFFA5F3FC);
  static const footer = Color(0xFF94A3B8);
  static const errorBackground = Color(0xFFFEF2F2);
  static const errorBorder = Color(0xFFFECACA);
  static const errorText = Color(0xFFB91C1C);

  /// Nền bong bóng: linear-gradient(145deg, blue-2, blue 60%, blue-dark)
  static const bubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue2, blue, blueDark],
    stops: [0, .6, 1],
  );

  /// Nền header cửa sổ chat: linear-gradient(135deg, blue, blue-2)
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, blue2],
  );
}

/// Robot của Trợ lý Elearning (vẽ lại SVG viewBox 48×48 trong Views/Shared/_ChatBubble.cshtml):
/// thân theo [color] (mặc định trắng), màn hình xanh, mắt và miệng xanh nhạt.
class ChatbotRobot extends StatelessWidget {
  final double size;
  final Color color;

  const ChatbotRobot({super.key, this.size = 36, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _RobotPainter(color),
  );
}

class _RobotPainter extends CustomPainter {
  final Color body;
  _RobotPainter(this.body);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final fill = Paint()..color = body;
    // Ăng-ten
    canvas.drawLine(
      const Offset(24, 5),
      const Offset(24, 12),
      Paint()
        ..color = body
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(24, 5), 3, fill);
    // Tai
    canvas.drawRRect(RRect.fromLTRBR(4, 20, 9, 30, const Radius.circular(2.5)), fill);
    canvas.drawRRect(RRect.fromLTRBR(39, 20, 44, 30, const Radius.circular(2.5)), fill);
    // Đầu, màn hình
    canvas.drawRRect(RRect.fromLTRBR(8, 11, 40, 38, const Radius.circular(10)), fill);
    canvas.drawRRect(
      RRect.fromLTRBR(12.5, 16.5, 35.5, 31.5, const Radius.circular(6)),
      Paint()..color = ChatbotColors.blue,
    );
    // Mắt, miệng
    final eye = Paint()..color = ChatbotColors.eye;
    canvas.drawCircle(const Offset(19.5, 24), 2.7, eye);
    canvas.drawCircle(const Offset(28.5, 24), 2.7, eye);
    canvas.drawPath(
      Path()
        ..moveTo(21, 28.6)
        ..quadraticBezierTo(24, 30.6, 27, 28.6),
      Paint()
        ..color = ChatbotColors.eye
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RobotPainter old) => old.body != body;
}

/// Bong bóng tròn mở Trợ lý Elearning (góc phải dưới, giống website): nền gradient, viền trắng,
/// chấm xanh "đang hoạt động", badge đỏ số tin chưa đọc và lời chào bên cạnh.
class ChatbotBubble extends StatelessWidget {
  final VoidCallback onPressed;

  /// Số tin chưa đọc (0 = ẩn badge)
  final int unread;

  /// Hiện lời chào "Xin chào! 👋 ..." cạnh bong bóng
  final bool showTeaser;
  final VoidCallback? onDismissTeaser;

  const ChatbotBubble({
    super.key,
    required this.onPressed,
    this.unread = 0,
    this.showTeaser = false,
    this.onDismissTeaser,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Semantics(
      button: true,
      label: unread > 0
          ? 'Mở Trợ lý Elearning ($unread tin chưa đọc)'
          : 'Mở Trợ lý Elearning',
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 62,
          height: 62,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ChatbotColors.bubbleGradient,
                  border: Border.all(color: Colors.white.withValues(alpha: .9), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: ChatbotColors.blue.withValues(alpha: .55),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const ChatbotRobot(size: 32),
              ),
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ChatbotColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!showTeaser) return bubble;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 14, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ChatbotColors.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: ChatbotColors.text.withValues(alpha: .25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 30, 12),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Xin chào! 👋\n',
                          style: TextStyle(fontWeight: FontWeight.w700, color: ChatbotColors.text),
                        ),
                        TextSpan(
                          text: 'Mình là Trợ lý Elearning. Bạn cần tìm khóa học nào?',
                          style: TextStyle(color: ChatbotColors.muted),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ),
                // Nút ẩn lời chào (.eco-cb-teaser-x): góc trên phải, nằm trong khung để bấm được
                Positioned(
                  top: 6,
                  right: 6,
                  child: Tooltip(
                    message: 'Ẩn lời chào',
                    child: InkResponse(
                      onTap: onDismissTeaser,
                      radius: 16,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: Icon(Icons.close_rounded, size: 16, color: ChatbotColors.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bubble,
      ],
    );
  }
}
