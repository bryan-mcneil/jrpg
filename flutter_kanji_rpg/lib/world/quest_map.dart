import '../battle/models.dart';

/// Node kinds on the Super Mario World-style world map (DESIGN.md §3.2).
/// Part 2 wires [lesson] (the M2 lesson flow), [npc] (dialogue + pick/type
/// review responses) and the battle kinds; [dungeon] opens its real screen in
/// M4.5.
enum QuestNodeType { lesson, npc, skirmish, dungeon, boss }

/// How an [QuestNodeType.npc] node poses its review "responses" (§3.2 reading &
/// writing practice): [pick] taps a meaning/reading, [type] spells the reading.
enum NpcAskMode { pick, type }

/// One line of NPC dialogue. [jp] is the Japanese; [en] an optional gloss shown
/// beneath it (quest dialogue stays bilingual — the §3.3 Japanese-only fade is
/// a dungeon-replay mechanic, not a quest one).
class DialogueLine {
  const DialogueLine({this.speaker, required this.jp, this.en});

  final String? speaker;
  final String jp;
  final String? en;
}

/// One node on a quest's node map. Coordinates are *fractions* of the map area
/// (0..1), so the Flame layer can place them at any resolution; the model stays
/// free of Flame/engine types and is unit-testable on its own.
class QuestNode {
  const QuestNode({
    required this.id,
    required this.title,
    required this.type,
    required this.x,
    required this.y,
    this.subtitle = '',
    this.formationId,
    this.lessonSize = 0,
    this.dialogue = const [],
    this.ask = 0,
    this.askMode = NpcAskMode.pick,
    this.requires = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final QuestNodeType type;

  /// Map-space position as a fraction of the playfield (0..1, top-left origin).
  final double x;
  final double y;

  /// Battle nodes ([skirmish]/[boss]): the [Formation] id to fight. Resolved
  /// against [formations] by [formation].
  final String? formationId;

  /// [lesson] nodes: how many new kanji the M2 lesson flow teaches here.
  final int lessonSize;

  /// [npc] nodes: the authored dialogue lines.
  final List<DialogueLine> dialogue;

  /// [npc] nodes: how many review questions are posed as dialogue responses
  /// (drawn from the player's learned pool — disguised review, §3.2). 0 = a
  /// pure story beat.
  final int ask;

  /// [npc] nodes: whether those responses are tapped or typed.
  final NpcAskMode askMode;

  /// Ids of nodes that must be cleared before this one unlocks. The first node
  /// of a quest has none and is always available.
  final List<String> requires;

  bool get isBattle =>
      type == QuestNodeType.skirmish || type == QuestNodeType.boss;

  /// The [Formation] this node fights, or null for non-battle nodes.
  Formation? get formation => formationId == null
      ? null
      : formations.firstWhere((f) => f.id == formationId);
}

/// A quest chapter: an ordered graph of nodes the player clears one by one
/// (1.1 → 1.2 → … → 1.boss), drawn as a path map.
class QuestMap {
  const QuestMap({required this.id, required this.title, required this.nodes});

  final String id;
  final String title;
  final List<QuestNode> nodes;

  QuestNode nodeById(String id) => nodes.firstWhere((n) => n.id == id);

  /// Undirected path segments to draw, one per `requires` link (predecessor →
  /// successor), de-duplicated.
  List<(QuestNode, QuestNode)> edges() {
    final out = <(QuestNode, QuestNode)>[];
    for (final n in nodes) {
      for (final reqId in n.requires) {
        out.add((nodeById(reqId), n));
      }
    }
    return out;
  }
}

/// Per-player progress through a [QuestMap] — which nodes are cleared. Pure
/// value object; persistence (Drift) lands with the M4 economy part.
class QuestProgress {
  QuestProgress([Iterable<String> cleared = const []])
      : cleared = {...cleared};

  final Set<String> cleared;

  bool isCleared(String id) => cleared.contains(id);

  /// A node is available to enter once every prerequisite is cleared.
  bool isUnlocked(QuestNode node) => node.requires.every(cleared.contains);

  /// Unlocked but not yet cleared — the nodes the avatar can act on now.
  bool isAvailable(QuestNode node) =>
      isUnlocked(node) && !isCleared(node.id);

  void clear(String id) => cleared.add(id);

  /// True once every node in [map] is cleared.
  bool isComplete(QuestMap map) => map.nodes.every((n) => isCleared(n.id));
}
