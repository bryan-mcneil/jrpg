import 'dart:math';

import '../db/database.dart';
import 'balance.dart';
import 'elements.dart';

/// Spell grammar (DESIGN.md §3.7): [element kanji] + [optional modifier
/// kanji], drawn in sequence. Resolution checks the tags; power scales with
/// total stroke count and the drawing grade.
sealed class SpellGrammarResult {
  const SpellGrammarResult();
}

class SpellOk extends SpellGrammarResult {
  const SpellOk(this.spell);

  final ResolvedSpell spell;
}

class SpellGrammarError extends SpellGrammarResult {
  const SpellGrammarError(this.message);

  final String message;
}

class ResolvedSpell {
  ResolvedSpell({
    required this.elementEntry,
    this.modifierEntry,
    required this.grade,
  })  : element = elementFromTag(elementEntry.tag)!,
        modifier =
            modifierEntry == null ? null : modifierFromTag(modifierEntry.tag);

  final KanjiEntry elementEntry;
  final KanjiEntry? modifierEntry;
  final BattleElement element;
  final ModifierClass? modifier;

  /// Drawing grade from recognition rank + speed, clamped to
  /// [gradeMin, gradeMax]; two-kanji spells average their grades.
  final double grade;

  int get totalStrokes =>
      elementEntry.strokeCount + (modifierEntry?.strokeCount ?? 0);

  /// 1.0 at ≤4 strokes up to the 2.0 cap at 16+ (so 鬱 isn't an auto-win).
  double get strokeMult =>
      1 +
      (strokeMultMax - 1) *
          ((totalStrokes - strokeMultFloorStrokes) /
                  (strokeMultCeilStrokes - strokeMultFloorStrokes))
              .clamp(0.0, 1.0);

  int get mpCost {
    final base = spellMpBase + (totalStrokes / 2).ceil();
    return modifier == ModifierClass.amp ? base * 2 : base;
  }

  /// Pre-matchup power (base × strokes × grade × shape).
  double get shapedPower {
    final shape = switch (modifier) {
      ModifierClass.storm => stormShape,
      ModifierClass.blade => bladeShape,
      ModifierClass.amp => ampShape,
      ModifierClass.orb => orbShape,
      _ => 1.0,
    };
    return spellBasePower * strokeMult * grade * shape;
  }

  bool get hitsAllEnemies => modifier == ModifierClass.storm;

  /// A buff spell empowers the party rather than dealing damage.
  bool get isBuff => modifier == ModifierClass.boon;

  bool get targetsSelf =>
      modifier == ModifierClass.ward ||
      modifier == ModifierClass.mend ||
      modifier == ModifierClass.boon;

  String get description {
    final mod = modifierEntry;
    return mod == null
        ? elementEntry.literal
        : '${elementEntry.literal}＋${mod.literal}';
  }
}

/// Checks the element+modifier grammar. [first] must carry an element tag,
/// [second] (if drawn) a modifier tag. Wrong order/class fails with a
/// teaching message — retries are free, only a cast spends MP.
SpellGrammarResult resolveSpell(
  KanjiEntry first,
  KanjiEntry? second, {
  required double grade,
}) {
  if (elementFromTag(first.tag) == null) {
    return SpellGrammarError(
        '${first.literal} is a ${first.tag} modifier — lead with an element kanji (木火土金水光闇).');
  }
  if (second != null && modifierFromTag(second.tag) == null) {
    return SpellGrammarError(
        '${second.literal} is a ${second.tag} element — modifiers come second.');
  }
  return SpellOk(ResolvedSpell(
    elementEntry: first,
    modifierEntry: second,
    grade: grade.clamp(gradeMin, gradeMax),
  ));
}

/// Drawing grade for one recognized kanji: top-candidate match and a fast
/// draw each earn a bonus over neutral 1.0.
double drawingGrade({required int candidateRank, required Duration elapsed}) {
  var g = 1.0;
  if (candidateRank == 0) g += gradeTopCandidateBonus;
  if (elapsed <= gradeFastDrawLimit) g += gradeFastDrawBonus;
  if (candidateRank > 2) g -= gradeTopCandidateBonus;
  return g.clamp(gradeMin, gradeMax);
}

/// Final per-target damage once the defender's element is known. [atkMult]
/// folds in temporary buffs (the boon spell's +ATK) before rounding.
int spellDamage(ResolvedSpell spell, BattleElement defender,
    {double generatingBonus = 1.0, double atkMult = 1.0}) {
  return max(
      1,
      (spell.shapedPower *
              matchup(spell.element, defender) *
              generatingBonus *
              atkMult)
          .round());
}
