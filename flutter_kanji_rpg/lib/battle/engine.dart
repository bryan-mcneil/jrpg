import 'dart:math';

import 'balance.dart';
import 'elements.dart';
import 'items.dart';
import 'models.dart';
import 'spells.dart';

/// Two halves per round (DESIGN.md §3.4): the player turn ([command] —
/// each ally picks ATTACK/MAGIC/ITEM), then the NPC turn ([reaction] —
/// the player picks DEFEND/SUPPORT/ITEM, then enemies act in [enemyPhase]).
enum BattlePhase { command, reaction, enemyPhase, finished }

enum BattleOutcome { victory, defeat }

/// One enemy's turn, handed to the UI. When [needsVolley] the UI runs
/// [action.questions] timed questions and reports back via
/// [BattleEngine.resolveEnemyVolley]; otherwise the action already applied.
class EnemyTurnSpec {
  EnemyTurnSpec(this.enemyIndex, this.enemy, this.action,
      {required this.needsVolley, this.fizzled = false, this.sealed = false});

  final int enemyIndex;
  final EnemyState enemy;
  final EnemyAction action;
  final bool needsVolley;

  /// Confusion misfire — the attack simply fails.
  final bool fizzled;

  /// 封印 on the enemy suppressed its big attack.
  final bool sealed;
}

class SpellHit {
  SpellHit(this.enemyIndex, this.damage, this.mult,
      {this.inflicted, this.immune = false});

  final int enemyIndex;
  final int damage;
  final double mult;
  final StatusType? inflicted;
  final bool immune;
}

class CastReport {
  CastReport({
    this.hits = const [],
    this.heal = 0,
    this.barrierSet = false,
    this.cleansed = false,
    this.buffApplied = false,
    required this.mpSpent,
  });

  final List<SpellHit> hits;
  final int heal;
  final bool barrierSet;
  final bool cleansed;
  final bool buffApplied;
  final int mpSpent;
}

/// What a used item did, for the UI banner and tests.
class ItemReport {
  ItemReport(
    this.item, {
    this.hpHealed = 0,
    this.mpRestored = 0,
    this.spRestored = 0,
    this.empowered = false,
    this.inflicted,
    this.immune = false,
  });

  final ItemSpec item;
  final int hpHealed;
  final int mpRestored;
  final int spRestored;
  final bool empowered;
  final StatusType? inflicted;
  final bool immune;
}

/// Pure turn logic: each round every ally takes one offensive action
/// (player turn), then the player picks a reaction and every living enemy
/// acts (NPC turn), then statuses tick. The UI owns question presentation
/// and reports [VolleyResult]s; all damage/status math is here so it
/// unit-tests without widgets.
class BattleEngine {
  BattleEngine(this.formation,
      {PlayerState? player, Random? rng, this.partySize = 1})
      : player = player ?? PlayerState(),
        rng = rng ?? Random(),
        enemies = [for (final spec in formation.enemies) EnemyState(spec)] {
    _alliesToAct = partySize;
  }

  final Formation formation;
  final PlayerState player;
  final List<EnemyState> enemies;
  final Random rng;
  final List<String> log = [];

  /// Allies acting on the player turn. One hero today; when companions
  /// join, the select-an-ally→act→quiz loop runs once per member.
  final int partySize;

  BattlePhase phase = BattlePhase.command;
  BattleOutcome? outcome;
  int round = 1;

  double _defendFactor = 1.0;
  int _alliesToAct = 1;
  final List<int> _turnQueue = [];

  List<EnemyState> get aliveEnemies => [for (final e in enemies) if (e.alive) e];

  // --- timers ---------------------------------------------------------------

  /// Timer scale for volleys the player initiates (ATTACK/DEFEND).
  double get playerTimeFactor =>
      player.hasStatus(StatusType.freeze) ? freezePlayerTimeFactor : 1.0;

  /// Timer scale for an enemy's volley at the player: frozen enemies attack
  /// slower (more reading time), a frozen player still reads on a fast clock.
  double enemyVolleyTimeFactor(EnemyState enemy) =>
      playerTimeFactor *
      (enemy.hasStatus(StatusType.freeze) ? freezeEnemyTimeFactor : 1.0);

  // --- difficulty floor (DESIGN.md §3.4) ------------------------------------

  /// Minimum question difficulty when fighting [enemy] (ATTACK, or its own
  /// volleys): tougher foes force typed answers.
  QuestionMode questionFloorFor(EnemyState enemy) => enemy.spec.questionFloor;

  /// The encounter-wide floor for player-wide volleys: the toughest living
  /// enemy in the room sets how hard the questions get.
  QuestionMode get encounterFloor => aliveEnemies.fold(
        QuestionMode.choice,
        (m, e) =>
            e.spec.questionFloor.index > m.index ? e.spec.questionFloor : m,
      );

  /// The floor for DEFEND bracing. Drawing a kanji is too slow and deliberate
  /// to demand mid-reaction, so the reaction never forces it: the floor caps
  /// at [QuestionMode.typed] (mastery can still make a known kanji's own
  /// production drawn). Drawing is driven by the enemies' fierce own volleys.
  QuestionMode get defendFloor =>
      encounterFloor.index > QuestionMode.typed.index
          ? QuestionMode.typed
          : encounterFloor;

  // --- player commands --------------------------------------------------------

  /// The menu the current phase offers: offense on the player turn,
  /// reactions on the NPC turn, nothing in between.
  List<BattleCommand> get commandMenu => switch (phase) {
        BattlePhase.command => offenseCommands,
        BattlePhase.reaction => reactionCommands,
        _ => const [],
      };

  bool canUse(BattleCommand cmd) {
    if (!commandMenu.contains(cmd)) return false;
    if (player.hasStatus(StatusType.seal) && player.sealedCommand == cmd) {
      return false;
    }
    return switch (cmd) {
      BattleCommand.support => player.sp >= supportSpCost,
      BattleCommand.magic => player.mp >= spellMpBase + 1,
      BattleCommand.item => player.hasItems,
      _ => true,
    };
  }

  /// ATTACK: damage = hits × per-hit power, ×1.25 on a clean 5/5, plus a
  /// speed bonus; Burn dulls the blade.
  void playerAttack(int targetIndex, VolleyResult result) {
    assert(canUse(BattleCommand.attack));
    final target = enemies[targetIndex];
    final combo = result.correct == result.total ? attackComboMult : 1.0;
    final burn =
        player.hasStatus(StatusType.burn) ? burnAttackPenalty : 1.0;
    final damage = (attackPerHit *
            result.correct *
            combo *
            (1 + attackSpeedBonusMax * result.avgTimeFrac) *
            burn *
            player.atkBuffMult)
        .round();
    target.hp = max(0, target.hp - damage);
    log.add('ATTACK — ${result.correct}/${result.total} hits on '
        '${target.spec.name} for $damage'
        '${combo > 1 ? ' (combo!)' : ''}');
    _afterOffenseAction();
  }

  /// DEFEND (reaction): each correct reverse answer shaves incoming damage
  /// this round.
  void playerDefend(VolleyResult result) {
    assert(canUse(BattleCommand.defend));
    _defendFactor =
        (1 - defendMitigationPerHit * result.correct).clamp(0.0, 1.0);
    log.add('DEFEND — ${result.correct}/${result.total} braced, damage ×'
        '${_defendFactor.toStringAsFixed(2)} this round');
    _startEnemyActions();
  }

  /// SUPPORT (reaction): the equipped pet hints the next [supportCharges]
  /// questions.
  void playerSupport() {
    assert(canUse(BattleCommand.support));
    player.sp -= supportSpCost;
    player.supportCharges = supportCharges;
    log.add('SUPPORT — word-sprite lends aid for $supportCharges questions');
    _startEnemyActions();
  }

  /// Consumed per question shown while the pet buff is up (50/50 hint).
  bool consumeSupportCharge() {
    if (player.supportCharges <= 0) return false;
    player.supportCharges--;
    return true;
  }

  /// MAGIC: applies a resolved, drawn spell. [targetIndex] is required for
  /// single-target damage spells.
  CastReport playerCast(ResolvedSpell spell, {int? targetIndex}) {
    assert(canUse(BattleCommand.magic));
    if (spell.mpCost > player.mp) {
      throw StateError('not enough MP');
    }
    player.mp -= spell.mpCost;

    CastReport report;
    if (spell.modifier == ModifierClass.mend) {
      final heal = (spell.shapedPower * mendShape).round();
      player.hp = min(player.maxHp, player.hp + heal);
      final hadStatuses = player.statuses.isNotEmpty;
      player.statuses.clear();
      player.sealedCommand = null;
      report = CastReport(heal: heal, cleansed: hadStatuses, mpSpent: spell.mpCost);
      log.add('${spell.description} — mended $heal HP'
          '${hadStatuses ? ', statuses cleansed' : ''}');
    } else if (spell.modifier == ModifierClass.ward) {
      player.barrier = Barrier(spell.element);
      report = CastReport(barrierSet: true, mpSpent: spell.mpCost);
      log.add('${spell.description} — ${elementGlyphs[spell.element]} barrier '
          'raised ($wardRounds rounds)');
    } else if (spell.isBuff) {
      player.atkBuffRounds = boonRounds;
      report = CastReport(buffApplied: true, mpSpent: spell.mpCost);
      log.add('${spell.description} — party empowered '
          '(+${(boonAtkBonus * 100).round()}% ATK, $boonRounds rounds)');
    } else {
      final genBonus = player.barrier != null &&
              generates[player.barrier!.element] == spell.element
          ? generatingBoost
          : 1.0;
      final targets = spell.hitsAllEnemies
          ? [for (var i = 0; i < enemies.length; i++) if (enemies[i].alive) i]
          : [targetIndex!];
      final hits = <SpellHit>[];
      for (final i in targets) {
        final enemy = enemies[i];
        final mult = matchup(spell.element, enemy.spec.element);
        final damage = spellDamage(spell, enemy.spec.element,
            generatingBonus: genBonus, atkMult: player.atkBuffMult);
        enemy.hp = max(0, enemy.hp - damage);
        StatusType? inflicted;
        var immune = false;
        if (spell.modifier == ModifierClass.orb) {
          final status = orbStatus[spell.element];
          if (status != null) {
            if (enemy.spec.statusImmunity == status) {
              immune = true;
            } else {
              enemy.statuses[status] = statusRounds;
              inflicted = status;
            }
          }
        }
        hits.add(SpellHit(i, damage, mult, inflicted: inflicted, immune: immune));
        log.add('${spell.description} hits ${enemy.spec.name} for $damage'
            '${_multLabel(mult)}'
            '${genBonus > 1 ? ' (相生 boost)' : ''}'
            '${inflicted != null ? ' — ${statusGlyphs[inflicted]}!' : ''}'
            '${immune ? ' — immune to ${statusGlyphs[enemy.spec.statusImmunity]}' : ''}');
      }
      report = CastReport(hits: hits, mpSpent: spell.mpCost);
    }
    _afterOffenseAction();
    return report;
  }

  String _multLabel(double mult) => mult > 1
      ? ' (×${mult.toStringAsFixed(1)} weakness!)'
      : mult < 1
          ? ' (×${mult.toStringAsFixed(1)} resisted)'
          : '';

  /// ITEM: spends one consumable (DESIGN.md §3.8). Usable on either menu —
  /// on the player turn it counts as that ally's action, on the NPC turn as
  /// the reaction. Ailment items need [targetIndex].
  ItemReport playerUseItem(ItemSpec item, {int? targetIndex}) {
    assert(canUse(BattleCommand.item));
    assert((player.items[item.id] ?? 0) > 0);
    player.items[item.id] = player.items[item.id]! - 1;

    final ItemReport report;
    switch (item.kind) {
      case ItemEffectKind.healHp:
        final healed = min(player.maxHp, player.hp + item.amount) - player.hp;
        player.hp += healed;
        report = ItemReport(item, hpHealed: healed);
        log.add('${item.name} — restored $healed HP');
      case ItemEffectKind.healMp:
        final gained = min(playerMaxMp, player.mp + item.amount) - player.mp;
        player.mp += gained;
        report = ItemReport(item, mpRestored: gained);
        log.add('${item.name} — restored $gained MP');
      case ItemEffectKind.healSp:
        final gained = min(playerMaxSp, player.sp + item.amount) - player.sp;
        player.sp += gained;
        report = ItemReport(item, spRestored: gained);
        log.add('${item.name} — restored $gained SP');
      case ItemEffectKind.empower:
        player.atkBuffRounds = item.amount;
        report = ItemReport(item, empowered: true);
        log.add('${item.name} — party empowered '
            '(+${(boonAtkBonus * 100).round()}% ATK, ${item.amount} rounds)');
      case ItemEffectKind.ailment:
        final enemy = enemies[targetIndex!];
        if (enemy.spec.statusImmunity == item.status) {
          report = ItemReport(item, immune: true);
          log.add('${item.name} — ${enemy.spec.name} is immune to '
              '${statusGlyphs[item.status]}');
        } else {
          enemy.statuses[item.status!] = statusRounds;
          report = ItemReport(item, inflicted: item.status);
          log.add('${item.name} — ${statusGlyphs[item.status]} on '
              '${enemy.spec.name}!');
        }
    }
    _advanceAfterCommand();
    return report;
  }

  /// Items act on both menus, so route to the right transition: an offense
  /// action on the player turn, a reaction on the NPC turn.
  void _advanceAfterCommand() {
    if (phase == BattlePhase.command) {
      _afterOffenseAction();
    } else {
      _startEnemyActions();
    }
  }

  void _afterOffenseAction() {
    if (aliveEnemies.isEmpty) {
      _finish(BattleOutcome.victory);
      return;
    }
    if (--_alliesToAct > 0) return; // the next ally still acts this turn
    _enterReaction();
  }

  void _enterReaction() {
    phase = BattlePhase.reaction;
    if (!reactionCommands.any(canUse)) {
      log.add('No reaction possible — the enemies press in!');
      _startEnemyActions();
    }
  }

  void _startEnemyActions() {
    phase = BattlePhase.enemyPhase;
    _turnQueue
      ..clear()
      ..addAll([for (var i = 0; i < enemies.length; i++) if (enemies[i].alive) i]);
  }

  // --- enemy phase ------------------------------------------------------------

  /// Pops the next enemy turn. Immediate actions (status/telegraph, fizzles,
  /// sealed bigs) are applied before returning; volleys wait for
  /// [resolveEnemyVolley]. Returns null when the round is over (statuses
  /// ticked, back to the command phase or finished).
  EnemyTurnSpec? nextEnemyTurn() {
    assert(phase == BattlePhase.enemyPhase);
    while (_turnQueue.isNotEmpty) {
      final index = _turnQueue.removeAt(0);
      final enemy = enemies[index];
      if (!enemy.alive) continue;
      final action = enemy.nextAction;
      enemy.scriptIndex++;

      if (action.kind == EnemyActionKind.bigAttack &&
          enemy.hasStatus(StatusType.seal)) {
        enemy.charging = null;
        log.add('${enemy.spec.name}の${action.name}は封印されている!');
        return EnemyTurnSpec(index, enemy, action,
            needsVolley: false, sealed: true);
      }
      if ((action.kind == EnemyActionKind.volley ||
              action.kind == EnemyActionKind.bigAttack) &&
          enemy.hasStatus(StatusType.confusion) &&
          rng.nextDouble() < confusionFizzleChance) {
        enemy.charging = null;
        log.add('${enemy.spec.name} is confused — ${action.name} fizzles!');
        return EnemyTurnSpec(index, enemy, action,
            needsVolley: false, fizzled: true);
      }

      switch (action.kind) {
        case EnemyActionKind.volley:
        case EnemyActionKind.bigAttack:
          if (action.kind == EnemyActionKind.bigAttack) enemy.charging = null;
          return EnemyTurnSpec(index, enemy, action, needsVolley: true);
        case EnemyActionKind.statusAttack:
          _inflictOnPlayer(action.inflicts!);
          log.add('${enemy.spec.name} uses ${action.name} — '
              '${statusGlyphs[action.inflicts]}!');
          return EnemyTurnSpec(index, enemy, action, needsVolley: false);
        case EnemyActionKind.telegraph:
          enemy.charging = action.name;
          log.add('${enemy.spec.name} is charging ${action.name}… DEFEND!');
          return EnemyTurnSpec(index, enemy, action, needsVolley: false);
      }
    }
    _endRound();
    return null;
  }

  /// Damage from an enemy volley the player just answered: per-miss damage,
  /// shaved by DEFEND and the ward barrier.
  void resolveEnemyVolley(EnemyTurnSpec turn, VolleyResult result) {
    assert(turn.needsVolley);
    final barrier = player.barrier != null ? wardFactor : 1.0;
    final damage =
        (turn.action.damagePerMiss * result.misses * _defendFactor * barrier)
            .round();
    player.hp = max(0, player.hp - damage);
    log.add('${turn.enemy.spec.name}の${turn.action.name} — '
        '${result.misses}/${result.total} slipped through for $damage');
    if (!player.alive) _finish(BattleOutcome.defeat);
  }

  void _inflictOnPlayer(StatusType status) {
    player.statuses[status] = statusRounds;
    if (status == StatusType.seal) {
      player.sealedCommand =
          sealableCommands[rng.nextInt(sealableCommands.length)];
      log.add('封印 — ${player.sealedCommand!.name.toUpperCase()} is sealed!');
    }
  }

  // --- end of round -------------------------------------------------------------

  void _endRound() {
    if (phase == BattlePhase.finished) return;

    // Burn ticks both sides.
    if (player.hasStatus(StatusType.burn)) {
      player.hp = max(0, player.hp - burnDotDamage);
      log.add('火傷 — you take $burnDotDamage burn damage');
    }
    for (final e in enemies) {
      if (e.alive && e.hasStatus(StatusType.burn)) {
        e.hp = max(0, e.hp - burnDotDamage);
        log.add('火傷 — ${e.spec.name} takes $burnDotDamage burn damage');
      }
    }

    _tickStatuses(player.statuses);
    if (!player.hasStatus(StatusType.seal)) player.sealedCommand = null;
    for (final e in enemies) {
      _tickStatuses(e.statuses);
    }
    final barrier = player.barrier;
    if (barrier != null) {
      barrier.roundsLeft--;
      if (barrier.roundsLeft <= 0) {
        player.barrier = null;
        log.add('The barrier fades.');
      }
    }
    if (player.atkBuffRounds > 0) {
      player.atkBuffRounds--;
      if (player.atkBuffRounds == 0) log.add('The empowerment fades.');
    }

    player.mp = min(playerMaxMp, player.mp + mpRegenPerRound);
    player.sp = min(playerMaxSp, player.sp + spRegenPerRound);
    _defendFactor = 1.0;
    round++;

    if (!player.alive) {
      _finish(BattleOutcome.defeat);
    } else if (aliveEnemies.isEmpty) {
      _finish(BattleOutcome.victory);
    } else {
      _startPlayerTurn();
    }
  }

  void _startPlayerTurn() {
    phase = BattlePhase.command;
    _alliesToAct = partySize;
    // Dead-ended (e.g. ATTACK sealed and no MP): the turn is lost. Statuses
    // tick each round, so a sealed menu always frees up eventually.
    if (!offenseCommands.any(canUse)) {
      log.add('Nothing you can do — the player turn slips away!');
      _enterReaction();
    }
  }

  void _tickStatuses(Map<StatusType, int> statuses) {
    for (final s in statuses.keys.toList()) {
      final left = statuses[s]! - 1;
      if (left <= 0) {
        statuses.remove(s);
      } else {
        statuses[s] = left;
      }
    }
  }

  void _finish(BattleOutcome o) {
    outcome = o;
    phase = BattlePhase.finished;
    log.add(o == BattleOutcome.victory ? 'Victory!' : 'Defeated…');
  }
}
