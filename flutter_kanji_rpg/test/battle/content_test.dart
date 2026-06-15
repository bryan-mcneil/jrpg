import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/elements.dart';
import 'package:flutter_kanji_rpg/battle/engine.dart';
import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/spells.dart';

import 'helpers.dart';

/// element[+modifier] spell from the test dictionary, fixed grade.
ResolvedSpell _spell(
  String elementTag, {
  String? modifierTag,
  int elementStrokes = 4,
  int modifierStrokes = 12,
}) {
  final result = resolveSpell(
    kanji('元', strokes: elementStrokes, tag: elementTag),
    modifierTag == null
        ? null
        : kanji('修', strokes: modifierStrokes, tag: modifierTag),
    grade: 1.0,
  );
  return (result as SpellOk).spell;
}

void main() {
  group('every shipped formation is well-formed', () {
    for (final f in formations) {
      test('${f.id}: enemies have HP and a non-empty script', () {
        expect(f.enemies, isNotEmpty);
        for (final e in f.enemies) {
          expect(e.maxHp, greaterThan(0), reason: '${e.id} needs HP');
          expect(e.script, isNotEmpty, reason: '${e.id} needs a script');
        }
      });
    }

    test('formation ids are unique (setup screen keys off them)', () {
      final ids = formations.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('swarm — the multi-target shape lesson', () {
    test('fields three enemies', () {
      expect(swarmFormation.enemies.length, 3);
    });

    test('a 火 storm hits all three: ×2 on the metal adds, ×1 on the wood '
        'leader, and it spends MP', () {
      final e = BattleEngine(swarmFormation);
      final mpBefore = e.player.mp;
      final report = e.playerCast(_spell('fire', modifierTag: 'storm'));

      expect(report.hits.length, 3, reason: 'storm is AoE');
      for (final h in report.hits) {
        final element = e.enemies[h.enemyIndex].spec.element;
        expect(h.mult, element == BattleElement.metal ? 2.0 : 1.0);
        expect(h.damage, greaterThan(0));
      }
      expect(e.player.mp, lessThan(mpBefore));
    });
  });

  group('mini-boss — the typed difficulty rung', () {
    test('forces typed answers but never drawn (DEFEND caps at typed)', () {
      final e = BattleEngine(miniBossFormation);
      expect(e.encounterFloor, QuestionMode.typed);
      expect(e.defendFloor, QuestionMode.typed);
      expect(e.questionFloorFor(e.enemies.single), QuestionMode.typed);
    });

    test('as a fire guardian it shrugs off 火傷 burn (themed immunity §3.5)',
        () {
      final e = BattleEngine(miniBossFormation);
      // A 火 orb would brand burn, but the warden is immune.
      final report = e.playerCast(_spell('fire', modifierTag: 'orb'),
          targetIndex: 0);
      expect(report.hits.single.immune, isTrue);
      expect(e.enemies.single.hasStatus(StatusType.burn), isFalse);
    });

    test('telegraphs a big attack, so the DEFEND window exists', () {
      expect(
        miniBossFormation.enemies.single.script
            .any((a) => a.kind == EnemyActionKind.telegraph),
        isTrue,
      );
    });
  });
}
