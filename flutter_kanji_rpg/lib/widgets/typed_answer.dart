import 'package:flutter/material.dart';

import '../battle/question_bank.dart';
import '../util/romaji.dart';

/// The harder reading question (DESIGN.md §3.4): instead of tapping one of
/// four options, the player spells the reading out. They can type kana
/// directly with a Japanese IME, or type romaji and watch it convert live.
/// Same countdown + [onAnswered] contract as the multiple-choice
/// `TimedQuestion`, so a volley can mix the two freely.
class TypedAnswerQuestion extends StatefulWidget {
  const TypedAnswerQuestion({
    super.key,
    required this.question,
    required this.duration,
    required this.onAnswered,
  });

  final BattleQuestion question;
  final Duration duration;

  /// [timeFrac] is the fraction of the timer left when answered (0 on
  /// timeout) — the speed-bonus input.
  final void Function(bool correct, double timeFrac) onAnswered;

  @override
  State<TypedAnswerQuestion> createState() => _TypedAnswerQuestionState();
}

class _TypedAnswerQuestionState extends State<TypedAnswerQuestion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  final _controller = TextEditingController();
  bool? _correct; // null until submitted/timed out

  /// The romaji-converted reading the player has typed so far.
  String get _kana => romajiToHiragana(_controller.text);

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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit({bool timedOut = false}) async {
    if (_correct != null) return;
    final frac = timedOut ? 0.0 : (1 - _timer.value).clamp(0.0, 1.0);
    _timer.stop();
    final answer = _kana.trim();
    setState(() =>
        _correct = !timedOut && widget.question.accepted.contains(answer));
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onAnswered(_correct!, frac);
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (1 - _timer.value).clamp(0.0, 1.0);
    final answered = _correct != null;
    final fieldColor = _correct == null
        ? null
        : (_correct! ? Colors.green.shade800 : Colors.red.shade900);
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
        // Same key the multiple-choice card uses, so volley plumbing and the
        // device test find a question the same way regardless of mode.
        const Text('How is it read?',
            key: Key('bq-format'), textAlign: TextAlign.center),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.question.prompt,
              key: const Key('bq-prompt'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 64),
            ),
          ),
        ),
        const Text('Spell out the reading',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            key: const Key('typed-field'),
            controller: _controller,
            enabled: !answered,
            autofocus: true,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 24, letterSpacing: 2),
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldColor ?? const Color(0xFF241B2F),
              border: const OutlineInputBorder(),
              hintText: 'かな',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        // Live romaji→kana echo so romaji typists see what they're committing.
        const SizedBox(height: 6),
        Text(
          _kana.isEmpty ? '　' : '→ $_kana',
          key: const Key('typed-preview'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Color(0xFFB57EDC)),
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FilledButton(
            key: const Key('typed-submit'),
            onPressed: answered ? null : () => _submit(),
            child: const Text('Answer'),
          ),
        ),
      ],
    );
  }
}
