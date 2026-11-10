import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

class SubtitleCue {
  const SubtitleCue(this.start, this.end, this.text);
  final Duration start, end;
  final String text;
}

List<SubtitleCue> parseWebVtt(String source) {
  final text = source
      .replaceAll('\uFEFF', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  Duration? timestamp(String value) {
    final match = RegExp(
      r'^(?:(\d+):)?(\d{2}):(\d{2})\.(\d{3})$',
    ).firstMatch(value);
    if (match == null) return null;
    final minutes = int.parse(match[2]!);
    final seconds = int.parse(match[3]!);
    if (minutes >= 60 || seconds >= 60) return null;
    return Duration(
      hours: int.tryParse(match[1] ?? '') ?? 0,
      minutes: minutes,
      seconds: seconds,
      milliseconds: int.parse(match[4]!),
    );
  }

  final cues = <SubtitleCue>[];
  for (final block in text.split(RegExp(r'\n[ \t]*\n'))) {
    final lines = block.split('\n');
    if (lines.isEmpty ||
        lines.first.startsWith('WEBVTT') ||
        lines.first.startsWith('NOTE') ||
        lines.first == 'STYLE' ||
        lines.first == 'REGION') {
      continue;
    }
    final index = lines.indexWhere((line) => line.contains('-->'));
    if (index < 0) continue;
    final parts = lines[index].split('-->');
    if (parts.length != 2) continue;
    final start = timestamp(parts[0].trim());
    final end = timestamp(parts[1].trim().split(RegExp(r'\s+')).first);
    if (start == null || end == null || end <= start) continue;
    cues.add(SubtitleCue(start, end, lines.skip(index + 1).join('\n')));
  }
  return cues;
}

class LessonSubtitles extends ChangeNotifier {
  LessonSubtitles({
    required this.hasSubtitle,
    required this.url,
    ApiClient? client,
  }) : _client = client ?? ApiClient.instance;
  final bool hasSubtitle;
  final String? url;
  final ApiClient _client;
  bool enabled = false, loading = false, disposed = false;
  String? message;
  List<SubtitleCue>? cues;
  Timer? timer;
  String textAt(Duration position) => enabled
      ? (cues ?? [])
            .where((cue) => position >= cue.start && position < cue.end)
            .map((cue) => cue.text)
            .join('\n')
      : '';
  Future<void> toggle() async {
    if (loading) return;
    if (!hasSubtitle || url == null || url!.isEmpty) {
      message = 'Video hiện chưa hỗ trợ phụ đề';
      timer?.cancel();
      notifyListeners();
      timer = Timer(const Duration(seconds: 3), () {
        if (!disposed) {
          message = null;
          notifyListeners();
        }
      });
      return;
    }
    if (enabled) {
      enabled = false;
      notifyListeners();
      return;
    }
    if (cues == null) {
      loading = true;
      message = null;
      notifyListeners();
      try {
        final source = utf8.decode(await _client.privateBytes(url!));
        if (!source.replaceFirst('\uFEFF', '').trimLeft().startsWith('WEBVTT')) {
          throw const FormatException();
        }
        cues = parseWebVtt(source);
      } catch (_) {
        if (!disposed) {
          message = 'Không tải được phụ đề. Vui lòng thử lại.';
          timer?.cancel();
          timer = Timer(const Duration(seconds: 3), () {
            if (!disposed) {
              message = null;
              notifyListeners();
            }
          });
        }
        return;
      } finally {
        loading = false;
        if (!disposed) notifyListeners();
      }
    }
    if (!disposed) {
      enabled = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposed = true;
    timer?.cancel();
    super.dispose();
  }
}
