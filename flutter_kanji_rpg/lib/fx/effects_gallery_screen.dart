import 'dart:math';

import 'package:flutter/material.dart';

import '../backgrounds/battle_background.dart';
import '../backgrounds/menu_background.dart';
import 'cast_burst.dart';
import 'damage_number.dart';
import 'hit_shake.dart';
import 'screen_shake.dart';

/// A standalone preview of the fx kit and painted backgrounds, reachable from
/// the dev menu ("FX Gallery"). Use it to play with each effect in isolation,
/// or as the harness for the widget tests. It keeps its own element swatches so
/// it never imports the battle/tag code.
class EffectsGalleryScreen extends StatefulWidget {
  const EffectsGalleryScreen({super.key});

  @override
  State<EffectsGalleryScreen> createState() => _EffectsGalleryScreenState();
}

/// A few element seeds for the preview. Kept local on purpose so the gallery
/// never imports the battle/tag code; the real screens pass
/// `tagInfo[element].color`.
const _swatches = <String, Color>{
  '火 Fire': Color(0xFFE25822),
  '水 Water': Color(0xFF3B82C4),
  '木 Wood': Color(0xFF4C9A4C),
  '金 Metal': Color(0xFFB0A654),
  '闇 Dark': Color(0xFF7B5EA7),
};

class _EffectsGalleryScreenState extends State<EffectsGalleryScreen> {
  final _shakeKey = GlobalKey<ScreenShakeState>();
  final _hitKey = GlobalKey<HitShakeState>();
  final _rng = Random();

  final List<({int id, Widget child})> _overlays = [];
  int _nextId = 0;

  Color _bg = _swatches.values.first;
  bool _showMenuBg = false;

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _overlays.removeWhere((e) => e.id == id));
  }

  void _spawnOverlay(Widget Function(VoidCallback remove) build) {
    final id = _nextId++;
    setState(() => _overlays.add((id: id, child: build(() => _remove(id)))));
  }

  void _floating(CombatTextKind kind) {
    final amount = 1 + _rng.nextInt(80);
    final dx = (_rng.nextDouble() * 2 - 1) * 0.4;
    _spawnOverlay((remove) => Align(
          alignment: Alignment(dx, -0.1),
          child: kind == CombatTextKind.miss
              ? FloatingCombatText(
                  text: 'MISS', kind: kind, onComplete: remove)
              : FloatingCombatText.amount(amount, kind: kind, onComplete: remove),
        ));
  }

  void _burst() {
    _spawnOverlay((remove) => Align(
          alignment: const Alignment(0, -0.1),
          child: CastBurst(color: _bg, glyph: '火', onComplete: remove),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FX & Background gallery')),
      body: ScreenShake(
        key: _shakeKey,
        child: Column(
          children: [
            Expanded(flex: 3, child: _stage()),
            const Divider(height: 1),
            // Flexible + internal scroll keeps the controls from overflowing
            // on short screens.
            Flexible(flex: 2, child: _controls()),
          ],
        ),
      ),
    );
  }

  Widget _stage() {
    final stageContent = Stack(
      alignment: Alignment.center,
      children: [
        // Sample target: a glyph "sprite" that shakes when hit.
        HitShake(
          key: _hitKey,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('鬼',
                style: TextStyle(fontSize: 56, color: _bg.withValues(alpha: 0.9))),
          ),
        ),
        ..._overlays.map((e) => e.child),
      ],
    );

    return _showMenuBg
        ? MenuBackground(child: Center(child: stageContent))
        : BattleBackground(color: _bg, child: Center(child: stageContent));
  }

  Widget _controls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Background', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                key: const Key('toggle-menu-bg'),
                label: const Text('Menu drift'),
                selected: _showMenuBg,
                onSelected: (v) => setState(() => _showMenuBg = v),
              ),
              for (final entry in _swatches.entries)
                ChoiceChip(
                  label: Text(entry.key),
                  selected: !_showMenuBg && _bg == entry.value,
                  onSelected: (_) => setState(() {
                    _bg = entry.value;
                    _showMenuBg = false;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Effects', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                key: const Key('fx-damage'),
                onPressed: () {
                  _floating(CombatTextKind.damage);
                  _hitKey.currentState?.hit();
                },
                child: const Text('Damage'),
              ),
              FilledButton(
                key: const Key('fx-crit'),
                onPressed: () {
                  _floating(CombatTextKind.crit);
                  _hitKey.currentState?.hit(flash: Colors.white, intensity: 12);
                },
                child: const Text('Crit'),
              ),
              FilledButton.tonal(
                key: const Key('fx-heal'),
                onPressed: () => _floating(CombatTextKind.heal),
                child: const Text('Heal'),
              ),
              FilledButton.tonal(
                key: const Key('fx-mana'),
                onPressed: () => _floating(CombatTextKind.mana),
                child: const Text('Mana'),
              ),
              OutlinedButton(
                key: const Key('fx-miss'),
                onPressed: () => _floating(CombatTextKind.miss),
                child: const Text('Miss'),
              ),
              FilledButton(
                key: const Key('fx-burst'),
                onPressed: _burst,
                child: const Text('Cast burst'),
              ),
              FilledButton(
                key: const Key('fx-screenshake'),
                onPressed: () => _shakeKey.currentState?.shake(intensity: 14),
                child: const Text('Screen shake'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
