import 'package:flutter/material.dart';

import '../battle/question_bank.dart';
import 'spell_canvas.dart';

/// The hardest reading-production question (DESIGN.md §3.4): instead of tapping
/// one of four kanji, the player is shown a reading and must *draw* the kanji
/// for it. Recognition reuses the same ML Kit ink pipeline as MAGIC casting —
/// recognition only, stroke order is never failed mid-battle (§4). Same
/// countdown + [onAnswered] contract as TimedQuestion / TypedAnswerQuestion, so
/// a volley can mix all three modes freely.
class DrawnAnswerQuestion extends StatefulWidget {
  const DrawnAnswerQuestion({
    super.key,
    required this.question,
    required this.duration,
    required this.onAnswered,
    this.recognizer,
  });

  final BattleQuestion question;
  final Duration duration;

  /// [timeFrac] is the fraction of the timer left when answered (0 on
  /// timeout) — the speed-bonus input.
  final void Function(bool correct, double timeFrac) onAnswered;

  /// Test seam forwarded to the embedded [SpellCanvas].
  final InkRecognizerFn? recognizer;

  @override
  State<DrawnAnswerQuestion> createState() => _DrawnAnswerQuestionState();
}

class _DrawnAnswerQuestionState extends State<DrawnAnswerQuestion>
    with SingleTickerProviderStateMixin {
  final _canvasKey = GlobalKey<SpellCanvasState>();
  late final AnimationController _timer;
  List<String> _candidates = const [];
  bool? _correct; // null until submitted/timed out

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _submit(timedOut: true);
      })
      ..forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  /// True when the recognizer offered the kanji the question wants.
  bool _matches(Iterable<String> candidates) =>
      candidates.any(widget.question.accepted.contains);

  void _onCandidates(List<String> candidates, Duration elapsed) {
    if (_correct != null) return;
    setState(() => _candidates = candidates);
    // Recognizing the right kanji *is* the answer — commit it immediately.
    if (_matches(candidates)) _submit();
  }

  Future<void> _submit({bool timedOut = false}) async {
    if (_correct != null) return;
    final frac = timedOut ? 0.0 : (1 - _timer.value).clamp(0.0, 1.0);
    _timer.stop();
    setState(() => _correct = !timedOut && _matches(_candidates));
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onAnswered(_correct!, frac);
  }

  void _clear() {
    _canvasKey.currentState?.clear();
    setState(() => _candidates = const []);
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (1 - _timer.value).clamp(0.0, 1.0);
    final answered = _correct != null;
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
        const SizedBox(height: 8),
        // Same keys the multiple-choice card uses, so volley plumbing and the
        // device test find a question the same way regardless of mode.
        const Text('Draw the kanji',
            key: Key('bq-format'), textAlign: TextAlign.center),
        Text(
          widget.question.prompt,
          key: const Key('bq-prompt'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 34),
        ),
        // Invisible test seam: the literal the player must draw. Offstage keeps
        // it in the tree (findable) but unpainted, so it never reveals the
        // answer on screen.
        Offstage(
          child: Text(widget.question.correct, key: const Key('drawn-answer')),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 220,
          child: SpellCanvas(
            key: _canvasKey,
            recognizer: widget.recognizer,
            enabled: !answered,
            onCandidates: _onCandidates,
          ),
        ),
        if (_correct == false)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'answer: ${widget.question.correct}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              key: const Key('drawn-clear'),
              onPressed: answered ? null : _clear,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('drawn-submit'),
              onPressed: answered ? null : () => _submit(),
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
