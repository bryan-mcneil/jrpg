import 'dart:async';

import 'package:flutter/material.dart';

import '../backgrounds/battle_background.dart';
import '../battle/balance.dart';
import '../battle/elements.dart';
import '../battle/engine.dart';
import '../battle/items.dart';
import '../battle/models.dart';
import '../battle/question_bank.dart';
import '../battle/spells.dart';
import '../db/database.dart';
import '../fx/cast_burst.dart';
import '../fx/damage_number.dart';
import '../fx/hit_shake.dart';
import '../fx/screen_shake.dart';
import '../game/tags.dart';
import '../widgets/listen_question.dart';
import '../widgets/spell_canvas.dart';
import '../widgets/timed_question.dart';

/// What the bottom panel is showing.
enum _Mode { command, targeting, itemSelect, volley, spellCompose, banner }

/// M3 battle vertical slice (DESIGN.md §3.4–3.7): the four commands with
/// target selection, element matchups, the four statuses, and MAGIC by
/// drawing. The engine owns all the math; this screen runs quizzes and
/// feeds results back.
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.formation,
    required this.data,
    this.playerHp = playerMaxHp,
    this.recognizer,
    this.speaker,
  });

  final Formation formation;
  final BattleData data;
  final int playerHp;

  /// Test seam for the spell canvas.
  final InkRecognizerFn? recognizer;

  /// Test seam for listen-and-translate audio (null → device TTS).
  final SpeakerFn? speaker;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleEngine engine;

  _Mode _mode = _Mode.command;
  String _banner = '';

  // Volley state.
  List<BattleQuestion> _questions = [];
  Duration _questionDuration = questionTime;
  String? _volleyBanner;
  void Function(int correct, double avgTimeFrac)? _onVolleyDone;

  // Targeting state: a pending spell or item, or both null when targeting
  // for ATTACK.
  ResolvedSpell? _pendingSpell;
  ItemSpec? _pendingItem;

  // --- juice: the decoupled fx kit (lib/fx, lib/backgrounds) -----------------
  // Imperative GlobalKey triggers (the spell-canvas pattern); positioning and
  // overlay lifetimes are owned here so the fx widgets stay battle-agnostic.
  final _screenShakeKey = GlobalKey<ScreenShakeState>();
  final _stackKey = GlobalKey();
  final _playerShakeKey = GlobalKey<HitShakeState>();
  late final List<GlobalKey<HitShakeState>> _enemyShakeKeys;

  /// Live floating-text / cast-burst overlays, positioned over a card or the
  /// HUD; each removes itself on completion by [id].
  final List<({int id, Offset center, Widget widget})> _overlays = [];
  int _fxSeq = 0;

  QuestionBank get bank => widget.data.bank;

  /// Backdrop tint: the boss's element if there is one, else the lead enemy's.
  Color get _encounterColor {
    final lead = engine.enemies.firstWhere(
      (e) => e.spec.isBoss,
      orElse: () => engine.enemies.first,
    );
    return tagInfo[lead.spec.element.name]!.color;
  }

  @override
  void initState() {
    super.initState();
    engine = BattleEngine(
      widget.formation,
      player: PlayerState(maxHp: widget.playerHp),
    );
    _enemyShakeKeys = [
      for (final _ in widget.formation.enemies) GlobalKey<HitShakeState>(),
    ];
  }

  // --- fx plumbing -----------------------------------------------------------

  /// Center of [key]'s render box in the overlay [Stack]'s coordinate space,
  /// or null if it isn't laid out yet (then the cosmetic effect is skipped).
  Offset? _centerOf(GlobalKey key) {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || box == null || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero), ancestor: stack);
  }

  void _addOverlay(Offset center, Widget Function(VoidCallback remove) build) {
    final id = _fxSeq++;
    void remove() {
      if (!mounted) return;
      setState(() => _overlays.removeWhere((o) => o.id == id));
    }

    setState(
      () => _overlays.add((id: id, center: center, widget: build(remove))),
    );
  }

  /// Floats a number/word up from [anchor], nudged sideways so stacked hits
  /// don't perfectly overlap.
  void _floatText(GlobalKey anchor, String text, CombatTextKind kind) {
    final center = _centerOf(anchor);
    if (center == null) return;
    final nudged = center.translate((_fxSeq.isEven ? -1 : 1) * 12.0, 0);
    _addOverlay(
      nudged,
      (remove) =>
          FloatingCombatText(text: text, kind: kind, onComplete: remove),
    );
  }

  void _burst(GlobalKey anchor, Color color, String? glyph) {
    final center = _centerOf(anchor);
    if (center == null) return;
    _addOverlay(
      center,
      (remove) => CastBurst(color: color, glyph: glyph, onComplete: remove),
    );
  }

  /// Jolts enemy [index] and floats the damage it just took.
  void _hitEnemy(
    int index,
    int amount, {
    required Color flash,
    CombatTextKind kind = CombatTextKind.damage,
  }) {
    _enemyShakeKeys[index].currentState?.hit(flash: flash);
    if (amount > 0) _floatText(_enemyShakeKeys[index], '$amount', kind);
  }

  void _playCastFx(ResolvedSpell spell, CastReport report) {
    final color = tagInfo[spell.element.name]!.color;
    final glyph = elementGlyphs[spell.element];
    if (spell.modifier == ModifierClass.amp) {
      _screenShakeKey.currentState?.shake(intensity: 12);
    }
    for (final hit in report.hits) {
      _burst(_enemyShakeKeys[hit.enemyIndex], color, glyph);
      _hitEnemy(
        hit.enemyIndex,
        hit.damage,
        flash: color,
        // A weakness multiplier reads as a crit-gold pop.
        kind: hit.mult > 1 ? CombatTextKind.crit : CombatTextKind.damage,
      );
      if (hit.inflicted != null) {
        _floatText(
          _enemyShakeKeys[hit.enemyIndex],
          statusGlyphs[hit.inflicted]!,
          CombatTextKind.status,
        );
      } else if (hit.immune) {
        _floatText(_enemyShakeKeys[hit.enemyIndex], '無効', CombatTextKind.miss);
      }
    }
    if (report.heal > 0) {
      _burst(_playerShakeKey, color, glyph);
      _floatText(_playerShakeKey, '+${report.heal}', CombatTextKind.heal);
    }
    if (report.cleansed) {
      _floatText(_playerShakeKey, '浄化', CombatTextKind.status);
    }
    if (report.barrierSet) {
      _burst(_playerShakeKey, color, glyph);
      _floatText(_playerShakeKey, '結界', CombatTextKind.mana);
    }
    if (report.buffApplied) {
      _floatText(_playerShakeKey, '力↑', CombatTextKind.crit);
    }
  }

  void _playItemFx(ItemReport report, int? targetIndex) {
    if (report.hpHealed > 0) {
      _floatText(_playerShakeKey, '+${report.hpHealed}', CombatTextKind.heal);
    }
    if (report.mpRestored > 0) {
      _floatText(_playerShakeKey, '+${report.mpRestored}', CombatTextKind.mana);
    }
    if (report.spRestored > 0) {
      _floatText(
        _playerShakeKey,
        '+${report.spRestored}',
        CombatTextKind.status,
      );
    }
    if (report.empowered) {
      _floatText(_playerShakeKey, '力↑', CombatTextKind.crit);
    }
    if (targetIndex != null && report.inflicted != null) {
      _floatText(
        _enemyShakeKeys[targetIndex],
        statusGlyphs[report.inflicted]!,
        CombatTextKind.status,
      );
    } else if (targetIndex != null && report.immune) {
      _floatText(_enemyShakeKeys[targetIndex], '無効', CombatTextKind.miss);
    }
  }

  // --- volley plumbing -------------------------------------------------------

  Future<VolleyResult> _runVolley(
    List<BattleQuestion> questions,
    Duration duration, {
    String? banner,
  }) {
    final completer = Completer<VolleyResult>();
    setState(() {
      _mode = _Mode.volley;
      _questions = questions;
      _questionDuration = duration;
      _volleyBanner = banner;
      _onVolleyDone = (correct, frac) => completer.complete(
        VolleyResult(correct, questions.length, avgTimeFrac: frac),
      );
    });
    return completer.future;
  }

  Duration _scaled(double factor) =>
      Duration(milliseconds: (questionTime.inMilliseconds * factor).round());

  // --- player commands ---------------------------------------------------------

  Future<void> _attack(int target) async {
    final result = await _runVolley(
      bank.volley(
        attackQuestionCount,
        attackFormats,
        floor: engine.questionFloorFor(engine.enemies[target]),
      ),
      _scaled(engine.playerTimeFactor),
    );
    final before = engine.enemies[target].hp;
    engine.playerAttack(target, result);
    final crit = result.total > 0 && result.correct == result.total;
    _hitEnemy(
      target,
      before - engine.enemies[target].hp,
      flash: crit ? Colors.white : const Color(0xFFFF5A4D),
      kind: crit ? CombatTextKind.crit : CombatTextKind.damage,
    );
    await _proceed();
  }

  Future<void> _defend() async {
    final result = await _runVolley(
      bank.volley(
        defendQuestionCount,
        defendFormats,
        floor: engine.defendFloor,
      ),
      _scaled(engine.playerTimeFactor),
    );
    engine.playerDefend(result);
    await _proceed();
  }

  Future<void> _support() async {
    engine.playerSupport();
    await _proceed();
  }

  Future<void> _cast(ResolvedSpell spell, {int? targetIndex}) async {
    final report = engine.playerCast(spell, targetIndex: targetIndex);
    setState(() => _pendingSpell = null);
    _playCastFx(spell, report);
    await _proceed();
  }

  /// Advances to wherever the engine landed: runs the enemy actions when
  /// the NPC turn is under way, then shows the current phase's menu
  /// (reaction, or the next round's offense).
  Future<void> _proceed() async {
    if (engine.phase == BattlePhase.enemyPhase) await _enemyPhase();
    if (mounted) setState(() => _mode = _Mode.command);
  }

  void _spellComposed(ResolvedSpell spell) {
    if (spell.targetsSelf || spell.hitsAllEnemies) {
      _cast(spell);
    } else if (engine.aliveEnemies.length == 1) {
      _cast(
        spell,
        targetIndex: engine.enemies.indexOf(engine.aliveEnemies.single),
      );
    } else {
      setState(() {
        _pendingSpell = spell;
        _mode = _Mode.targeting;
      });
    }
  }

  void _targetChosen(int index) {
    final item = _pendingItem;
    if (item != null) {
      _useItem(item, targetIndex: index);
      return;
    }
    final spell = _pendingSpell;
    if (spell != null) {
      _cast(spell, targetIndex: index);
    } else {
      _attack(index);
    }
  }

  // --- items -----------------------------------------------------------------

  void _onItemPressed() => setState(() => _mode = _Mode.itemSelect);

  /// Picks a target for an ailment item when more than one enemy is alive,
  /// otherwise uses it straight away.
  void _selectItem(ItemSpec item) {
    if (item.targetsEnemy) {
      final alive = engine.aliveEnemies;
      if (alive.length == 1) {
        _useItem(item, targetIndex: engine.enemies.indexOf(alive.single));
      } else {
        setState(() {
          _pendingItem = item;
          _mode = _Mode.targeting;
        });
      }
    } else {
      _useItem(item);
    }
  }

  Future<void> _useItem(ItemSpec item, {int? targetIndex}) async {
    final report = engine.playerUseItem(item, targetIndex: targetIndex);
    setState(() => _pendingItem = null);
    _playItemFx(report, targetIndex);
    await _proceed();
  }

  // --- enemy phase --------------------------------------------------------------

  Future<void> _enemyPhase() async {
    while (mounted && engine.phase == BattlePhase.enemyPhase) {
      final turn = engine.nextEnemyTurn();
      if (turn == null) break;
      if (turn.needsVolley) {
        final result = await _runVolley(
          bank.volley(
            turn.action.questions,
            enemyFormats,
            floor: engine.questionFloorFor(turn.enemy),
          ),
          _scaled(engine.enemyVolleyTimeFactor(turn.enemy)),
          banner: '${turn.enemy.spec.name}の${turn.action.name}!',
        );
        final before = engine.player.hp;
        engine.resolveEnemyVolley(turn, result);
        final dealt = before - engine.player.hp;
        if (dealt > 0) {
          final big = turn.action.kind == EnemyActionKind.bigAttack;
          _playerShakeKey.currentState?.hit();
          _floatText(_playerShakeKey, '$dealt', CombatTextKind.damage);
          _screenShakeKey.currentState?.shake(intensity: big ? 14 : 7);
        }
        if (engine.outcome == BattleOutcome.defeat) {
          _screenShakeKey.currentState?.shake(intensity: 16);
        }
      } else {
        setState(() {
          _mode = _Mode.banner;
          _banner = engine.log.last;
        });
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }
  }

  // --- build ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1423),
      appBar: AppBar(
        title: Text('${widget.formation.name} — Round ${engine.round}'),
      ),
      body: BattleBackground(
        color: _encounterColor,
        child: ScreenShake(
          key: _screenShakeKey,
          child: SafeArea(
            child: Stack(
              key: _stackKey,
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < engine.enemies.length; i++)
                            Expanded(child: _enemyCard(i)),
                        ],
                      ),
                    ),
                    _logLine(),
                    const Divider(height: 1, color: Colors.white12),
                    _playerHud(),
                    Expanded(child: _bottomPanel()),
                  ],
                ),
                for (final o in _overlays)
                  Positioned(
                    left: o.center.dx,
                    top: o.center.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: o.widget,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logLine() {
    final text = engine.log.isEmpty ? '言霊よ、目覚めよ…' : engine.log.last;
    return InkWell(
      onTap: _showFullLog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          key: const Key('battle-log-last'),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showFullLog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Battle log'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final line in engine.log.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- enemy cards -----------------------------------------------------------------

  Widget _enemyCard(int index) {
    final enemy = engine.enemies[index];
    final info = tagInfo[enemy.spec.element.name]!;
    final targeting = _mode == _Mode.targeting && enemy.alive;
    return GestureDetector(
      key: Key('target-$index'),
      onTap: targeting ? () => _targetChosen(index) : null,
      child: HitShake(
        key: _enemyShakeKeys[index],
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          opacity: enemy.alive ? 1 : 0.25,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: targeting ? Colors.amber : Colors.white12,
                width: targeting ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${enemy.spec.name} ${info.glyph}',
                  style: TextStyle(fontSize: 12, color: info.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: enemy.spec.spritePath == null
                      ? _glyphSprite(enemy)
                      : Image.asset(
                          enemy.spec.spritePath!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (_, _, _) => _glyphSprite(enemy),
                        ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: enemy.hp / enemy.spec.maxHp,
                  minHeight: 6,
                  color: info.color,
                  backgroundColor: Colors.white12,
                ),
                Text(
                  '${enemy.hp}/${enemy.spec.maxHp}',
                  key: Key('enemy-hp-$index'),
                  style: const TextStyle(fontSize: 12),
                ),
                if (enemy.statuses.isNotEmpty || enemy.charging != null)
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final s in enemy.statuses.keys)
                        _statusBadge(statusGlyphs[s]!),
                      if (enemy.charging != null)
                        _statusBadge('⚡${enemy.charging}', color: Colors.amber),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glyphSprite(EnemyState enemy) => Center(
    child: Text(
      enemy.spec.glyph,
      style: TextStyle(
        fontSize: 52,
        color: tagInfo[enemy.spec.element.name]!.color,
      ),
    ),
  );

  Widget _statusBadge(
    String label, {
    Key? key,
    Color color = const Color(0xFFB57EDC),
  }) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      border: Border.all(color: color.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color)),
  );

  // --- player HUD --------------------------------------------------------------------

  Widget _playerHud() {
    final p = engine.player;
    return HitShake(
      key: _playerShakeKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _statBar('HP', p.hp, p.maxHp, Colors.green, key: 'player-hp'),
                const SizedBox(width: 8),
                _statBar(
                  'MP',
                  p.mp,
                  playerMaxMp,
                  Colors.blueAccent,
                  key: 'player-mp',
                ),
                const SizedBox(width: 8),
                _statBar(
                  'SP',
                  p.sp,
                  playerMaxSp,
                  Colors.amber,
                  key: 'player-sp',
                ),
              ],
            ),
            if (p.statuses.isNotEmpty ||
                p.barrier != null ||
                p.supportCharges > 0 ||
                p.atkBuffRounds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final s in p.statuses.keys)
                      _statusBadge(
                        s == StatusType.seal
                            ? '封印 ${p.sealedCommand?.name.toUpperCase()}'
                            : statusGlyphs[s]!,
                      ),
                    if (p.barrier != null)
                      _statusBadge(
                        '結界 ${elementGlyphs[p.barrier!.element]} '
                        '(${p.barrier!.roundsLeft})',
                        color: Colors.lightBlueAccent,
                      ),
                    if (p.atkBuffRounds > 0)
                      _statusBadge(
                        '力 +ATK (${p.atkBuffRounds})',
                        key: const Key('atk-buff'),
                        color: const Color(0xFFE0B341),
                      ),
                    if (p.supportCharges > 0)
                      _statusBadge(
                        'word-sprite ×${p.supportCharges}',
                        key: const Key('support-charges'),
                        color: Colors.amber,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBar(
    String label,
    int value,
    int max,
    Color color, {
    required String key,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label $value/$max',
            key: Key(key),
            style: const TextStyle(fontSize: 11),
          ),
          LinearProgressIndicator(
            value: max == 0 ? 0 : value / max,
            minHeight: 6,
            color: color,
            backgroundColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  // --- bottom panel --------------------------------------------------------------------

  Widget _bottomPanel() {
    if (engine.phase == BattlePhase.finished) return _resultView();
    return switch (_mode) {
      _Mode.command => _commandView(),
      _Mode.targeting => _targetingView(),
      _Mode.itemSelect => _itemSelectView(),
      _Mode.volley => _volleyView(),
      _Mode.spellCompose => _SpellComposer(
        data: widget.data,
        player: engine.player,
        recognizer: widget.recognizer,
        onCast: _spellComposed,
        onCancel: () => setState(() => _mode = _Mode.command),
      ),
      _Mode.banner => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _banner,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    };
  }

  /// The phase menu: the player turn offers ATTACK/MAGIC/ITEM, the NPC
  /// turn DEFEND/SUPPORT/ITEM (DESIGN.md §3.4). ITEM is live on both menus
  /// and disables only when the bag is empty.
  Widget _commandView() {
    final offense = engine.phase == BattlePhase.command;
    final commands = offense
        ? [
            (BattleCommand.attack, 'ATTACK', Icons.gavel, _onAttackPressed),
            (BattleCommand.magic, 'MAGIC', Icons.brush, _onMagicPressed),
            (BattleCommand.item, 'ITEM', Icons.backpack, _onItemPressed),
          ]
        : [
            (BattleCommand.defend, 'DEFEND', Icons.shield, _defend),
            (BattleCommand.support, 'SUPPORT', Icons.pets, _support),
            (BattleCommand.item, 'ITEM', Icons.backpack, _onItemPressed),
          ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offense ? 'Your turn' : 'Enemy turn — react!',
              key: const Key('phase-label'),
              style: TextStyle(
                fontSize: 15,
                color: offense ? Colors.amber : Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (final (cmd, label, icon, action) in commands)
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: SizedBox(
                      width: 116,
                      height: 56,
                      child: FilledButton.icon(
                        key: Key('cmd-${cmd.name}'),
                        onPressed: engine.canUse(cmd) ? action : null,
                        icon: Icon(
                          engine.player.sealedCommand == cmd &&
                                  engine.player.hasStatus(StatusType.seal)
                              ? Icons.lock
                              : icon,
                          size: 20,
                        ),
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onAttackPressed() {
    final alive = engine.aliveEnemies;
    if (alive.length == 1) {
      _attack(engine.enemies.indexOf(alive.single));
    } else {
      setState(() {
        _pendingSpell = null;
        _mode = _Mode.targeting;
      });
    }
  }

  void _onMagicPressed() => setState(() => _mode = _Mode.spellCompose);

  Widget _targetingView() {
    final prompt = _pendingItem != null
        ? 'Choose a target for ${_pendingItem!.name}'
        : _pendingSpell != null
        ? 'Choose a target for ${_pendingSpell!.description}'
        : 'Choose a target to ATTACK';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prompt, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            '(tap an enemy above)',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            key: const Key('target-cancel'),
            onPressed: () => setState(() {
              _pendingSpell = null;
              _pendingItem = null;
              _mode = _Mode.command;
            }),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// The bag: each carried item as a button labelled with its glyph, name,
  /// and remaining count. Empty entries are hidden; SP/MP/etc. effects show
  /// in the log after use.
  Widget _itemSelectView() {
    final owned = [
      for (final entry in engine.player.items.entries)
        if (entry.value > 0 && itemCatalog[entry.key] != null)
          (itemCatalog[entry.key]!, entry.value),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use an item',
              key: Key('item-header'),
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (owned.isEmpty)
              const Text(
                'The bag is empty.',
                style: TextStyle(color: Colors.white54),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final (item, count) in owned)
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                        width: 150,
                        height: 52,
                        child: FilledButton.tonal(
                          key: Key('item-${item.id}'),
                          onPressed: () => _selectItem(item),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.glyph,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${item.name} ×$count',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('item-cancel'),
              onPressed: () => setState(() => _mode = _Mode.command),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _volleyView() {
    return Center(
      child: SingleChildScrollView(
        child: VolleyRunner(
          key: ValueKey(
            'volley-${engine.round}-${engine.log.length}-$_volleyBanner',
          ),
          questions: _questions,
          questionDuration: _questionDuration,
          confused: engine.player.hasStatus(StatusType.confusion),
          consumeFiftyFifty: engine.consumeSupportCharge,
          recognizer: widget.recognizer,
          speaker: widget.speaker,
          banner: _volleyBanner == null
              ? null
              : Container(
                  width: double.infinity,
                  color: const Color(0xFF3A2438),
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    _volleyBanner!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
          onDone: (correct, frac) {
            final cb = _onVolleyDone;
            _onVolleyDone = null;
            cb?.call(correct, frac);
          },
        ),
      ),
    );
  }

  Widget _resultView() {
    final won = engine.outcome == BattleOutcome.victory;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            won ? Icons.emoji_events : Icons.dangerous,
            size: 64,
            color: won ? Colors.amber : Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            won ? 'Victory!' : 'Defeated…',
            key: Key(won ? 'battle-victory' : 'battle-defeat'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            won
                ? 'The stolen words return to the land.\n'
                      '(KP & coin rewards arrive with the M4 economy.)'
                : 'The Forgetting claims this bout — study and return.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('battle-continue'),
            // Hand the result back so a world-map node can mark itself cleared
            // and unlock the next (callers that don't care just ignore it).
            onPressed: () => Navigator.of(context).pop(engine.outcome),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// --- spell composer ------------------------------------------------------------

typedef _Slot = ({KanjiEntry entry, double grade});

/// MAGIC: draw an element kanji, optionally a modifier kanji, cast
/// (DESIGN.md §3.7). Grammar mistakes show a teaching message and retries
/// are free — only the cast spends MP.
class _SpellComposer extends StatefulWidget {
  const _SpellComposer({
    required this.data,
    required this.player,
    required this.onCast,
    required this.onCancel,
    this.recognizer,
  });

  final BattleData data;
  final PlayerState player;
  final InkRecognizerFn? recognizer;
  final void Function(ResolvedSpell) onCast;
  final VoidCallback onCancel;

  @override
  State<_SpellComposer> createState() => _SpellComposerState();
}

class _SpellComposerState extends State<_SpellComposer> {
  final _canvasKey = GlobalKey<SpellCanvasState>();

  final List<_Slot?> _slots = [null, null];
  int _activeSlot = 0;
  String? _message;
  int _matchSeq = 0;

  Future<void> _onCandidates(List<String> candidates, Duration elapsed) async {
    final seq = ++_matchSeq;
    for (var rank = 0; rank < candidates.length; rank++) {
      final entry = await widget.data.castable(candidates[rank]);
      if (entry == null) continue;
      if (!mounted || seq != _matchSeq) return;
      setState(() {
        _slots[_activeSlot] = (
          entry: entry,
          grade: drawingGrade(candidateRank: rank, elapsed: elapsed),
        );
        _message = null;
      });
      return;
    }
    if (!mounted || seq != _matchSeq) return;
    setState(() {
      _slots[_activeSlot] = null;
      _message = candidates.isEmpty
          ? null
          : 'No castable kanji recognized — only learned kanji answer the call.';
    });
  }

  SpellGrammarResult? get _grammar {
    final first = _slots[0];
    if (first == null) return null;
    final grade = _slots[1] == null
        ? first.grade
        : (first.grade + _slots[1]!.grade) / 2;
    return resolveSpell(first.entry, _slots[1]?.entry, grade: grade);
  }

  void _clearActive() {
    _canvasKey.currentState?.clear();
    setState(() {
      _slots[_activeSlot] = null;
      _message = null;
      _matchSeq++;
    });
  }

  void _toModifierSlot() {
    _canvasKey.currentState?.clear();
    setState(() {
      _activeSlot = 1;
      _matchSeq++;
    });
  }

  Widget _slotChip(int index) {
    final slot = _slots[index];
    final active = _activeSlot == index;
    final label = slot == null
        ? (index == 0 ? 'element…' : 'modifier…')
        : slot.entry.literal;
    return Container(
      key: Key('spell-slot-$index'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? Colors.amber : Colors.white24,
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 22)),
          if (slot != null) ...[
            const SizedBox(width: 6),
            Text(
              '${tagInfo[slot.entry.tag]?.glyph} ${slot.entry.tag} '
              '· ${slot.entry.strokeCount}画',
              style: TextStyle(
                fontSize: 11,
                color: tagInfo[slot.entry.tag]?.color ?? Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grammar = _grammar;
    final spell = grammar is SpellOk ? grammar.spell : null;
    final grammarMessage = grammar is SpellGrammarError
        ? grammar.message
        : null;
    final mpShort = spell != null && spell.mpCost > widget.player.mp;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _slotChip(0),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('＋'),
              ),
              _slotChip(1),
              const SizedBox(width: 10),
              Text(
                spell == null ? 'MP —' : 'MP ${spell.mpCost}',
                key: const Key('spell-mp-cost'),
                style: TextStyle(
                  color: mpShort ? Colors.redAccent : Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SpellCanvas(
              key: _canvasKey,
              recognizer: widget.recognizer,
              onCandidates: _onCandidates,
            ),
          ),
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                _message ??
                    grammarMessage ??
                    (mpShort
                        ? 'Not enough MP — ${spell.mpCost} needed.'
                        : spell != null
                        ? '${spell.description} — '
                              '${spell.totalStrokes} strokes ready'
                        : 'Draw a learned element kanji (木火土金水…).'),
                key: const Key('spell-message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _message != null || grammarMessage != null || mpShort
                      ? Colors.orangeAccent
                      : Colors.white70,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                key: const Key('spell-clear'),
                onPressed: _clearActive,
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              if (_activeSlot == 0)
                OutlinedButton(
                  key: const Key('spell-add-modifier'),
                  onPressed: _slots[0] != null ? _toModifierSlot : null,
                  child: const Text('＋Modifier'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('spell-cast'),
                onPressed: spell != null && !mpShort
                    ? () => widget.onCast(spell)
                    : null,
                child: const Text('Cast'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const Key('spell-cancel'),
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
