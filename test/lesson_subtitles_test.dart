import 'package:flutter_test/flutter_test.dart';
import 'package:ecolearning_app/presentation/screens/learning/lesson_subtitles.dart';

void main() {
  test(
    'parses WebVTT identifiers, hours, cue settings and multiline Unicode',
    () {
      final cues = parseWebVtt(
        '\uFEFFWEBVTT\r\n\r\nfirst\r\n00:01.250 --> 00:03.500 align:start\r\nXin chào\r\nViệt Nam\r\n\r\n01:02:03.000 --> 01:02:04.000\r\nKết thúc\r\n',
      );
      expect(cues.length, 2);
      expect(cues.first.start, const Duration(milliseconds: 1250));
      expect(cues.first.end, const Duration(milliseconds: 3500));
      expect(cues.first.text, 'Xin chào\nViệt Nam');
      expect(cues.last.start, const Duration(hours: 1, minutes: 2, seconds: 3));
    },
  );

  test('ignores malformed cues and notes', () {
    expect(
      parseWebVtt('WEBVTT\n\nNOTE test\nignored\n\n00:01.000 --> invalid\nno'),
      isEmpty,
    );
  });
}
