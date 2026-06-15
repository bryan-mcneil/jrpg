import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import 'quest_map.dart';

/// The Super Mario World-style node map (DESIGN.md §3.2), rendered in Flame:
/// nodes joined by paths, a walking avatar that hops node-to-node, and a
/// tap-to-walk-then-act flow. All math lives in [QuestMap]/[QuestProgress];
/// this layer is pure presentation + input. Node coordinates are fractions of
/// the playfield, so the same map lays out at any device size.
class WorldMapGame extends FlameGame {
  WorldMapGame({
    required this.map,
    required this.progress,
    required this.onNodeActivated,
    this.onStep,
  });

  final QuestMap map;
  final QuestProgress progress;

  /// Fired when the avatar arrives at a tapped node (or re-taps where it
  /// stands) — the screen opens the quest sheet from here.
  final void Function(QuestNode node) onNodeActivated;

  /// One footstep tick while walking; the screen turns this into a SFX so the
  /// game stays free of plugin calls (keeps it testable).
  final VoidCallback? onStep;

  late final _Avatar _avatar;
  final List<_NodeMarker> _markers = [];
  late final _PathLayer _paths;

  /// Node the avatar currently stands on.
  late String currentNodeId;

  final Map<String, Vector2> _pixels = {};

  /// Insets so nodes (and the tall avatar above them) never clip the edges.
  static final _margin = Vector2(40, 56);

  bool get isBusy => _avatar.isMoving;

  Vector2 pixelOf(QuestNode node) =>
      _pixels[node.id] ?? Vector2.zero();

  @override
  Color backgroundColor() => const Color(0xFF20281C);

  @override
  Future<void> onLoad() async {
    currentNodeId = _initialNode().id;

    add(_Backdrop()..priority = -10);

    _paths = _PathLayer(this);
    add(_paths);

    for (final node in map.nodes) {
      final marker = _NodeMarker(node: node, onTap: _handleTap);
      _markers.add(marker);
      add(marker);
    }

    _avatar = _Avatar(onStep: onStep);
    images.prefix = 'assets/art/';
    await _avatar.loadSheet(images);
    add(_avatar);

    if (!size.isZero()) _relayout();
    refresh();
  }

  /// The avatar starts at the furthest node already cleared (so a returning
  /// player resumes where they left off), else at the very first node.
  QuestNode _initialNode() {
    for (final node in map.nodes.reversed) {
      if (progress.isCleared(node.id)) return node;
    }
    return map.nodes.first;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!size.isZero() && isLoaded) _relayout();
  }

  void _relayout() {
    final field = size - _margin * 2;
    for (final node in map.nodes) {
      _pixels[node.id] =
          _margin + Vector2(node.x * field.x, node.y * field.y);
    }
    for (final marker in _markers) {
      marker.position = pixelOf(marker.node);
    }
    _paths.size = size;
    if (!_avatar.isMoving) {
      _avatar.position = pixelOf(map.nodeById(currentNodeId));
    }
  }

  /// Re-reads [progress] and repaints node/path states. Call after a battle
  /// result changes what is cleared.
  void refresh() {
    for (final marker in _markers) {
      marker.state = _stateOf(marker.node);
    }
  }

  _NodeVisualState _stateOf(QuestNode node) {
    if (progress.isCleared(node.id)) return _NodeVisualState.cleared;
    if (progress.isUnlocked(node)) return _NodeVisualState.available;
    return _NodeVisualState.locked;
  }

  void _handleTap(QuestNode node) {
    if (isBusy) return;
    if (node.id == currentNodeId) {
      onNodeActivated(node);
      return;
    }
    if (!progress.isUnlocked(node)) return; // locked — not yet reachable
    _avatar.walkTo(pixelOf(node), onArrive: () {
      currentNodeId = node.id;
      onNodeActivated(node);
    });
  }
}

/// Soft top-down gradient so the map reads like terrain until the Tiled
/// backdrop pipeline lands in M4.5.
class _Backdrop extends PositionComponent with HasGameReference<WorldMapGame> {
  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & game.size.toSize();
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        const [Color(0xFF3E5A34), Color(0xFF6B5A38)],
      );
    canvas.drawRect(rect, paint);
  }
}

class _PathLayer extends PositionComponent {
  _PathLayer(this.game) : super(priority: 0);

  final WorldMapGame game;

  final _lit = Paint()
    ..color = const Color(0xFFD9C58A)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  final _dim = Paint()
    ..color = const Color(0x55FFFFFF)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    for (final (from, to) in game.map.edges()) {
      // A segment lights up once its source node is cleared — the trodden path.
      final paint = game.progress.isCleared(from.id) ? _lit : _dim;
      canvas.drawLine(
          game.pixelOf(from).toOffset(), game.pixelOf(to).toOffset(), paint);
    }
  }
}

enum _NodeVisualState { locked, available, cleared }

const _nodeGlyph = {
  QuestNodeType.lesson: '学',
  QuestNodeType.npc: '話',
  QuestNodeType.skirmish: '戦',
  QuestNodeType.dungeon: '洞',
  QuestNodeType.boss: '鬼',
};

class _NodeMarker extends PositionComponent with TapCallbacks {
  _NodeMarker({required this.node, required this.onTap})
      : super(anchor: Anchor.center, size: Vector2.all(_radius * 2 + 8), priority: 1);

  final QuestNode node;
  final void Function(QuestNode node) onTap;

  static const _radius = 19.0;
  static const _gold = Color(0xFFE0B341);
  static const _green = Color(0xFF5FB05F);
  static const _grey = Color(0xFF7A7A7A);

  _NodeVisualState state = _NodeVisualState.locked;
  double _t = 0;

  late final TextPaint _label = TextPaint(
    style: const TextStyle(
      fontSize: 18,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final centerV = size / 2;
    final center = centerV.toOffset();
    final color = switch (state) {
      _NodeVisualState.locked => _grey,
      _NodeVisualState.available => _gold,
      _NodeVisualState.cleared => _green,
    };
    final locked = state == _NodeVisualState.locked;

    // A gold pulse ring marks the node(s) the player can act on now.
    if (state == _NodeVisualState.available) {
      final pulse = 2 + 2 * (0.5 + 0.5 * (_t * 3).remainder(6.283) / 6.283);
      canvas.drawCircle(
        center,
        _radius + pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _gold.withValues(alpha: 0.6),
      );
    }

    canvas.drawCircle(
        center, _radius, Paint()..color = color.withValues(alpha: locked ? 0.3 : 1));
    canvas.drawCircle(
      center,
      _radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFF1A1423).withValues(alpha: locked ? 0.4 : 1),
    );

    _label.render(
      canvas,
      _nodeGlyph[node.type]!,
      centerV,
      anchor: Anchor.center,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(node);
    event.handled = true;
  }
}

/// The player's walking sprite — a Time Fantasy 3×4 RPG-Maker sheet (3 walk
/// frames × 4 facings: down/left/right/up, 78×108 per cell). Idle holds the
/// middle frame of a facing.
class _Avatar extends SpriteAnimationGroupComponent<String> {
  _Avatar({this.onStep})
      : super(anchor: Anchor.bottomCenter, size: Vector2(40, 55), priority: 10);

  final VoidCallback? onStep;

  static final _cell = Vector2(78, 108);
  static const _speed = 130.0; // px/sec
  static const _stepEvery = 0.26; // footstep cadence while walking

  bool isMoving = false;
  bool _ready = false;
  double _stepAccum = 0;

  late final TextPaint _token = TextPaint(
    style: const TextStyle(fontSize: 34, color: Colors.white),
  );

  Future<void> loadSheet(Images cache) async {
    try {
      final ui.Image sheet = await cache.load('samurai.png');
      SpriteAnimation walk(int row) => SpriteAnimation.fromFrameData(
            sheet,
            SpriteAnimationData.sequenced(
              amount: 3,
              stepTime: 0.16,
              textureSize: _cell,
              texturePosition: Vector2(0, row * _cell.y),
            ),
          );
      SpriteAnimation idle(int row) => SpriteAnimation.spriteList(
            [
              Sprite(sheet,
                  srcPosition: Vector2(_cell.x, row * _cell.y), srcSize: _cell),
            ],
            stepTime: double.infinity,
          );
      // Sheet row order: down, left, right, up.
      animations = {
        'idle_down': idle(0),
        'idle_left': idle(1),
        'idle_right': idle(2),
        'idle_up': idle(3),
        'walk_down': walk(0),
        'walk_left': walk(1),
        'walk_right': walk(2),
        'walk_up': walk(3),
      };
      current = 'idle_down';
      _ready = true;
    } catch (_) {
      // No sprite bundled (assets/art/*.png is gitignored placeholder art) —
      // degrade to a glyph token, same philosophy as the battle sprites. The
      // map stays fully playable.
      _ready = false;
    }
  }

  void _face(String key) {
    if (_ready) current = key;
  }

  void walkTo(Vector2 target, {required VoidCallback onArrive}) {
    final delta = target - position;
    final dir = delta.x.abs() > delta.y.abs()
        ? (delta.x < 0 ? 'left' : 'right')
        : (delta.y < 0 ? 'up' : 'down');
    _face('walk_$dir');
    isMoving = true;
    _stepAccum = 0;
    final duration = (delta.length / _speed).clamp(0.2, 2.5);
    add(MoveToEffect(
      target,
      EffectController(duration: duration),
      onComplete: () {
        isMoving = false;
        _face('idle_$dir');
        onArrive();
      },
    ));
  }

  @override
  void render(Canvas canvas) {
    if (_ready) {
      super.render(canvas);
      return;
    }
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 4, size.x - 4, size.y - 6),
      const Radius.circular(8),
    );
    canvas.drawRRect(box, Paint()..color = const Color(0xFF8A4B3B));
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF1A1423),
    );
    _token.render(canvas, '侍', size / 2, anchor: Anchor.center);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMoving) return;
    _stepAccum += dt;
    if (_stepAccum >= _stepEvery) {
      _stepAccum -= _stepEvery;
      onStep?.call();
    }
  }
}
