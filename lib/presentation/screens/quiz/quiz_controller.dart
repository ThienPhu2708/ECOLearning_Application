import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/repositories/quiz_repository.dart';

class QuizQuestion {
  final int index;
  final String text;
  final List<String> options;
  QuizQuestion(Map<String, dynamic> json)
    : index = JsonUtils.asInt(json['index']),
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
    if (expired && !_autoAttempted) {
      _autoAttempted = true;
      unawaited(submit());
    }
  }

  void choose(int question, int option) {
    if (submitting ||
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
    if (result != null || !dirty) return _queue;
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
      } finally {
        saving = false;
        _emit();
      }
    });
    return _queue;
  }

  Future<void> submit() async {
    if (submitting || result != null || _disposed) return;
    submitting = true;
    submitError = null;
    _emit();
    try {
      await _queue;
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
