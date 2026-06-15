import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../battle/engine.dart' show BattleOutcome;
import '../battle/question_bank.dart' show BattleData, QuestionBank;
import '../providers.dart';
import '../world/quest_map.dart';
import '../world/world_map_game.dart';
import 'battle_screen.dart';
import 'lesson_screen.dart';
import 'npc_dialogue_screen.dart';

/// M4 — the world map (DESIGN.md §3.2). A Flame node map you walk with a
/// sprite; tapping a node opens its quest sheet and runs that node: a lesson,
/// an NPC talk, or an M3 battle. Clearing a node unlocks the next. Quest
/// content is authored in JSON (`assets/data/quests/`, §8) and loaded here;
/// the economy and replay ranks arrive in later M4 parts. Progress is
/// in-memory for now.
class WorldMapScreen extends ConsumerWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = ref.watch(quest1Provider);
    return quest.when(
      data: (map) => _WorldMapView(map: map),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('World Map (M4)')),
        body: Center(child: Text('Could not load the quest: $e')),
      ),
    );
  }
}

class _WorldMapView extends ConsumerStatefulWidget {
  const _WorldMapView({required this.map});

  final QuestMap map;

  @override
  ConsumerState<_WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends ConsumerState<_WorldMapView> {
  late final QuestProgress _progress;
  late final WorldMapGame _game;

  /// Dev escape hatch (same intent as the battle-setup toggle): act on a node
  /// before enough kanji are learned.
  bool _godMode = false;

  @override
  void initState() {
    super.initState();
    _progress = QuestProgress();
    _game = WorldMapGame(
      map: widget.map,
      progress: _progress,
      onNodeActivated: _onNodeActivated,
      onStep: _playStep,
    );
    _safeAudio(() => FlameAudio.bgm.play('map_theme.ogg', volume: 0.4));
  }

  @override
  void dispose() {
    _safeAudio(() => FlameAudio.bgm.stop());
    super.dispose();
  }

  // Audio is best-effort: a missing plugin (e.g. in tests) must never crash
  // the map.
  void _safeAudio(Future<Object?> Function() fn) {
    try {
      fn().then((_) {}, onError: (_, _) {});
    } catch (_) {/* plugin unavailable */}
  }

  void _playStep() => _safeAudio(() => FlameAudio.play('step.ogg', volume: 0.5));

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  void _markCleared(QuestNode node) {
    _progress.clear(node.id);
    _game.refresh();
  }

  Future<void> _onNodeActivated(QuestNode node) async {
    if (_progress.isCleared(node.id)) {
      _showSheet(node, const _ClearedBody());
      return;
    }
    switch (node.type) {
      case QuestNodeType.lesson:
        _showSheet(
          node,
          _ActionBody(
            blurb: 'Study the kanji, then their power is yours to wield.',
            label: 'Begin lesson',
            icon: Icons.menu_book,
            onPressed: () {
              Navigator.of(context).pop();
              _startLesson(node);
            },
          ),
        );
      case QuestNodeType.npc:
        _showSheet(
          node,
          _ActionBody(
            blurb: 'Someone waits with words for you.',
            label: 'Speak',
            icon: Icons.chat_bubble_outline,
            onPressed: () {
              Navigator.of(context).pop();
              _startNpc(node);
            },
          ),
        );
      case QuestNodeType.skirmish:
      case QuestNodeType.boss:
        _showSheet(
          node,
          _ActionBody(
            blurb: 'Ink-beasts bar the way. Answer true to drive them off.',
            label: 'Begin battle',
            icon: Icons.flash_on,
            onPressed: () {
              Navigator.of(context).pop();
              _startBattle(node);
            },
          ),
        );
      case QuestNodeType.dungeon:
        _showSheet(node, const _ComingSoonBody());
    }
  }

  Future<void> _startLesson(QuestNode node) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LessonScreen(lessonSize: node.lessonSize),
    ));
    if (!mounted) return;
    final learned = (await ref.read(databaseProvider).learnedLiterals()).length;
    if (!mounted) return;
    if (learned >= QuestionBank.minPoolSize) {
      _markCleared(node);
      _snack('The first words return to memory — now you can fight.');
    } else {
      _snack('Learn at least ${QuestionBank.minPoolSize} kanji to press on.');
    }
  }

  Future<void> _startNpc(QuestNode node) async {
    QuestionBank? bank;
    if (node.ask > 0) {
      final data =
          await BattleData.load(ref.read(databaseProvider), godMode: _godMode);
      if (!mounted) return;
      if (data.bank.usable) bank = data.bank;
    }
    final cleared = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => NpcDialogueScreen(node: node, bank: bank),
    ));
    if (!mounted) return;
    if (cleared == true) {
      _markCleared(node);
      _snack('言霊 restored — the path opens onward.');
    }
  }

  Future<void> _startBattle(QuestNode node) async {
    final data =
        await BattleData.load(ref.read(databaseProvider), godMode: _godMode);
    if (!mounted) return;
    if (!data.bank.usable) {
      _snack('Learn at least ${QuestionBank.minPoolSize} kanji first — '
          'or toggle god mode (dev).');
      return;
    }
    _safeAudio(() => FlameAudio.bgm.stop());
    final outcome = await Navigator.of(context).push<BattleOutcome>(
      MaterialPageRoute(
        builder: (_) => BattleScreen(formation: node.formation!, data: data),
      ),
    );
    if (!mounted) return;
    _safeAudio(() => FlameAudio.bgm.play('map_theme.ogg', volume: 0.4));
    if (outcome == BattleOutcome.victory) {
      _markCleared(node);
      _snack('言霊 restored — the path opens onward.');
    } else if (outcome == BattleOutcome.defeat) {
      _snack('The Forgetting holds this ground. Study and return.');
    }
  }

  void _showSheet(QuestNode node, Widget body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF231B2E),
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(node.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            if (node.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(node.subtitle,
                  style: const TextStyle(color: Colors.white60)),
            ],
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Map (M4)'),
        actions: [
          IconButton(
            key: const Key('worldmap-godmode'),
            tooltip: 'God mode (dev): act without enough learned kanji',
            color: _godMode ? Colors.amber : null,
            icon: Icon(
                _godMode ? Icons.auto_awesome : Icons.auto_awesome_outlined),
            onPressed: () => setState(() => _godMode = !_godMode),
          ),
        ],
      ),
      body: GameWidget(game: _game),
    );
  }
}

/// A quest-sheet body with a single call-to-action button.
class _ActionBody extends StatelessWidget {
  const _ActionBody({
    required this.blurb,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String blurb;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(blurb, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ],
    );
  }
}

class _ClearedBody extends StatelessWidget {
  const _ClearedBody();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.check_circle, color: Color(0xFF5FB05F)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Cleared. Replays at higher mastery ranks arrive in M4 Part 4.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Free-roam dungeons open in M4.5.',
      style: TextStyle(color: Colors.white70),
    );
  }
}
