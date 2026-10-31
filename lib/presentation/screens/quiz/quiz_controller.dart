import 'dart:math';
import '../../../core/network/api_exception.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';

class QuizQuestion {
  final int index;
  final int id;
  final String text;
  final List<String> options;
  QuizQuestion(Map<String, dynamic> json)
    : index = JsonUtils.asInt(json['index']),
      id = JsonUtils.asInt(json['questionId']),
      text = JsonUtils.asString(json['text']),
      options = JsonUtils.asStringList(json['options']);
}

class QuizController extends ChangeNotifier {
  QuizController(
    this.repository,
    Map<String, dynamic> attempt, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    attemptId = JsonUtils.asInt(attempt['attemptId']);
    supportsReview = JsonUtils.asBool(attempt['supportsQuizReview']);
    departures = JsonUtils.asInt(attempt['departureCount']);
    _awayKey = JsonUtils.asStringOrNull(attempt['openDepartureKey']);
    expiresAt = DateTime.tryParse(JsonUtils.asString(attempt['expiresAt']));
    questions = JsonUtils.asMapList(
      attempt['questions'],
    ).map(QuizQuestion.new).toList();
    final raw = JsonUtils.asList(attempt['answers']);
    answers = List.generate(questions.length, (i) {
      final value = i < raw.length ? JsonUtils.asInt(raw[i], fallback: -1) : -1;
      return value >= 0 && value < questions[i].options.length ? value : -1;
    });
    if (attemptId <= 0 ||
        expiresAt == null ||
        questions.isEmpty ||
        questions.any((q) => q.text.isEmpty || q.options.length != 4)) {
      throw const FormatException(
        'Không tải được nội dung bài quiz. Vui lòng quay lại và thử tiếp tục bài.',
      );
    }
  }
  bool supportsReview = false;
  int departures = 0;
  Object? visibilityError;
  String? _awayKey;
  final _visibilityEvents = <({String key, bool returned})>[];
  Future<void> _visibilityQueue = Future.value();
  bool _checkingWriter = false;
  int _ticks = 0;
  String _newKey() => List.generate(
    32,
    (_) => Random.secure().nextInt(16).toRadixString(16),
  ).join();
  void depart() {
    if (!supportsReview ||
        _disposed ||
        result != null ||
        expired ||
        sessionLost ||
        _awayKey != null) {
      return;
    }
    _awayKey = _newKey();
    _visibilityEvents.add((key: _awayKey!, returned: false));
    unawaited(flushVisibility());
  }

  void resume() {
    if (_awayKey != null) {
      _visibilityEvents.add((key: _awayKey!, returned: true));
      _awayKey = null;
      unawaited(flushVisibility());
    }
    unawaited(checkSession());
    tick();
  }

  Future<void> flushVisibility() {
    _visibilityQueue = _visibilityQueue.then((_) async {
      while (_visibilityEvents.isNotEmpty && !_disposed) {
        final event = _visibilityEvents.first;
        try {
          departures = await repository.visibility(
            attemptId,
            event.key,
            returned: event.returned,
          );
          _visibilityEvents.removeAt(0);
          visibilityError = null;
        } catch (error) {
          visibilityError = error;
          if (error is ApiException && error.code == 'QUIZ_SESSION_ACTIVE') {
            sessionLost = true;
          }
          _emit();
          return;
        }
      }
      _emit();
    });
    return _visibilityQueue;
  }

  Future<void> checkSession() async {
    if (!supportsReview ||
        _checkingWriter ||
        _disposed ||
        result != null ||
        sessionLost ||
        expired) {
      return;
    }
    _checkingWriter = true;
    try {
      final state = await repository.checkWriter(attemptId);
      if (_disposed) return;
      if (JsonUtils.asBool(state['finished'])) {
        await submit();
      } else if (!JsonUtils.asBool(state['active'])) {
        sessionLost = true;
      }
    } on ApiException catch (error) {
      if (error.code == 'QUIZ_SESSION_ACTIVE') sessionLost = true;
    } finally {
      _checkingWriter = false;
      _emit();
    }
  }

  final QuizRepository repository;
  final DateTime Function() _now;
  late final int attemptId;
  late final DateTime? expiresAt;
  late final List<QuizQuestion> questions;
  late final List<int> answers;
  Object? draftError;
  Object? submitError;
  Map<String, dynamic>? result;
  bool submitting = false;
  bool saving = false;
  bool sessionLost = false;
  bool _disposed = false;
  bool _autoAttempted = false;
  int _revision = 0;
  int _savedRevision = 0;
  Future<void> _queue = Future.value();
  Timer? _timer;
  int get answered => answers.where((a) => a >= 0).length;
  int get secondsLeft => expiresAt == null
      ? 0
      : expiresAt!.difference(_now()).inSeconds.clamp(0, 86400 * 365);
  bool get expired => expiresAt == null || !expiresAt!.isAfter(_now());
  bool get dirty => _savedRevision != _revision;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void startTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
    tick();
  }

  void tick() {
    if (_disposed || result != null) return;
    _emit();
    if (++_ticks % 5 == 0) unawaited(checkSession());
    if (expired && !_autoAttempted) {
      _autoAttempted = true;
      unawaited(submit());
    }
  }

  void choose(int question, int option) {
    if (sessionLost ||
        submitting ||
        result != null ||
        expired ||
        question < 0 ||
        question >= questions.length ||
        option < 0 ||
        option >= questions[question].options.length ||
        answers[question] == option) {
      return;
    }
    answers[question] = option;
    _revision++;
    _emit();
    unawaited(saveDraft());
  }

  Future<void> saveDraft() {
    if (sessionLost || result != null || !dirty) return _queue;
    final snapshot = List<int>.of(answers);
    final revision = _revision;
    _queue = _queue.then((_) async {
      if (result != null || revision <= _savedRevision) return;
      saving = true;
      _emit();
      try {
        final saved = await repository.saveDraft(attemptId, snapshot);
        if (saved) {
          _savedRevision = revision;
          draftError = null;
        } else {
          _autoAttempted = true;
          unawaited(submit());
        }
      } catch (e) {
        draftError = e;
        if (e is ApiException && e.code == 'QUIZ_SESSION_ACTIVE') {
          sessionLost = true;
        }
      } finally {
        saving = false;
        _emit();
      }
    });
    return _queue;
  }

  Future<void> submit() async {
    if (submitting || sessionLost || result != null || _disposed) return;
    submitting = true;
    submitError = null;
    _emit();
    try {
      await _queue;
      if (supportsReview) {
        await flushVisibility();
        if (visibilityError != null) throw visibilityError!;
      }
      final response = await repository.submit(
        attemptId,
        List<int>.of(answers),
      );
      if (_disposed) return;
      result = response;
      _timer?.cancel();
    } catch (e) {
      if (!_disposed) submitError = e;
    } finally {
      submitting = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
