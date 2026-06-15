import 'dart:math';

import 'package:flutter/material.dart';

import 'battle_background.dart' show kSceneBase;

/// Faint kanji glyphs drifting upward through the dark — the menu/title
/// ambiance. Thematically the 言霊 (word-spirits) returning to the world
/// (DESIGN.md §3.9). Put it behind menu content with a [child].
///
/// Pure widgets + a [CustomPaint] layer; no art assets required.
class MenuBackground extends StatefulWidget {
  const MenuBackground({
    super.key,
    this.child,
    this.animate = true,
    this.tint = const Color(0xFFE25822),
    this.glyphs = _defaultGlyphs,
  });

  final Widget? child;

  /// Disable for tests so the repeating controller settles.
  final bool animate;

  /// Accent the drifting glyphs lean toward (defaults to the 火 ember used
  /// on the current home menu).
  final Color tint;
  final List<String> glyphs;

  static const _defaultGlyphs = [
    '木', '火', '土', '金', '水', '光', '闇', '言', '霊', '忘', '剣', '癒',
  ];

  @override
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final List<_Glyph> _drift;

  @override
  void initState() {
    super.initState();
    final rng = Random(0x5C21BE);
    _drift = [
      for (var i = 0; i < 14; i++)
        _Glyph(
          glyph: widget.glyphs[rng.nextInt(widget.glyphs.length)],
          x: rng.nextDouble(),
          phase: rng.nextDouble(),
          speed: 0.25 + rng.nextDouble() * 0.5,
          scale: 0.5 + rng.nextDouble() * 1.4,
          sway: rng.nextDouble() * 2 - 1,
        ),
    ];
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kSceneBase,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            painter: _MenuBackgroundPainter(
              glyphs: _drift,
              tint: widget.tint,
              t: _controller.value,
              textDirection: Directionality.of(context),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Glyph {
  const _Glyph({
    required this.glyph,
    required this.x,
    required this.phase,
    required this.speed,
    required this.scale,
    required this.sway,
  });

  final String glyph;
  final double x;
  final double phase;
  final double speed;
  final double scale;
  final double sway;
}

class _MenuBackgroundPainter extends CustomPainter {
  _MenuBackgroundPainter({
    required this.glyphs,
    required this.tint,
    required this.t,
    required this.textDirection,
  });

  final List<_Glyph> glyphs;
  final Color tint;
  final double t;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    for (final g in glyphs) {
      final progress = (t * g.speed + g.phase) % 1.0;
      final y = size.height * (1 - progress);
      final x = (g.x + g.sway * 0.05 * sin(progress * 2 * pi)) * size.width;
      // Deeper (smaller) glyphs are dimmer; everything fades at the edges.
      final edgeFade = sin(progress * pi).clamp(0.0, 1.0);
      final alpha = edgeFade * (0.04 + 0.08 * (g.scale / 1.9));

      final painter = TextPainter(
        text: TextSpan(
          text: g.glyph,
          style: TextStyle(
            fontSize: 40 * g.scale,
            color: Color.lerp(Colors.white, tint, 0.5)!
                .withValues(alpha: alpha),
          ),
        ),
        textDirection: textDirection,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(_MenuBackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.tint != tint;
}
