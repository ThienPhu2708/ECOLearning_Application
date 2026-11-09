import 'package:flutter/material.dart';
import '../../../core/utils/json_utils.dart';

/// Mirrors ECOLearning web: Views/Learning/Certificate.cshtml.
/// Keep certificate geometry independent of phone width and text scaling.
class WebCertificateCanvas extends StatelessWidget {
  static const width = 908.0;
  final Map<String, dynamic> certificate;
  const WebCertificateCanvas({super.key, required this.certificate});
  static String issuedDate(dynamic value) {
    final date = DateTime.tryParse(JsonUtils.asString(value))?.toLocal();
    if (date == null) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final student = JsonUtils.asString(certificate['studentName']);
    final course = JsonUtils.asString(certificate['courseTitle']);
    final teacher = JsonUtils.asString(certificate['instructor']);
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 900,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF1E1B4B), width: 12),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: .15),
                  offset: const Offset(0, 20),
                  blurRadius: 40,
                  spreadRadius: -15,
                ),
                const BoxShadow(color: Color(0xFFC7D2FE), spreadRadius: 2),
              ],
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFF334155), height: 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HỆ THỐNG ĐÀO TẠO TRỰC TUYẾN E-LEARNING',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.95,
                      color: Color(0xFF434CE8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CHỨNG NHẬN TỐT NGHIỆP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.7,
                      height: 1.3,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Chứng nhận này được trân trọng trao cho học viên',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                      ),
                    ),
                    child: Text(
                      student.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF434CE8),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Đã hoàn thành nội dung học và đạt bài kiểm tra cuối khóa:',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 26 / 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 26 / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 68),
                  SizedBox(
                    width: 700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _signature(teacher, teacher, 'Giảng viên phụ trách'),
                        Container(
                          width: 90,
                          height: 90,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: .4),
                                offset: const Offset(0, 4),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'OFFICIAL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '★ VERIFIED ★',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  issuedDate(certificate['issuedAt']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _signature(
                          'E-Learning Board',
                          'Hội đồng Học thuật',
                          'E-Learning Director',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _signature(String signature, String name, String role) => SizedBox(
    width: 180,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          signature,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'cursive',
            fontSize: 20,
            color: Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(
          width: double.infinity,
          height: 1,
          child: ColoredBox(color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          role,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}
