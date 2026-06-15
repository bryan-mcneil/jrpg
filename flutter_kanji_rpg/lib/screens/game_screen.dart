import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Empty Flame scene from the M0 toolchain check: dark background with a
/// pulsing 火 glyph proving the render/update loop is alive.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flame Scene (M0)')),
      body: GameWidget(game: KanjiRpgGame()),
    );
  }
}

class KanjiRpgGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFF1A1423);

  @override
  Future<void> onLoad() async {
    add(_PulsingKanji());
  }
}

class _PulsingKanji extends TextComponent with HasGameReference {
  _PulsingKanji()
      : super(
          text: '火',
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: const TextStyle(fontSize: 96, color: Color(0xFFE25822)),
          ),
        );

  double _t = 0;

  @override
  void onMount() {
    super.onMount();
    position = game.size / 2;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = size / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    scale = Vector2.all(1 + 0.1 * sin(_t * 2 * pi));
  }
}
