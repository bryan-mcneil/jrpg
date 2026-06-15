import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../game/tags.dart';
import '../providers.dart';
import '../widgets/stroke_animation.dart';

/// Dev screen proving the seeded dictionary: browse kanji per JLPT level,
/// tap one for details + stroke-order animation.
class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  int _level = 5;
  late Future<List<KanjiEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = ref.read(databaseProvider).kanjiForLevel(_level);
  }

  void _setLevel(int level) {
    setState(() {
      _level = level;
      _entries = ref.read(databaseProvider).kanjiForLevel(level);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kanji Browser (M2)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 5, label: Text('N5')),
                ButtonSegment(value: 4, label: Text('N4')),
                ButtonSegment(value: 2, label: Text('N2–N3')),
                ButtonSegment(value: 1, label: Text('N1')),
              ],
              selected: {_level},
              onSelectionChanged: (s) => _setLevel(s.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<KanjiEntry>>(
              future: _entries,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('DB error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final k = list[i];
                    return ListTile(
                      leading: Text(k.literal,
                          style: const TextStyle(fontSize: 32)),
                      title: Text(k.meaningList.join(', '),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${k.strokeCount} strokes · ${k.onList.join(' ')} '
                          '${k.kunList.join(' ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: TagChip(k.tag),
                      onTap: () => _showDetail(k),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(KanjiEntry k) {
    final words = ref.read(databaseProvider).wordsWithKanji(k.literal);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KanjiStrokeAnimation(strokePaths: k.strokeList, size: 140),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${k.literal}  N${k.level}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(k.meaningList.join(', ')),
                      const SizedBox(height: 8),
                      Text('On: ${k.onList.join('、')}'),
                      Text('Kun: ${k.kunDisplayList.join('、')}'),
                      const SizedBox(height: 8),
                      TagChip(k.tag),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            FutureBuilder<List<VocabEntry>>(
              future: words,
              builder: (context, snapshot) {
                final list = snapshot.data;
                if (list == null) return const SizedBox(height: 24);
                if (list.isEmpty) return const Text('No common words yet.');
                return Column(
                  key: const Key('vocab-words'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final w in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${w.word}【${w.reading}】 '
                          '${w.glossList.take(2).join('; ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
