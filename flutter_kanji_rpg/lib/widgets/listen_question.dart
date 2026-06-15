import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../battle/balance.dart';
import '../battle/question_bank.dart';

/// Speaks a Japanese word aloud. Injectable so tests (and future platforms or
/// pre-recorded Tatoeba audio) can swap the TTS engine out.
typedef SpeakerFn = Future<void> Function(String text);

/// Default speaker: the device's Japanese TTS voice (DESIGN.md §6 — the
/// listening-question fallback until Tatoeba recordings are sourced). The
/// future completes only when the utterance finishes, so the question's clock
/// can wait for it.
class TtsSpeaker {
  TtsSpeaker() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _prepared = false;

  Future<void> _prepare() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.45); // a touch slower than default — it's a quiz
    await _tts.awaitSpeakCompletion(true);
    _prepared = true;
  }

  Future<void> speak(String text) async {
    if (!_prepared) await _prepare();
    await _tts.stop(); // cut off a still-playing replay before the next one
    await _tts.speak(text);
  }

  Future<void> dispose() => _tts.stop();
}

/// Listen-and-translate (DESIGN.md §3.4): the word is *spoken*, not shown, and
/// the player taps its meaning. The clock does not start until the first
/// playback finishes — you are never timed against audio you haven't heard —
/// and a replay button lets you hear it again with the clock still running.
/// Same countdown + [onAnswered] contract as the other question cards, so a
/// volley can mix it freely.
class ListenQuestion extends StatefulWidget {
  const ListenQuestion({
    super.key,
    required this.question,
    required this.duration,
    required this.onAnswered,
    this.speaker,
    this.confused = false,
    this.fiftyFifty = false,
  });

  final BattleQuestion question;
  final Duration duration;

  /// [timeFrac] is the fraction of the timer left when answered (0 on
  /// timeout) — the speed-bonus input.
  final void Function(bool correct, double timeFrac) onAnswered;

  /// Injected for tests; null in production builds the device TTS speaker.
  final SpeakerFn? speaker;
  final bool confused;
  final bool fiftyFifty;

  @override
  State<ListenQuestion> createState() => _ListenQuestionState();
}

class _ListenQuestionState extends State<ListenQuestion>
    with SingleTickerProviderStateMixin {
  /// Safety net so a silent/unsupported TTS engine can't deadlock the clock.
  static const _maxAudioWait = Duration(seconds: 8);

  late final AnimationController _timer;
  late final SpeakerFn _speak;
  TtsSpeaker? _ownedTts;

  late List<String> _options;
  String? _chosen;
  bool _ready = false; // first playback finished → clock runs, options live
  bool _timedOut = false;
  bool _reshuffled = false;

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
    final injected = widget.speaker;
    if (injected == null) {
      _ownedTts = TtsSpeaker();
      _speak = _ownedTts!.speak;
    } else {
      _speak = injected;
    }
    _timer = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _timeout();
      });
    _begin();
  }

  @override
  void dispose() {
    _timer.dispose();
    _ownedTts?.dispose();
    super.dispose();
  }

  /// Play once, then release the clock and the answer buttons.
  Future<void> _begin() async {
    await _playOnce();
    if (!mounted) return;
    setState(() => _ready = true);
    _timer.forward();
  }

  Future<void> _playOnce() async {
    try {
      await _speak(widget.question.prompt).timeout(_maxAudioWait);
    } catch (_) {
      // Silent or unsupported TTS — proceed so the question is never a
      // deadlock. The player can still read the options and answer.
    }
  }

  /// Hearing it again does not pause or reset the clock — by now it's running.
  void _replay() {
    if (!_ready || _chosen != null || _timedOut) return;
    _playOnce();
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
    if (!_ready || _chosen != null || _timedOut) return;
    final frac = (1 - _timer.value).clamp(0.0, 1.0);
    _timer.stop();
    setState(() => _chosen = option);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onAnswered(option == widget.question.correct, frac);
  }

  Color? _optionColor(String option) {
    if (_chosen == null && !_timedOut) return null;
    if (option == widget.question.correct) return Colors.green.shade800;
    if (option == _chosen) return Colors.red.shade800;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (1 - _timer.value).clamp(0.0, 1.0);
    final answered = _chosen != null || _timedOut;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LinearProgressIndicator(
            // Full bar while the prompt is still playing — the clock hasn't
            // started yet.
            value: _ready ? timeLeft : 1,
            minHeight: 6,
            color: _ready && timeLeft < 0.25 ? Colors.redAccent : Colors.amber,
            backgroundColor: Colors.white12,
          ),
        ),
        const SizedBox(height: 12),
        // Same key the other cards use, so volley plumbing and the device test
        // find a question the same way regardless of mode.
        const Text('Listen and translate',
            key: Key('bq-format'), textAlign: TextAlign.center),
        // Invisible test seam: the meaning to tap. Offstage keeps it findable
        // but unpainted, so it never reveals the answer on screen.
        Offstage(
          child: Text(widget.question.correct, key: const Key('listen-answer')),
        ),
        const SizedBox(height: 8),
        Center(
          child: FilledButton.icon(
            key: const Key('listen-replay'),
            onPressed: _ready && !answered ? _replay : null,
            icon: const Icon(Icons.volume_up),
            label: Text(_ready ? 'Replay' : 'Listening…'),
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
              onPressed: _ready && !answered ? () => _choose(option) : null,
              child: Text(
                option,
                style: const TextStyle(fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
