/// Every tunable number in the M3 battle slice lives here so balancing
/// passes (DESIGN.md §8 — "playtest M3 hard") touch one file.
library;

// Player baseline (placeholder stats until the M4 KP economy).
const int playerMaxHp = 100;
const int playerMaxMp = 30;
const int playerMaxSp = 10;
const int mpRegenPerRound = 2;
const int spRegenPerRound = 1;

// ATTACK — 5 kanji questions; damage = hits × per-hit power.
const int attackQuestionCount = 5;
const int attackPerHit = 6;
const double attackComboMult = 1.25; // 5/5 bonus
const double attackSpeedBonusMax = 0.25; // scaled by avg time remaining
const double burnAttackPenalty = 0.8; // burned player hits softer

// DEFEND — 5 reverse questions; each correct shaves damage this round.
const int defendQuestionCount = 5;
const double defendMitigationPerHit = 0.18; // 5/5 → only 10% gets through

// SUPPORT — the equipped pet's hint engine.
const int supportSpCost = 4;
const int supportCharges = 10; // questions buffed per cast

// MAGIC — power = base × strokeMult × grade × matchup × shape.
const double spellBasePower = 10;
const int strokeMultFloorStrokes = 4; // ≤4 strokes → ×1.0
const int strokeMultCeilStrokes = 16; // ≥16 strokes → ×2.0 (cap, §8)
const double strokeMultMax = 2.0;
const double stormShape = 0.7; // per enemy, hits all
const double bladeShape = 1.5; // single target burst
const double ampShape = 2.0; // and doubles MP cost
const double orbShape = 0.6; // damage rider on the status
const double mendShape = 0.8; // heal factor
const double wardFactor = 0.5; // barrier keeps 50% of damage out
const int wardRounds = 3;

// 力/強/上-type *boon* (buff): empowers the party's outgoing damage for a
// few rounds — a temporary +ATK (the first of the §3.8/§9 stats). Pure
// support: a boon spell deals no damage and needs no target.
const double boonAtkBonus = 0.5; // +50% outgoing damage → ×1.5
const int boonRounds = 3; // temporary stat lasts this many battle rounds

// Usable items (§3.8) — placeholder magnitudes until the M4 economy. The
// 力の薬 reuses the boon buff (boonRounds / boonAtkBonus).
const int itemHealHp = 40;
const int itemHealMp = 15;
const int itemHealSp = 6;
const double generatingBoost = 1.25; // barrier element generates spell element
const int spellMpBase = 2; // mpCost = base + ceil(strokes / 2), amp ×2

// Drawing grade (recognition rank + speed) bounds.
const double gradeMin = 0.8;
const double gradeMax = 1.2;
const double gradeTopCandidateBonus = 0.1;
const double gradeFastDrawBonus = 0.1;
const Duration gradeFastDrawLimit = Duration(seconds: 4);

// Statuses.
const int statusRounds = 3;
const int burnDotDamage = 4;
const double freezePlayerTimeFactor = 0.7; // player timers run faster
const double freezeEnemyTimeFactor = 1.3; // frozen enemy volleys arrive slower
const double confusionFizzleChance = 0.35; // confused enemies misfire
const double confusionReshuffleAt = 0.5; // player options shuffle mid-question

// Question timers.
const Duration questionTime = Duration(seconds: 8);

// Difficulty (DESIGN.md §3.4) — questions climb a ladder as the player grows
// and as foes get tougher: tap an option → spell the reading out → draw the
// kanji. Two triggers, whichever is harder wins:
//   • progression: a kanji whose FSRS card has matured past a stability
//     threshold is quizzed the hard way — reading recall past
//     [masteryStabilityDays] (about a week) becomes typed; kanji production
//     (reading→kanji) past the much higher [drawMasteryStabilityDays] becomes a
//     freehand drawing. Drawing a kanji from memory is the hardest recall, so
//     it is gated behind genuine long-term retention.
//   • encounter: mini-bosses and bosses carry a higher questionFloor that
//     forces the hard form even on freshly-learned kanji.
// Each rung is slower than the last, so it gets a bigger slice of the clock.
const double masteryStabilityDays = 7.0; // reading recall → typed
const double drawMasteryStabilityDays = 90.0; // kanji production → drawn
const double typedQuestionTimeFactor = 1.6;
const double drawnQuestionTimeFactor = 3.5; // drawing + recognition is slowest

// Listen-and-translate (DESIGN.md §3.4): hear a spoken Japanese word, tap its
// meaning. Answering is a tap, but comprehension from audio is harder than
// reading, so it gets a bigger clock. The clock does not start until the
// first playback finishes — listening is never timed against silence.
const double listenQuestionTimeFactor = 1.6;

// Element matchups (DESIGN.md §3.5).
const double overcomeMult = 2.0;
const double resistMult = 0.5;
