import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' show Rating;

import '../db/database.dart';
import '../providers.dart';
import '../widgets/multiple_choice.dart';

/// FSRS review queue: every due card gets a meaning question; correct =
/// Good, wrong = Again. (Battle formats arrive in M3 — this is the plain
/// study queue.)
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _random = Random();

  List<KanjiEntry>? _queue;
  List<KanjiEntry> _pool = [];
  int _index = 0;
  int _correct = 0;
  String? _lastOutcome;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final due = await db.dueCards(DateTime.now());
    final entries = [
      for (final card in due) await db.kanjiByLiteral(card.literal),
    ];
    final pool = await db.kanjiForLevel(5);
    setState(() {
      _queue = entries;
      _pool = pool;
    });
  }

  /// [avoid] holds every valid meaning of the quizzed kanji — a distractor
  /// that is also correct would mark the player wrong for being right.
  List<String> _options(String correct, {Set<String> avoid = const {}}) {
    final distractors = <String>{};
    final candidates = [..._pool]..shuffle(_random);
    for (final k in candidates) {
      if (k.meaningList.isEmpty) continue;
      final v = k.meaningList.first;
      if (v != correct && !avoid.contains(v) && distractors.length < 3) {
        distractors.add(v);
      }
    }
    return ([correct, ...distractors]..shuffle(_random));
  }

  Future<void> _answer(KanjiEntry k, bool correct) async {
    final srs = ref.read(srsRepositoryProvider);
    final nextDue =
        await srs.review(k.literal, correct ? Rating.good : Rating.again);
    ref.invalidate(dueCountProvider);
    if (!mounted) return;
    final wait = nextDue.difference(DateTime.now().toUtc());
    final waitLabel = wait.inDays >= 1
        ? 'in ${wait.inDays} d'
        : wait.inHours >= 1
            ? 'in ${wait.inHours} h'
            : 'in ${max(wait.inMinutes, 1)} min';
    setState(() {
      if (correct) _correct++;
      _lastOutcome = correct
          ? '${k.literal} ✓ — next review $waitLabel'
          : '${k.literal} ✗ — again $waitLabel';
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue;
    final remaining = queue == null ? 0 : queue.length - _index;
    return Scaffold(
      appBar: AppBar(title: Text('Reviews (M2) — $remaining left')),
      body: queue == null
          ? const Center(child: CircularProgressIndicator())
          : _index >= queue.length
              ? _doneView(queue.length)
              : Column(
                  children: [
                    if (_lastOutcome != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_lastOutcome!,
                            key: const Key('review-outcome'),
                            textAlign: TextAlign.center),
                      ),
                    Expanded(
                      child: Center(
                        child: MultipleChoice(
                          key: ValueKey('rev-${queue[_index].literal}-$_index'),
                          prompt: Column(
                            children: [
                              const Text('What does this mean?'),
                              Text(queue[_index].literal,
                                  style: const TextStyle(fontSize: 80)),
                            ],
                          ),
                          options: _options(queue[_index].meaningList.first,
                              avoid: queue[_index].meaningList.toSet()),
                          correct: queue[_index].meaningList.first,
                          onAnswered: (c) => _answer(queue[_index], c),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _doneView(int total) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(total == 0 ? Icons.inbox : Icons.check_circle,
              color: Colors.greenAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            total == 0
                ? 'Queue clear — nothing due right now.'
                : 'Done! $_correct / $total correct.',
            key: const Key('review-done'),
            style: const TextStyle(fontSize: 20),
          ),
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
