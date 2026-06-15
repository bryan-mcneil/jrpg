import 'dart:math';

import 'package:flutter/material.dart';

import '../battle/balance.dart';
import '../battle/models.dart';
import '../battle/question_bank.dart';
import 'drawn_answer.dart';
import 'listen_question.dart';
import 'spell_canvas.dart';
import 'typed_answer.dart';

/// One battle question on a countdown. Timeout counts as a miss; statuses
/// reach into the quiz itself (DESIGN.md §3.6): 混乱 reshuffles the options
/// midway, 凍結 changes [duration] via the engine's time factors, and the
/// pet's 50/50 hint trims two wrong options.
class TimedQuestion extends StatefulWidget {
  const TimedQuestion({
    super.key,
    required this.question,
    required this.duration,
    required this.onAnswered,
    this.confused = false,
    this.fiftyFifty = false,
  });

  final BattleQuestion question;
  final Duration duration;

  /// [timeFrac] is the fraction of the timer remaining when answered (0 on
  /// timeout) — the speed-bonus input.
  final void Function(bool correct, double timeFrac) onAnswered;
  final bool confused;
  final bool fiftyFifty;

  @override
  State<TimedQuestion> createState() => _TimedQuestionState();
}

class _TimedQuestionState extends State<TimedQuestion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  late List<String> _options;
  String? _chosen;
  bool _timedOut = false;
  bool _reshuffled = false;

  bool get _kanjiOptions =>
      widget.question.format == QuestionFormat.meaningToKanji ||
      widget.question.format == QuestionFormat.readingToKanji;

  @override
  void initState() {
    super.initState();
    _options = [...widget.question.options];
    if (widget.fiftyFifty) {
      final wrong = [..._options]
        ..remove(widget.question.correct)
        ..shuffle(Random());
      _options = [widget.question.correct, wrong.first]..shuffle(Random());
    }
    _timer = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _timeout();
      })
      ..forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _onTick() {
    if (widget.confused &&
        !_reshuffled &&
        _chosen == null &&
        _timer.value >= confusionReshuffleAt) {
      setState(() {
        _reshuffled = true;
        _options.shuffle(Random());
      });
    } else {
      setState(() {}); // drive the timer bar
    }
  }

  Future<void> _timeout() async {
    if (_chosen != null || _timedOut) return;
    setState(() => _timedOut = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onAnswered(false, 0);
  }

  Future<void> _choose(String option) async {
    if (_chosen != null || _timedOut) return;
    final frac = (1 - _timer.value).clamp(0.0, 1.0);
    _timer.stop();
    setState(() => _chosen = option);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      widget.onAnswered(option == widget.question.correct, frac);
    }
  }

  Color? _optionColor(String option) {
    if (_chosen == null && !_timedOut) return null;
    if (option == widget.question.correct) return Colors.green.shade800;
    if (option == _chosen) return Colors.red.shade800;
    return null;
  }

  String get _instruction => switch (widget.question.format) {
        QuestionFormat.kanjiToMeaning => 'What does this mean?',
        QuestionFormat.kanjiToReading => 'How is it read?',
        QuestionFormat.meaningToKanji => 'Pick the kanji for…',
        QuestionFormat.readingToKanji => 'Which kanji reads…',
        // Listen questions route to ListenQuestion, never here, but the switch
        // must stay exhaustive.
        QuestionFormat.listenToMeaning => 'Listen and translate',
      };

  @override
  Widget build(BuildContext context) {
    final timeLeft = (1 - _timer.value).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LinearProgressIndicator(
            value: timeLeft,
            minHeight: 6,
            color: timeLeft < 0.25 ? Colors.redAccent : Colors.amber,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 12),
        Text(_instruction,
            key: const Key('bq-format'), textAlign: TextAlign.center),
        // Word-form prompts (食べる) can outgrow the row at 64pt; scale down.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.question.prompt,
              key: const Key('bq-prompt'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _kanjiOptions ? 26 : 64),
            ),
          ),
        ),
        if (widget.confused)
          const Text('混乱 — the words swim…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFB57EDC), fontSize: 12)),
        if (_timedOut)
          const Text('Too slow!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 8),
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: _optionColor(option),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => _choose(option),
              child: Text(
                option,
                style: TextStyle(fontSize: _kanjiOptions ? 28 : 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

/// Runs a volley of [questions] back to back and reports the summed
/// [VolleyOutcome] — the bridge between the quiz UI and the engine's
/// VolleyResult.
class VolleyRunner extends StatefulWidget {
  const VolleyRunner({
    super.key,
    required this.questions,
    required this.questionDuration,
    required this.onDone,
    this.confused = false,
    this.consumeFiftyFifty,
    this.banner,
    this.recognizer,
    this.speaker,
  });

  final List<BattleQuestion> questions;
  final Duration questionDuration;
  final void Function(int correct, double avgTimeFrac) onDone;
  final bool confused;

  /// Returns true when a support charge is available for this question.
  final bool Function()? consumeFiftyFifty;
  final Widget? banner;

  /// Test seam forwarded to the ink canvas of any drawn questions.
  final InkRecognizerFn? recognizer;

  /// Test seam forwarded to the speaker of any listen-and-translate questions.
  final SpeakerFn? speaker;

  @override
  State<VolleyRunner> createState() => _VolleyRunnerState();
}

class _VolleyRunnerState extends State<VolleyRunner> {
  int _index = 0;
  int _correct = 0;
  double _fracSum = 0;
  bool _fiftyFifty = false;

  @override
  void initState() {
    super.initState();
    _prepareCurrent();
  }

  /// A 50/50 hint can only trim multiple-choice options, so it's only drawn
  /// (and a support charge only spent) when the current question is a tap one.
  void _prepareCurrent() {
    _fiftyFifty = widget.questions[_index].mode == QuestionMode.choice
        ? (widget.consumeFiftyFifty?.call() ?? false)
        : false;
  }

  void _answered(bool correct, double frac) {
    if (correct) _correct++;
    _fracSum += frac;
    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _prepareCurrent();
      });
    } else {
      widget.onDone(_correct, _fracSum / widget.questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_index];
    final listen = question.format == QuestionFormat.listenToMeaning;
    // Each rung up the difficulty ladder takes longer to answer, so it gets a
    // bigger slice of the clock (tap < type < draw); listen-and-translate gets
    // its own factor (the clock only starts once the audio has played).
    final duration = listen
        ? widget.questionDuration * listenQuestionTimeFactor
        : switch (question.mode) {
            QuestionMode.choice => widget.questionDuration,
            QuestionMode.typed =>
              widget.questionDuration * typedQuestionTimeFactor,
            QuestionMode.drawn =>
              widget.questionDuration * drawnQuestionTimeFactor,
          };
    final key = ValueKey('volley-q$_index');
    final card = listen
        ? ListenQuestion(
            key: key,
            question: question,
            duration: duration,
            speaker: widget.speaker,
            confused: widget.confused,
            fiftyFifty: _fiftyFifty,
            onAnswered: _answered,
          )
        : switch (question.mode) {
            QuestionMode.typed => TypedAnswerQuestion(
                key: key,
                question: question,
                duration: duration,
                onAnswered: _answered,
              ),
            QuestionMode.drawn => DrawnAnswerQuestion(
                key: key,
                question: question,
                duration: duration,
                recognizer: widget.recognizer,
                onAnswered: _answered,
              ),
            QuestionMode.choice => TimedQuestion(
                key: key,
                question: question,
                duration: duration,
                confused: widget.confused,
                fiftyFifty: _fiftyFifty,
                onAnswered: _answered,
              ),
          };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.banner != null) widget.banner!,
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            'Question ${_index + 1} / ${widget.questions.length}'
            '${_fiftyFifty ? '  ·  word-sprite whispers (50/50)' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        card,
      ],
    );
  }
}
