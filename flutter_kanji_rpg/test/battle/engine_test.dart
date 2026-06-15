import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/battle/balance.dart';
import 'package:flutter_kanji_rpg/battle/elements.dart';
import 'package:flutter_kanji_rpg/battle/engine.dart';
import 'package:flutter_kanji_rpg/battle/items.dart';
import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/spells.dart';

import 'helpers.dart';

/// Scripted Random so confusion fizzles and seal targets are predictable.
class FixedRandom implements Random {
  FixedRandom({this.doubleValue = 0.99, this.intValue = 0});

  double doubleValue;
  int intValue;

  @override
  double nextDouble() => doubleValue;

  @override
  int nextInt(int max) => min(intValue, max - 1);

  @override
  bool nextBool() => false;
}

ResolvedSpell spell(String elementTag,
    {String? modifierTag, int elementStrokes = 4, int modifierStrokes = 10}) {
  final result = resolveSpell(
    kanji('元', strokes: elementStrokes, tag: elementTag),
    modifierTag == null
        ? null
        : kanji('修', strokes: modifierStrokes, tag: modifierTag),
    grade: 1.0,
  );
  return (result as SpellOk).spell;
}

/// Spends the player turn on a whiffed ATTACK (0/5 → no damage).
void passOffense(BattleEngine e, {int target = 0}) =>
    e.playerAttack(target, const VolleyResult(0, 5));

/// Completes the round from wherever the engine stands: a whiffed DEFEND
/// if the reaction is still open, then every enemy volley answered with
/// [correct] hits.
void drainRound(BattleEngine e, {int correct = 999}) {
  if (e.phase == BattlePhase.reaction) {
    e.playerDefend(const VolleyResult(0, 5));
  }
  while (e.phase == BattlePhase.enemyPhase) {
    final turn = e.nextEnemyTurn();
    if (turn == null) break;
    if (turn.needsVolley) {
      e.resolveEnemyVolley(
        turn,
        VolleyResult(
            min(correct, turn.action.questions), turn.action.questions),
      );
    }
  }
}

void main() {
  group('ATTACK', () {
    test('damage = hits × power, 5/5 combo and speed bonus on top', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerAttack(0, const VolleyResult(5, 5, avgTimeFrac: 1.0));
      // 6 × 5 × 1.25 × 1.25 = 46.875 → 47
      expect(e.enemies[0].hp, 40 - 47 < 0 ? 0 : 40 - 47);
      expect(e.enemies[0].alive, isFalse);
    });

    test('partial volleys hit without the combo', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerAttack(0, const VolleyResult(3, 5));
      expect(e.enemies[0].hp, 40 - 18);
    });

    test('target selection leaves the other enemy untouched', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerAttack(1, const VolleyResult(3, 5));
      expect(e.enemies[0].hp, 40);
      expect(e.enemies[1].hp, 40 - 18);
    });

    test('burn dulls player attacks', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.statuses[StatusType.burn] = 3;
      e.playerAttack(0, const VolleyResult(5, 5));
      // 6 × 5 × 1.25 × 0.8 = 30
      expect(e.enemies[0].hp, 40 - 30);
    });
  });

  group('MAGIC (the M3 verify gate)', () {
    test('火+storm hits both skirmish enemies, ×2 on the metal bat', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      final report =
          e.playerCast(spell('fire', modifierTag: 'storm', modifierStrokes: 12));
      expect(report.hits, hasLength(2));
      // 10 × 2.0 strokes × 0.7 = 14 vs wood; ×2 vs metal = 28.
      expect(e.enemies[0].hp, 40 - 14);
      expect(e.enemies[1].hp, 40 - 28);
      expect(report.hits[1].mult, 2.0);
    });

    test('火+blade bursts a single target only', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      final report = e.playerCast(
          spell('fire', modifierTag: 'blade'), targetIndex: 0);
      expect(report.hits, hasLength(1));
      // 14 strokes → ×1.83, ×1.5 shape → 28 vs wood.
      expect(e.enemies[0].hp, 40 - 28);
      expect(e.enemies[1].hp, 40);
    });

    test('火 vs the 水 boss lands at 0.5×', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      final report = e.playerCast(spell('fire'), targetIndex: 0);
      expect(report.hits.single.mult, 0.5);
      expect(e.enemies[0].hp, 150 - 5);
      expect(e.log.join(), contains('×0.5'));
    });

    test('MP is spent and casting below cost throws', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerCast(spell('fire'), targetIndex: 0); // cost 4
      expect(e.player.mp, playerMaxMp - 4);
      drainRound(e);
      e.player.mp = 3;
      expect(() => e.playerCast(spell('fire'), targetIndex: 0),
          throwsStateError);
    });

    test('orb inflicts the element status; immunities hold', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      final sealed = e.playerCast(
          spell('metal', modifierTag: 'orb'), targetIndex: 0);
      expect(sealed.hits.single.inflicted, StatusType.seal);
      expect(e.enemies[0].hasStatus(StatusType.seal), isTrue);
      drainRound(e);

      final frozen = e.playerCast(
          spell('water', modifierTag: 'orb'), targetIndex: 0);
      expect(frozen.hits.single.immune, isTrue,
          reason: 'the 水 boss cannot be Frozen');
      expect(e.enemies[0].hasStatus(StatusType.freeze), isFalse);
    });

    test('mend heals and cleanses; ward halves incoming damage', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.hp = 50;
      e.player.statuses[StatusType.confusion] = 3;
      final report = e.playerCast(
          spell('wood', modifierTag: 'mend', modifierStrokes: 18));
      // 22 strokes → cap ×2.0; 10 × 2.0 × 0.8 = 16 healed.
      expect(report.heal, 16);
      expect(e.player.hp, 66);
      expect(e.player.statuses, isEmpty);
      drainRound(e, correct: 999);

      e.playerCast(spell('earth', modifierTag: 'ward', modifierStrokes: 9));
      expect(e.player.barrier, isNotNull);
      final before = e.player.hp;
      // Kobold round 2: ひっかき, 2 questions × 5 per miss, all missed:
      // 10 × 0.5 barrier = 5. Bat round 2: status attack, no damage.
      drainRound(e, correct: 0);
      expect(before - e.player.hp, 5);
    });

    test('a barrier that generates the spell element boosts it ×1.25', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerCast(spell('wood', modifierTag: 'ward', modifierStrokes: 9));
      drainRound(e, correct: 999);
      // 木 generates 火 → fire spell rides the barrier: 10 × 1.25 = 12.5 → 13.
      final report = e.playerCast(spell('fire'), targetIndex: 0);
      expect(report.hits.single.damage, 13);
    });
  });

  group('DEFEND and the boss script', () {
    test('boss cycles volley → status → telegraph → big', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      final boss = e.enemies[0];

      passOffense(e);
      e.playerDefend(const VolleyResult(0, 5)); // unbraced reaction
      var turn = e.nextEnemyTurn()!;
      expect(turn.action.kind, EnemyActionKind.volley);
      e.resolveEnemyVolley(turn, const VolleyResult(4, 4));
      expect(e.nextEnemyTurn(), isNull);
      expect(e.player.hp, playerMaxHp, reason: 'perfect answers, no damage');

      passOffense(e);
      e.playerDefend(const VolleyResult(0, 5));
      turn = e.nextEnemyTurn()!;
      expect(turn.action.kind, EnemyActionKind.statusAttack);
      expect(e.player.hasStatus(StatusType.confusion), isTrue);
      expect(e.nextEnemyTurn(), isNull);

      passOffense(e);
      e.playerDefend(const VolleyResult(0, 5));
      turn = e.nextEnemyTurn()!;
      expect(turn.action.kind, EnemyActionKind.telegraph);
      expect(boss.charging, '大水流');
      expect(e.nextEnemyTurn(), isNull);

      // The DEFEND window: 5/5 reverse answers shave the big attack to 10%.
      passOffense(e);
      e.playerDefend(const VolleyResult(5, 5));
      turn = e.nextEnemyTurn()!;
      expect(turn.action.kind, EnemyActionKind.bigAttack);
      expect(boss.charging, isNull);
      e.resolveEnemyVolley(turn, const VolleyResult(0, 6));
      // 6 misses × 9 = 54 × 0.1 → 5.
      expect(playerMaxHp - e.player.hp, 5);
    });

    test('an undefended big attack hurts', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      for (var i = 0; i < 3; i++) {
        passOffense(e);
        drainRound(e, correct: 999);
      }
      passOffense(e);
      e.playerSupport(); // reaction spent without bracing
      final turn = e.nextEnemyTurn()!;
      e.resolveEnemyVolley(turn, const VolleyResult(0, 6));
      expect(playerMaxHp - e.player.hp, 54);
    });

    test('封印 suppresses the boss big attack', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      for (var i = 0; i < 3; i++) {
        passOffense(e);
        drainRound(e, correct: 999);
      }
      // Boss is about to unleash 大水流 — seal it.
      e.playerCast(spell('metal', modifierTag: 'orb'), targetIndex: 0);
      e.playerSupport();
      final turn = e.nextEnemyTurn()!;
      expect(turn.sealed, isTrue);
      expect(turn.needsVolley, isFalse);
      expect(e.nextEnemyTurn(), isNull);
      expect(e.player.hp, playerMaxHp);
    });
  });

  group('statuses', () {
    test('kobold burn brand ticks 4 a round and expires', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      // Round 1 and 2: volleys (answer perfectly). Round 3: 燃える毒牙.
      for (var i = 0; i < 3; i++) {
        passOffense(e);
        drainRound(e, correct: 999);
      }
      expect(e.player.hasStatus(StatusType.burn), isTrue);
      final afterInflict = e.player.hp; // burn already ticked once
      expect(playerMaxHp - afterInflict, burnDotDamage);
      passOffense(e);
      drainRound(e, correct: 999);
      expect(afterInflict - e.player.hp, burnDotDamage);
    });

    test('seal locks one command and lifts when it expires', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom(intValue: 0));
      e.player.statuses[StatusType.seal] = 1;
      e.player.sealedCommand = BattleCommand.attack;
      expect(e.canUse(BattleCommand.attack), isFalse);
      expect(e.canUse(BattleCommand.magic), isTrue,
          reason: 'seal locks one command, not the whole menu');
      e.playerCast(spell('fire'), targetIndex: 0); // ATTACK sealed — cast
      drainRound(e, correct: 999);
      expect(e.player.hasStatus(StatusType.seal), isFalse);
      expect(e.player.sealedCommand, isNull);
      expect(e.canUse(BattleCommand.attack), isTrue);
    });

    test('freeze speeds the player clock and slows frozen enemies', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(e.playerTimeFactor, 1.0);
      e.player.statuses[StatusType.freeze] = 3;
      expect(e.playerTimeFactor, freezePlayerTimeFactor);
      e.enemies[0].statuses[StatusType.freeze] = 3;
      expect(e.enemyVolleyTimeFactor(e.enemies[0]),
          closeTo(freezePlayerTimeFactor * freezeEnemyTimeFactor, 0.001));
      expect(e.enemyVolleyTimeFactor(e.enemies[1]), freezePlayerTimeFactor);
    });

    test('confused enemies fizzle their volleys', () {
      final rng = FixedRandom(doubleValue: 0.0); // always under 35%
      final e = BattleEngine(skirmishFormation, rng: rng);
      e.enemies[0].statuses[StatusType.confusion] = 3;
      passOffense(e);
      e.playerDefend(const VolleyResult(0, 5));
      final turn = e.nextEnemyTurn()!;
      expect(turn.fizzled, isTrue);
      expect(turn.needsVolley, isFalse);
    });

    test('burn DoT can finish a fight at end of round', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.enemies[0].hp = 3;
      e.enemies[0].statuses[StatusType.burn] = 3;
      e.playerAttack(1, const VolleyResult(5, 5, avgTimeFrac: 1.0)); // 47, kills
      expect(e.enemies[1].alive, isFalse);
      drainRound(e, correct: 999);
      expect(e.enemies[0].alive, isFalse, reason: 'burn tick finished it');
      expect(e.outcome, BattleOutcome.victory);
    });
  });

  group('flow', () {
    test('SUPPORT spends SP, charges burn down per question', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      passOffense(e);
      e.playerSupport();
      expect(e.player.sp, playerMaxSp - supportSpCost);
      expect(e.player.supportCharges, supportCharges);
      for (var i = 0; i < supportCharges; i++) {
        expect(e.consumeSupportCharge(), isTrue);
      }
      expect(e.consumeSupportCharge(), isFalse);
    });

    test('MP and SP regenerate each round', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      passOffense(e);
      e.playerSupport(); // sp 10 → 6
      drainRound(e, correct: 999);
      e.playerCast(spell('fire'), targetIndex: 0); // mp capped at 30, then -4
      drainRound(e, correct: 999);
      expect(e.player.sp, playerMaxSp - supportSpCost + 2);
      expect(e.player.mp, playerMaxMp - 4 + mpRegenPerRound);
    });

    test('killing the last enemy ends the battle before the enemy phase', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.enemies[0].hp = 1;
      e.enemies[1].hp = 1;
      e.playerCast(spell('fire', modifierTag: 'storm'));
      expect(e.outcome, BattleOutcome.victory);
      expect(e.phase, BattlePhase.finished);
    });

    test('a glass-cannon player can lose to one volley', () {
      final e = BattleEngine(skirmishFormation,
          player: PlayerState(maxHp: 1), rng: FixedRandom());
      passOffense(e);
      e.playerSupport(); // reaction without bracing
      final turn = e.nextEnemyTurn()!;
      e.resolveEnemyVolley(turn, const VolleyResult(0, 2));
      expect(e.outcome, BattleOutcome.defeat);
      expect(e.phase, BattlePhase.finished);
    });
  });

  group('turn structure (player turn → NPC turn)', () {
    test('offense menu offers ATTACK/MAGIC, reaction DEFEND/SUPPORT', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(e.phase, BattlePhase.command);
      expect(e.canUse(BattleCommand.attack), isTrue);
      expect(e.canUse(BattleCommand.magic), isTrue);
      expect(e.canUse(BattleCommand.defend), isFalse,
          reason: 'DEFEND belongs to the NPC turn');
      expect(e.canUse(BattleCommand.support), isFalse);

      passOffense(e);
      expect(e.phase, BattlePhase.reaction);
      expect(e.canUse(BattleCommand.defend), isTrue);
      expect(e.canUse(BattleCommand.support), isTrue);
      expect(e.canUse(BattleCommand.attack), isFalse,
          reason: 'ATTACK belongs to the player turn');
      expect(e.canUse(BattleCommand.magic), isFalse);
    });

    test('ITEM is on both menus and usable with a stocked bag', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(offenseCommands, contains(BattleCommand.item));
      expect(reactionCommands, contains(BattleCommand.item));
      expect(e.canUse(BattleCommand.item), isTrue);
      passOffense(e);
      expect(e.canUse(BattleCommand.item), isTrue,
          reason: 'ITEM is live on the reaction menu too');
    });

    test('a full round: offense, reaction, enemy actions, next round', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(e.round, 1);
      e.playerAttack(0, const VolleyResult(3, 5));
      expect(e.phase, BattlePhase.reaction);
      e.playerDefend(const VolleyResult(5, 5));
      expect(e.phase, BattlePhase.enemyPhase);
      drainRound(e, correct: 0); // every enemy question missed
      // 5/5 DEFEND shaves both volleys: (2 + 2 misses) × 5 × 0.1 → 1 + 1.
      expect(playerMaxHp - e.player.hp, 2);
      expect(e.round, 2);
      expect(e.phase, BattlePhase.command);
    });

    test('every ally acts before the NPC turn (the select→act loop)', () {
      final e = BattleEngine(skirmishFormation,
          rng: FixedRandom(), partySize: 2);
      e.playerAttack(0, const VolleyResult(1, 5));
      expect(e.phase, BattlePhase.command,
          reason: 'a second ally still has to act');
      e.playerAttack(1, const VolleyResult(1, 5));
      expect(e.phase, BattlePhase.reaction);
    });

    test('with no usable reaction the NPC turn rolls in unopposed', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.sp = 0; // SUPPORT unaffordable
      e.player.items.updateAll((k, v) => 0); // and the bag is empty
      e.player.statuses[StatusType.seal] = 2;
      e.player.sealedCommand = BattleCommand.defend;
      passOffense(e);
      expect(e.phase, BattlePhase.enemyPhase, reason: 'reaction auto-skips');
      expect(e.log.join(), contains('No reaction possible'));
    });

    test('with no usable offense the player turn is skipped too', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      passOffense(e);
      // Mid-round: seal ATTACK, drain MP, and empty the bag so round 2's
      // whole offense menu is dead.
      e.player.statuses[StatusType.seal] = 2;
      e.player.sealedCommand = BattleCommand.attack;
      e.player.mp = 0;
      e.player.items.updateAll((k, v) => 0);
      drainRound(e, correct: 999);
      expect(e.round, 2);
      expect(e.phase, BattlePhase.reaction,
          reason: 'sealed ATTACK + no MP → straight to the reaction');
      expect(e.log.join(), contains('the player turn slips away'));
    });

    test('封印 picks among the four real commands, never ITEM', () {
      // intValue 99 clamps to the pool's last index — with ITEM in the
      // pool that would be ITEM; sealable pool must end at MAGIC.
      final e = BattleEngine(bossFormation,
          rng: FixedRandom(doubleValue: 0.99, intValue: 99));
      for (var i = 0; i < 5; i++) {
        // Boss round 5 (言霊封じ) inflicts seal.
        passOffense(e);
        drainRound(e, correct: 999);
      }
      expect(e.player.hasStatus(StatusType.seal), isTrue);
      expect(e.player.sealedCommand, BattleCommand.magic);
    });
  });

  group('boon (buff) and healing', () {
    test('a boon spell is a no-target party buff, deals no damage', () {
      final s = spell('wood', modifierTag: 'boon');
      expect(s.isBuff, isTrue);
      expect(s.targetsSelf, isTrue, reason: 'buffs the party, not an enemy');
      expect(s.hitsAllEnemies, isFalse);

      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      final report = e.playerCast(s); // no targetIndex needed
      expect(report.buffApplied, isTrue);
      expect(report.hits, isEmpty);
      expect(e.enemies[0].hp, 40, reason: 'a buff never damages');
      expect(e.player.atkBuffRounds, boonRounds);
      expect(e.player.atkBuffMult, 1 + boonAtkBonus);
    });

    test('the buff empowers the next ATTACK by +50%', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerCast(spell('fire', modifierTag: 'boon')); // round 1 action
      drainRound(e); // into round 2, buff still up
      e.playerAttack(0, const VolleyResult(3, 5));
      // 6 × 3 hits × 1.5 buff = 27 (vs 18 unbuffed).
      expect(e.enemies[0].hp, 40 - 27);
    });

    test('the buff empowers MAGIC damage too', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerCast(spell('fire', modifierTag: 'boon'));
      drainRound(e);
      // Plain 火 bolt vs the wood kobold: 10 base × 1.0 (4 strokes, neutral)
      // × 1.5 buff = 15.
      final report = e.playerCast(spell('fire'), targetIndex: 0);
      expect(report.hits.single.damage, 15);
    });

    test('the buff lasts boonRounds rounds, then fades', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.playerCast(spell('fire', modifierTag: 'boon')); // round 1 action
      expect(e.player.atkBuffMult, 1 + boonAtkBonus);
      for (var r = 0; r < boonRounds; r++) {
        expect(e.player.atkBuffMult, 1 + boonAtkBonus,
            reason: 'still empowered during round ${r + 1}');
        drainRound(e);
        if (r < boonRounds - 1) passOffense(e); // spend next round's offense
      }
      expect(e.player.atkBuffRounds, 0);
      expect(e.player.atkBuffMult, 1.0);
      expect(e.log.join(), contains('empowerment fades'));
    });

    test('mend magic heals the player and cleanses statuses', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.hp = 50;
      e.player.statuses[StatusType.confusion] = 3;
      final report =
          e.playerCast(spell('water', modifierTag: 'mend', modifierStrokes: 18));
      expect(report.heal, greaterThan(0));
      expect(e.player.hp, greaterThan(50));
      expect(e.player.statuses, isEmpty, reason: 'mend cleanses');
      expect(report.cleansed, isTrue);
    });
  });

  group('items (§3.8)', () {
    test('canUse(item) tracks the bag', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(e.canUse(BattleCommand.item), isTrue,
          reason: 'the default loadout has items');
      e.player.items.updateAll((k, v) => 0);
      expect(e.canUse(BattleCommand.item), isFalse, reason: 'empty bag');
    });

    test('a healing item restores HP (capped) and is consumed', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.hp = 80;
      final before = e.player.items['potion']!;
      final report = e.playerUseItem(itemCatalog['potion']!);
      // 80 + 40 capped at 100 → 20 healed.
      expect(report.hpHealed, 20);
      expect(e.player.hp, 100);
      expect(e.player.items['potion'], before - 1);
    });

    test('MP and SP items refill those gauges', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      e.player.mp = 5;
      final mp = e.playerUseItem(itemCatalog['ether']!);
      expect(mp.mpRestored, itemHealMp);
      expect(e.player.mp, 5 + itemHealMp);

      final e2 = BattleEngine(skirmishFormation, rng: FixedRandom());
      e2.player.sp = 1;
      final sp = e2.playerUseItem(itemCatalog['restorative']!);
      expect(sp.spRestored, itemHealSp);
      expect(e2.player.sp, 1 + itemHealSp);
    });

    test('the 力 tonic empowers exactly like a boon spell', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      final report = e.playerUseItem(itemCatalog['tonic']!);
      expect(report.empowered, isTrue);
      expect(e.player.atkBuffRounds, boonRounds);
      expect(e.player.atkBuffMult, 1 + boonAtkBonus);
    });

    test('a status item lands its ailment on a target enemy', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      final report = e.playerUseItem(itemCatalog['firecharm']!, targetIndex: 0);
      expect(report.inflicted, StatusType.burn);
      expect(e.enemies[0].hasStatus(StatusType.burn), isTrue);
      expect(e.enemies[1].hasStatus(StatusType.burn), isFalse,
          reason: 'only the target is afflicted');
    });

    test('themed immunity blocks a status item', () {
      final e = BattleEngine(bossFormation, rng: FixedRandom());
      const frost = ItemSpec(
        id: 'frost',
        name: '氷塊',
        glyph: '氷',
        kind: ItemEffectKind.ailment,
        status: StatusType.freeze,
      );
      e.player.items['frost'] = 1;
      final report = e.playerUseItem(frost, targetIndex: 0);
      expect(report.immune, isTrue, reason: 'the 水 boss cannot be Frozen');
      expect(e.enemies[0].hasStatus(StatusType.freeze), isFalse);
    });

    test('ITEM spends the offense on the player turn', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      expect(e.phase, BattlePhase.command);
      e.playerUseItem(itemCatalog['potion']!);
      expect(e.phase, BattlePhase.reaction,
          reason: 'a single ally used its action on the item');
    });

    test('ITEM opens the enemy phase when used as the reaction', () {
      final e = BattleEngine(skirmishFormation, rng: FixedRandom());
      passOffense(e);
      expect(e.phase, BattlePhase.reaction);
      e.playerUseItem(itemCatalog['firecharm']!, targetIndex: 0);
      expect(e.phase, BattlePhase.enemyPhase);
    });

    test('封印 never locks ITEM (the bag is physical, not kotodama)', () {
      expect(sealableCommands, isNot(contains(BattleCommand.item)));
    });
  });
}
