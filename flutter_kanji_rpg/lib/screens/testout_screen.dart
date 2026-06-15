import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../providers.dart';
import '../widgets/multiple_choice.dart';

/// One-shot challenge exam per DESIGN.md §3.1: pass and the level's items
/// are seeded as well-known FSRS cards (high stability), unlocking the
/// next level without grinding lessons.
class TestOutScreen extends ConsumerStatefulWidget {
  const TestOutScreen({super.key, this.level = 5, this.questionCount = 12});

  final int level;
  final int questionCount;

  /// Required fraction of correct answers.
  static const double passBar = 0.8;

  @override
  ConsumerState<TestOutScreen> createState() => _TestOutScreenState();
}

class _TestOutScreenState extends ConsumerState<TestOutScreen> {
  final _random = Random();

  List<KanjiEntry> _pool = [];
  List<KanjiEntry>? _questions;
  int _index = 0;
  int _correct = 0;
  bool _finished = false;
  int _seeded = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final level = await db.kanjiForLevel(widget.level);
    final sample = [...level]..shuffle(_random);
    setState(() {
      _pool = level;
      _questions = sample.take(widget.questionCount).toList();
    });
  }

  List<String> _options(String correct) {
    final distractors = <String>{};
    final candidates = [..._pool]..shuffle(_random);
    for (final k in candidates) {
      if (k.meaningList.isEmpty) continue;
      final v = k.meaningList.first;
      if (v != correct && distractors.length < 3) distractors.add(v);
    }
    return ([correct, ...distractors]..shuffle(_random));
  }

  bool get _passed =>
      _correct >= (widget.questionCount * TestOutScreen.passBar).ceil();

  Future<void> _answer(bool correct) async {
    if (correct) _correct++;
    if (_index + 1 < _questions!.length) {
      setState(() => _index++);
      return;
    }
    var seeded = 0;
    if (_passed) {
      final db = ref.read(databaseProvider);
      final srs = ref.read(srsRepositoryProvider);
      final learned = await db.learnedLiterals();
      for (final k in _pool.where((k) => !learned.contains(k.literal))) {
        await srs.seedKnown(k.literal);
        seeded++;
      }
      ref.invalidate(dueCountProvider);
    }
    if (!mounted) return;
    setState(() {
      _finished = true;
      _seeded = seeded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    return Scaffold(
      appBar: AppBar(
        title: Text(_finished
            ? 'Test-out N${widget.level}'
            : 'Test-out N${widget.level} — '
                '${questions == null ? '…' : '${_index + 1} / ${questions.length}'}'),
      ),
      body: questions == null
          ? const Center(child: CircularProgressIndicator())
          : _finished
              ? _resultView()
              : Center(
                  child: MultipleChoice(
                    key: ValueKey('exam-$_index'),
                    prompt: Column(
                      children: [
                        const Text('What does this mean?'),
                        Text(questions[_index].literal,
                            style: const TextStyle(fontSize: 80)),
                      ],
                    ),
                    options: _options(questions[_index].meaningList.first),
                    correct: questions[_index].meaningList.first,
                    onAnswered: _answer,
                  ),
                ),
    );
  }

  Widget _resultView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_passed ? Icons.emoji_events : Icons.cancel,
              color: _passed ? Colors.amber : Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            '$_correct / ${widget.questionCount} correct — '
            '${_passed ? 'passed!' : 'not passed'}',
            key: const Key('exam-result'),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          if (_passed)
            Text(_seeded == 0
                ? 'All N${widget.level} kanji were already known.'
                : '$_seeded kanji marked well-known '
                    '(reviews scheduled ~2 months out).'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to menu'),
          ),
        ],
      ),
    );
  }
}
