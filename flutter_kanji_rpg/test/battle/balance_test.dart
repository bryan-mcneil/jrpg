import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/balance.dart';
import 'package:flutter_kanji_rpg/battle/elements.dart';
import 'package:flutter_kanji_rpg/battle/engine.dart';
import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/spells.dart';

import 'helpers.dart';

/// These pin the DESIGN §8 ceilings ("playtest M3 hard"). The knobs in
/// balance.dart can be retuned, but a change that trips one of these is a
/// balance *regression*, not a tweak — update the expectation here on purpose
/// so the ceiling stays a deliberate decision.
ResolvedSpell _blade(int totalStrokes) {
  final result = resolveSpell(
    kanji('元', strokes: 4, tag: 'fire'),
    kanji('修', strokes: totalStrokes - 4, tag: 'blade'),
    grade: gradeMax, // best-case drawing
  );
  return (result as SpellOk).spell;
}

void main() {
  test('a perfect, sped, boon-buffed ATTACK is bounded (no runaway burst)', () {
    // The boss has the HP headroom to absorb the full hit (skirmish foes would
    // clamp it at their 40 HP). ATTACK has no element matchup, so the target's
    // element is irrelevant.
    final e = BattleEngine(bossFormation);
    e.player.atkBuffRounds = boonRounds; // +50% boon active
    final before = e.enemies[0].hp;
    e.playerAttack(0, const VolleyResult(5, 5, avgTimeFrac: 1.0));
    final dealt = before - e.enemies[0].hp;
    // 6 × 5 × 1.25 combo × 1.25 speed × 1.5 buff = 70.31 → 70. This is the
    // single-target ATTACK ceiling.
    expect(dealt, 70);
  });

  test('the 16-stroke cap means 29-stroke 鬱 is no auto-win (§8)', () {
    final capped = _blade(16); // ×2.0 strokeMult
    final huge = _blade(29); // 鬱-scale, still capped at ×2.0
    expect(huge.strokeMult, capped.strokeMult);
    // End to end: extra strokes past the cap buy zero extra damage.
    expect(
      spellDamage(huge, BattleElement.wood),
      spellDamage(capped, BattleElement.wood),
    );
  });

  test('a perfect DEFEND keeps ~90% of an enemy volley out (§3.4)', () {
    final e = BattleEngine(bossFormation);
    e.playerAttack(0, const VolleyResult(0, 5)); // whiff → reaction opens
    expect(e.phase, BattlePhase.reaction);
    e.playerDefend(const VolleyResult(5, 5)); // perfect brace

    final hpBefore = e.player.hp;
    final turn = e.nextEnemyTurn()!; // boss 水撃 volley
    expect(turn.needsVolley, isTrue);
    e.resolveEnemyVolley(
        turn, VolleyResult(0, turn.action.questions)); // all slip through
    final dealt = hpBefore - e.player.hp;

    final undefended = turn.action.damagePerMiss * turn.action.questions;
    expect(dealt, lessThanOrEqualTo((undefended * 0.1).ceil()),
        reason: 'a 5/5 brace must mitigate at least 90%');
  });

  test('storm trades per-target power for coverage — never a strict upgrade '
      'over blade on one target', () {
    final blade = _blade(16); // single-target burst
    final storm = (resolveSpell(
      kanji('元', strokes: 4, tag: 'fire'),
      kanji('修', strokes: 12, tag: 'storm'),
      grade: gradeMax,
    ) as SpellOk)
        .spell;
    // Against a lone enemy the blade out-hits the storm; storm only pulls ahead
    // by hitting the whole room.
    expect(
      spellDamage(storm, BattleElement.wood),
      lessThan(spellDamage(blade, BattleElement.wood)),
    );
  });
}
