import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' show Rating;

import '../db/database.dart';
import '../game/tags.dart';
import '../providers.dart';
import '../widgets/multiple_choice.dart';
import '../widgets/stroke_animation.dart';
import '../widgets/trace_canvas.dart';

/// Lesson flow per DESIGN.md §3.1: meaning + readings → stroke animation →
/// guided tracing → quiz. Completing an item creates its FSRS card and
/// applies the quiz result as the first review.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, this.lessonSize = 5});

  final int lessonSize;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

enum _Phase { info, trace, meaningQuiz, readingQuiz }

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _random = Random();

  List<KanjiEntry>? _items;
  List<KanjiEntry> _pool = []; // distractor source
  Map<String, List<VocabEntry>> _words = {}; // example words per item
  int _index = 0;
  _Phase _phase = _Phase.info;
  String _traceStatus = '';
  bool _meaningCorrect = true;
  bool _done = false;

  KanjiEntry get _current => _items![_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final level = await db.kanjiForLevel(5);
    final learned = await db.learnedLiterals();
    final unlearned =
        level.where((k) => !learned.contains(k.literal)).toList();
    final items = unlearned.take(widget.lessonSize).toList();
    final words = {
      for (final k in items)
        k.literal: await db.wordsWithKanji(k.literal, limit: 3),
    };
    setState(() {
      _pool = level;
      _items = items;
      _words = words;
      _done = unlearned.isEmpty;
    });
  }

  /// [avoid] holds every valid answer for the quizzed kanji — a distractor
  /// that is also correct would mark the player wrong for being right.
  List<String> _options(String correct, List<String> Function(KanjiEntry) f,
      {Set<String> avoid = const {}}) {
    final distractors = <String>{};
    final candidates = [..._pool]..shuffle(_random);
    for (final k in candidates) {
      final values = f(k);
      if (values.isEmpty) continue;
      final v = values.first;
      if (v != correct && !avoid.contains(v) && distractors.length < 3) {
        distractors.add(v);
      }
    }
    return ([correct, ...distractors]..shuffle(_random));
  }

  Future<void> _finishItem(bool readingCorrect) async {
    final srs = ref.read(srsRepositoryProvider);
    final rating =
        _meaningCorrect && readingCorrect ? Rating.good : Rating.again;
    await srs.learn(_current.literal);
    await srs.review(_current.literal, rating);
    ref.invalidate(dueCountProvider);
    if (!mounted) return;
    setState(() {
      if (_index + 1 < _items!.length) {
        _index++;
        _phase = _Phase.info;
        _traceStatus = '';
      } else {
        _done = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text(items == null || _done
            ? 'Lesson (M2)'
            : 'Lesson ${_index + 1} / ${items.length} — ${_current.literal}'),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : _done
              ? _completedView()
              : switch (_phase) {
                  _Phase.info => _infoView(),
                  _Phase.trace => _traceView(),
                  _Phase.meaningQuiz => _meaningQuizView(),
                  _Phase.readingQuiz => _readingQuizView(),
                },
    );
  }

  Widget _completedView() {
    final learnedNow = _items?.length ?? 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            learnedNow == 0
                ? 'All N5 kanji already learned!'
                : 'Lesson complete — $learnedNow kanji learned!',
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text('First reviews are due in minutes — check the queue.'),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('lesson-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to menu'),
          ),
        ],
      ),
    );
  }

  Widget _infoView() {
    final k = _current;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(k.literal, style: const TextStyle(fontSize: 96)),
                  Text(k.meaningList.join(', '),
                      style: const TextStyle(fontSize: 22),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  if (k.onList.isNotEmpty) Text('On: ${k.onList.join('、')}'),
                  if (k.kunList.isNotEmpty)
                    Text('Kun: ${k.kunDisplayList.join('、')}',
                        textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TagChip(k.tag),
                      const SizedBox(width: 8),
                      Chip(label: Text('${k.strokeCount} strokes')),
                    ],
                  ),
                  if (_words[k.literal]?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    for (final w in _words[k.literal]!)
                      Text(
                        '${w.word}【${w.reading}】 ${w.glossList.first}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                  const SizedBox(height: 16),
                  KanjiStrokeAnimation(strokePaths: k.strokeList, size: 180),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('lesson-next'),
            onPressed: () => setState(() {
              _phase = _Phase.trace;
              _traceStatus = 'Trace stroke 1 of ${k.strokeCount} — '
                  'start at the green dot';
            }),
            child: const Text('Trace it'),
          ),
        ],
      ),
    );
  }

  Widget _traceView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_traceStatus,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TraceCanvas(
                key: ValueKey('trace-${_current.literal}'),
                strokePaths: _current.strokeList,
                onStrokeResult: (accepted, message) =>
                    setState(() => _traceStatus = message),
                onCompleted: () async {
                  await Future.delayed(const Duration(milliseconds: 700));
                  if (mounted) {
                    setState(() => _phase = _Phase.meaningQuiz);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _meaningQuizView() {
    final k = _current;
    return Center(
      child: MultipleChoice(
        key: ValueKey('mq-${k.literal}'),
        prompt: Column(
          children: [
            const Text('What does this mean?'),
            Text(k.literal, style: const TextStyle(fontSize: 80)),
          ],
        ),
        options: _options(k.meaningList.first, (e) => e.meaningList,
            avoid: k.meaningList.toSet()),
        correct: k.meaningList.first,
        onAnswered: (correct) => setState(() {
          _meaningCorrect = correct;
          _phase = _Phase.readingQuiz;
        }),
      ),
    );
  }

  Widget _readingQuizView() {
    final k = _current;
    // Canonical reading: first on-reading, else first kun. Okurigana kun
    // readings show as the word the player will meet (食べる → たべる).
    final form = k.readingForms.first;
    final correct = form.reading;
    return Center(
      child: MultipleChoice(
        key: ValueKey('rq-${k.literal}'),
        prompt: Column(
          children: [
            const Text('How is it read?'),
            Text(form.wordForm(k.literal),
                style: const TextStyle(fontSize: 80)),
          ],
        ),
        options: _options(correct, (e) => [...e.onList, ...e.kunList],
            avoid: {...k.onList, ...k.kunList}),
        correct: correct,
        onAnswered: _finishItem,
      ),
    );
  }
}
