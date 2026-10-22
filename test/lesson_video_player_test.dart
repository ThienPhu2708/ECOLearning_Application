import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:ecolearning_app/presentation/screens/learning/lesson_video_player.dart';

class TestVideo extends VideoPlayerController {
  TestVideo() : super.networkUrl(Uri.parse('https://example.com/video.mp4')) {
    value = VideoPlayerValue(
      duration: Duration(minutes: 12),
      position: Duration(minutes: 3, seconds: 24),
      size: Size(1920, 1080),
      isInitialized: true,
      buffered: [DurationRange(Duration.zero, Duration(minutes: 5))],
    );
  }
  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
  }
}

void main() {
  for (final size in [const Size(844, 390), const Size(720, 300)]) {
    testWidgets(
      'speed menu fits landscape $size and all choices remain reachable',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final video = TestVideo();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: Scaffold(
              body: LessonVideoPlayer(
                controller: video,
                title: 'SELECT, WHERE và ORDER BY',
                fullscreen: true,
                loading: false,
                error: null,
                onBack: () {},
                onRetry: () {},
                onPlayPause: () async {},
                onFullscreen: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tốc độ phát'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('2.0x'));
        await tester.tap(find.text('2.0x'));
        await tester.pumpAndSettle();
        expect(video.value.playbackSpeed, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await video.dispose();
      },
    );
  }

  testWidgets(
    'video controls expose only permitted speeds and never allow scrubbing',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const previewFont = String.fromEnvironment('PLAYER_FONT_PATH');
      const previewIcons = String.fromEnvironment('PLAYER_ICONS_PATH');
      for (final entry in {
        'PreviewUI': previewFont,
        'MaterialIcons': previewIcons,
      }.entries) {
        if (entry.value.isEmpty) continue;
        await tester.runAsync(() async {
          final bytes = await File(entry.value).readAsBytes();
          await (FontLoader(
            entry.key,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        });
      }
      final video = TestVideo();
      var fullscreen = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: previewFont.isEmpty ? null : 'PreviewUI',
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const ValueKey('player-preview'),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LessonVideoPlayer(
                    controller: video,
                    title: 'Cài đặt môi trường phát triển',
                    loading: false,
                    error: null,
                    onBack: () {},
                    onRetry: () {},
                    onPlayPause: () async {},
                    onFullscreen: () => fullscreen++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNothing);
      expect(find.byTooltip('Tới 10 giây'), findsNothing);
      expect(find.byTooltip('Lùi 10 giây'), findsNothing);
      expect(find.text('03:24 / 12:00'), findsOneWidget);
      final next = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'Bài kế tiếp',
        ),
      );
      expect(next.onPressed, isNull);
      await tester.tap(find.byTooltip('Toàn màn hình'));
      expect(fullscreen, 1);
      await tester.tap(find.byTooltip('Tốc độ phát'));
      await tester.pumpAndSettle();
      expect(find.text('Bình thường · 1x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);
      expect(find.text('0.75x'), findsNothing);
      expect(find.text('1.25x'), findsNothing);
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(video.value.playbackSpeed, 1.5);
      expect(tester.takeException(), isNull);
      // Opt-in local visual QA; not a committed binary baseline.
      const output = String.fromEnvironment('PLAYER_PREVIEW_PATH');
      if (output.isNotEmpty) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('player-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(output).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
      await video.dispose();
    },
  );
}
