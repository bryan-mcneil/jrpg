import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/battle/elements.dart';
import 'package:flutter_kanji_rpg/battle/spells.dart';

import 'helpers.dart';

void main() {
  final fire = kanji('火', strokes: 4, tag: 'fire');
  final storm = kanji('嵐', strokes: 12, tag: 'storm');
  final blade = kanji('剣', strokes: 10, tag: 'blade');
  final amp = kanji('大', strokes: 3, tag: 'amp');
  final mend = kanji('癒', strokes: 18, tag: 'mend');

  ResolvedSpell resolve(dynamic first, [dynamic second]) {
    final result = resolveSpell(first, second, grade: 1.0);
    expect(result, isA<SpellOk>());
    return (result as SpellOk).spell;
  }

  group('grammar', () {
    test('element alone casts', () {
      final spell = resolve(fire);
      expect(spell.element, BattleElement.fire);
      expect(spell.modifier, isNull);
      expect(spell.hitsAllEnemies, isFalse);
    });

    test('element + modifier casts', () {
      final spell = resolve(fire, storm);
      expect(spell.modifier, ModifierClass.storm);
      expect(spell.hitsAllEnemies, isTrue);
    });

    test('leading with a modifier is rejected with a teaching message', () {
      final result = resolveSpell(storm, null, grade: 1.0);
      expect(result, isA<SpellGrammarError>());
      expect((result as SpellGrammarError).message, contains('嵐'));
    });

    test('an element in the modifier slot is rejected', () {
      final water = kanji('水', tag: 'water');
      final result = resolveSpell(fire, water, grade: 1.0);
      expect(result, isA<SpellGrammarError>());
      expect((result as SpellGrammarError).message, contains('水'));
    });
  });

  group('stroke power (§3.7)', () {
    test('≤4 strokes is ×1.0', () {
      expect(resolve(fire).strokeMult, 1.0);
    });

    test('scales linearly to ×2.0 at 16 strokes', () {
      expect(resolve(fire, storm).strokeMult, 2.0); // 4 + 12
      final mid = resolve(fire, kanji('中', strokes: 6, tag: 'blade'));
      expect(mid.strokeMult, closeTo(1.5, 0.001)); // 10 strokes
    });

    test('29-stroke 鬱 caps at ×2.0 — no auto-win (§8)', () {
      final utsu = kanji('鬱', strokes: 29, tag: 'dark');
      expect(resolve(utsu).strokeMult, 2.0);
    });
  });

  group('MP cost', () {
    test('scales with stroke count', () {
      expect(resolve(fire).mpCost, 4); // 2 + ceil(4/2)
      expect(resolve(fire, storm).mpCost, 10); // 2 + ceil(16/2)
    });

    test('amp doubles the cost', () {
      expect(resolve(fire, amp).mpCost, 2 * (2 + (7 / 2).ceil()));
    });
  });

  group('damage', () {
    test('matchup multiplies: 火 vs 水 boss lands at 0.5×', () {
      final spell = resolve(fire); // power 10 × mult 1.0 × grade 1.0
      expect(spellDamage(spell, BattleElement.water), 5);
      expect(spellDamage(spell, BattleElement.metal), 20);
      expect(spellDamage(spell, BattleElement.wood), 10);
    });

    test('storm trades per-target power for coverage; blade bursts', () {
      final stormSpell = resolve(fire, storm); // ×2.0 strokes × 0.7 shape
      expect(spellDamage(stormSpell, BattleElement.wood), 14);
      final bladeSpell = resolve(fire, blade); // 14 strokes ×1.83 × 1.5
      expect(spellDamage(bladeSpell, BattleElement.wood), 28);
    });

    test('generating barrier boosts the spell it feeds', () {
      final spell = resolve(fire);
      expect(
          spellDamage(spell, BattleElement.wood, generatingBonus: 1.25), 13);
    });

    test('grade scales power and clamps to 0.8–1.2', () {
      final low = resolveSpell(fire, null, grade: 0.1) as SpellOk;
      expect(low.spell.grade, 0.8);
      final high = resolveSpell(fire, null, grade: 9) as SpellOk;
      expect(high.spell.grade, 1.2);
      expect(spellDamage(high.spell, BattleElement.wood), 12);
    });
  });

  group('drawing grade', () {
    test('top candidate + fast draw earns the max', () {
      expect(
          drawingGrade(
              candidateRank: 0, elapsed: const Duration(seconds: 2)),
          1.2);
    });

    test('deep candidate, slow draw sinks toward the floor', () {
      expect(
          drawingGrade(
              candidateRank: 4, elapsed: const Duration(seconds: 10)),
          0.9);
    });
  });

  test('mend/ward/boon target self, never enemies', () {
    expect(resolve(fire, mend).targetsSelf, isTrue);
    expect(resolve(fire, kanji('盾', strokes: 9, tag: 'ward')).targetsSelf,
        isTrue);
    final boon = resolve(fire, kanji('力', strokes: 2, tag: 'boon'));
    expect(boon.targetsSelf, isTrue);
    expect(boon.isBuff, isTrue);
    expect(resolve(fire).targetsSelf, isFalse);
  });
}
