import 'balance.dart';
import 'elements.dart';
import 'items.dart';

/// What an enemy does on its turn. Scripts are fixed cycles so fights are
/// learnable (and tests deterministic).
enum EnemyActionKind {
  /// Timed question volley at the player; damage per wrong/slow answer.
  volley,

  /// Inflicts a status on the player, no questions.
  statusAttack,

  /// Announces next turn's big attack — the DEFEND window.
  telegraph,

  /// The telegraphed heavy volley.
  bigAttack,
}

class EnemyAction {
  const EnemyAction.volley(this.name, {required this.questions, required this.damagePerMiss})
      : kind = EnemyActionKind.volley,
        inflicts = null;

  const EnemyAction.status(this.name, this.inflicts)
      : kind = EnemyActionKind.statusAttack,
        questions = 0,
        damagePerMiss = 0;

  const EnemyAction.telegraph(this.name)
      : kind = EnemyActionKind.telegraph,
        inflicts = null,
        questions = 0,
        damagePerMiss = 0;

  const EnemyAction.big(this.name, {required this.questions, required this.damagePerMiss})
      : kind = EnemyActionKind.bigAttack,
        inflicts = null;

  final EnemyActionKind kind;
  final String name;
  final int questions;
  final int damagePerMiss;
  final StatusType? inflicts;
}

/// How a question is answered (DESIGN.md §3.4). The ladder is ordered by
/// difficulty so a floor and a per-kanji mastery bump combine by taking the
/// harder of the two: tap an option ([choice]), spell the reading out
/// ([typed], for kanji→reading), or draw the kanji freehand ([drawn], for
/// reading→kanji). Listen-and-translate is a question *format*
/// (QuestionFormat.listenToMeaning), not a mode — it taps a meaning, so it
/// stays [choice]. A kun+on spell-out rung would extend this enum.
enum QuestionMode { choice, typed, drawn }

class EnemySpec {
  const EnemySpec({
    required this.id,
    required this.name,
    required this.glyph,
    required this.element,
    required this.maxHp,
    required this.script,
    this.spritePath,
    this.statusImmunity,
    this.isBoss = false,
    this.questionFloor = QuestionMode.choice,
  });

  final String id;
  final String name;

  /// Placeholder battle sprite: a big kanji glyph (also the fallback when
  /// the Time Fantasy battler PNG isn't present in assets/art/).
  final String glyph;
  final BattleElement element;
  final int maxHp;
  final List<EnemyAction> script;
  final String? spritePath;

  /// Themed immunity (DESIGN.md §3.5): e.g. a 水 boss can't be Frozen.
  final StatusType? statusImmunity;
  final bool isBoss;

  /// Minimum question difficulty this enemy demands (DESIGN.md §3.4). Tougher
  /// foes — mini-bosses and bosses — raise this so their fights force typed
  /// answers even on kanji the player hasn't yet mastered.
  final QuestionMode questionFloor;
}

class Formation {
  const Formation({required this.id, required this.name, required this.enemies});

  final String id;
  final String name;
  final List<EnemySpec> enemies;
}

/// Mutable per-battle enemy state.
class EnemyState {
  EnemyState(this.spec) : hp = spec.maxHp;

  final EnemySpec spec;
  int hp;
  int scriptIndex = 0;
  final Map<StatusType, int> statuses = {}; // type → rounds left

  /// Set while a telegraphed big attack is charging.
  String? charging;

  bool get alive => hp > 0;
  bool hasStatus(StatusType s) => statuses.containsKey(s);

  EnemyAction get nextAction => spec.script[scriptIndex % spec.script.length];
}

class Barrier {
  Barrier(this.element) : roundsLeft = wardRounds;

  final BattleElement element;
  int roundsLeft;
}

class PlayerState {
  PlayerState({this.maxHp = playerMaxHp, Map<String, int>? items})
      : hp = maxHp,
        mp = playerMaxMp,
        sp = playerMaxSp,
        items = items ?? {...defaultItemLoadout};

  final int maxHp;
  int hp;
  int mp;
  int sp;
  final Map<StatusType, int> statuses = {};

  /// Usable items carried into battle: item id → count remaining (§3.8).
  final Map<String, int> items;
  bool get hasItems => items.values.any((c) => c > 0);

  /// Which command 封印 locked, while statuses[seal] is active.
  BattleCommand? sealedCommand;
  Barrier? barrier;
  int supportCharges = 0;

  /// Temporary +ATK from a 力/強-type boon spell: rounds remaining of the
  /// buff (DESIGN.md §3.7). The de-facto ATK stat until §9's stat tracks
  /// land, when this becomes a multiplier on the real stat.
  int atkBuffRounds = 0;

  /// Outgoing-damage multiplier this round (1.0 when no boon is active).
  double get atkBuffMult => atkBuffRounds > 0 ? 1 + boonAtkBonus : 1.0;

  bool get alive => hp > 0;
  bool hasStatus(StatusType s) => statuses.containsKey(s);
}

enum BattleCommand { attack, defend, support, magic, item }

/// The player-turn menu: each ally picks one of these (DESIGN.md §3.4).
const offenseCommands = [
  BattleCommand.attack,
  BattleCommand.magic,
  BattleCommand.item,
];

/// The NPC-turn reaction menu, chosen before the enemies act.
const reactionCommands = [
  BattleCommand.defend,
  BattleCommand.support,
  BattleCommand.item,
];

/// What 封印 may lock. ITEM is excluded on purpose: 封印 is a word-seal
/// (言霊封じ), and items are physical objects, not kotodama — so the bag
/// stays open even when a command is sealed.
const sealableCommands = [
  BattleCommand.attack,
  BattleCommand.defend,
  BattleCommand.support,
  BattleCommand.magic,
];

/// Outcome of one question volley, reported by the UI to the engine.
class VolleyResult {
  const VolleyResult(this.correct, this.total, {this.avgTimeFrac = 0});

  final int correct;
  final int total;

  /// Average fraction of the timer remaining on answers (0–1) — the speed
  /// bonus input.
  final double avgTimeFrac;

  int get misses => total - correct;
}

// --- M3 placeholder content -------------------------------------------------

/// 2-enemy skirmish: a wood beast and a metal beast, so fire spells teach
/// the matchup table (2× vs 金, neutral vs 木).
final skirmishFormation = Formation(
  id: 'skirmish',
  name: 'Ink Beasts',
  enemies: [
    const EnemySpec(
      id: 'kobold',
      name: 'インク小鬼',
      glyph: '鬼',
      element: BattleElement.wood,
      maxHp: 40,
      spritePath: 'assets/art/kobold1.png',
      script: [
        EnemyAction.volley('かみつき', questions: 2, damagePerMiss: 5),
        EnemyAction.volley('ひっかき', questions: 2, damagePerMiss: 5),
        EnemyAction.status('燃える毒牙', StatusType.burn),
      ],
    ),
    const EnemySpec(
      id: 'bat',
      name: 'インク蝙蝠',
      glyph: '蝠',
      element: BattleElement.metal,
      maxHp: 40,
      spritePath: 'assets/art/bat1.png',
      script: [
        EnemyAction.volley('超音波', questions: 2, damagePerMiss: 5),
        EnemyAction.status('惑わしの羽音', StatusType.confusion),
        EnemyAction.volley('急降下', questions: 2, damagePerMiss: 5),
      ],
    ),
  ],
);

/// The boss: a corrupted water guardian. Water overcomes fire, so 火 spells
/// land at 0.5× (the M3 verify gate) while 土 spells exploit its weakness.
final bossFormation = Formation(
  id: 'boss',
  name: '忘水の精',
  enemies: [
    const EnemySpec(
      id: 'water-sprite',
      name: '忘水の精',
      glyph: '水',
      element: BattleElement.water,
      maxHp: 150,
      spritePath: 'assets/art/elemental1.png',
      statusImmunity: StatusType.freeze,
      isBoss: true,
      // The final boss is the hardest fight (§3.4): reading recall must be
      // spelled out and kanji production must be *drawn*, not tapped,
      // regardless of how well the player knows the kanji.
      questionFloor: QuestionMode.drawn,
      script: [
        EnemyAction.volley('水撃', questions: 4, damagePerMiss: 6),
        EnemyAction.status('忘却の霧', StatusType.confusion),
        EnemyAction.telegraph('大水流'),
        EnemyAction.big('大水流', questions: 6, damagePerMiss: 9),
        EnemyAction.status('言霊封じ', StatusType.seal),
        EnemyAction.volley('水撃', questions: 4, damagePerMiss: 6),
        EnemyAction.telegraph('大水流'),
        EnemyAction.big('大水流', questions: 6, damagePerMiss: 9),
        EnemyAction.status('凍てつく波', StatusType.freeze),
      ],
    ),
  ],
);

/// 3-enemy swarm (DESIGN.md §3.4 — skirmishes field 1–3 enemies). Two flimsy
/// 金 needle-bugs flank a sturdier 木 vine: a 火 storm clears the metal adds at
/// ×2 (fire melts metal) while a 火 blade or ATTACK finishes the wood leader.
/// The fight teaches multi-target *shape* — storm for the swarm, blade for the
/// leader — so it complements the 2-enemy skirmish's matchup lesson.
final swarmFormation = Formation(
  id: 'swarm',
  name: 'インクの群れ',
  enemies: [
    const EnemySpec(
      id: 'needle-a',
      name: 'インク針',
      glyph: '針',
      element: BattleElement.metal,
      maxHp: 22,
      script: [
        EnemyAction.volley('刺突', questions: 1, damagePerMiss: 5),
        EnemyAction.volley('刺突', questions: 1, damagePerMiss: 5),
      ],
    ),
    const EnemySpec(
      id: 'needle-b',
      name: 'インク針',
      glyph: '針',
      element: BattleElement.metal,
      maxHp: 22,
      script: [
        EnemyAction.volley('刺突', questions: 1, damagePerMiss: 5),
        EnemyAction.status('目くらまし', StatusType.confusion),
      ],
    ),
    const EnemySpec(
      id: 'vine',
      name: 'インク蔦',
      glyph: '蔦',
      element: BattleElement.wood,
      maxHp: 48,
      script: [
        EnemyAction.volley('巻きつき', questions: 2, damagePerMiss: 5),
        EnemyAction.volley('締めつけ', questions: 2, damagePerMiss: 6),
        EnemyAction.status('胞子', StatusType.confusion),
      ],
    ),
  ],
);

/// A mini-boss sitting between the skirmish and the §3.9 boss: a 火 warden that
/// forces the *typed* answer rung (DESIGN.md §3.4 questionFloor) — reading
/// recall must be spelled out even on freshly-learned kanji — but never the
/// drawn rung (that is the final boss's alone; DEFEND caps at typed). Its 火
/// element means 水 spells hit it for ×2, and as a fire guardian it is immune
/// to 火傷 burn (§3.5 themed immunity).
final miniBossFormation = Formation(
  id: 'miniboss',
  name: '忘火の番人',
  enemies: [
    const EnemySpec(
      id: 'fire-warden',
      name: '忘火の番人',
      glyph: '火',
      element: BattleElement.fire,
      maxHp: 90,
      statusImmunity: StatusType.burn,
      questionFloor: QuestionMode.typed,
      script: [
        EnemyAction.volley('火の粉', questions: 3, damagePerMiss: 5),
        EnemyAction.telegraph('業火'),
        EnemyAction.big('業火', questions: 5, damagePerMiss: 8),
        EnemyAction.status('封じ火', StatusType.seal),
        EnemyAction.volley('火の粉', questions: 3, damagePerMiss: 5),
      ],
    ),
  ],
);

final formations = [
  skirmishFormation,
  swarmFormation,
  miniBossFormation,
  bossFormation,
];
