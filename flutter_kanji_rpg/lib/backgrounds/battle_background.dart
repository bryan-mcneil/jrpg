import 'dart:math';

import 'package:flutter/material.dart';

/// The deep base every scene sits on — matches the existing menu/Flame
/// background so painted backdrops blend with the rest of the app.
const kSceneBase = Color(0xFF1A1423);

/// A painted, element-tinted battle backdrop: a vertical gradient sky, a
/// grounded glow where the fight stands, and slow drifting motes (rescued
/// word-spirits, DESIGN.md §3.9). Procedural so it needs none of the
/// gitignored Time Fantasy art; a purchased parallax can replace it later
/// by swapping this widget out.
///
/// Takes a [color] (pass the encounter's element color), not an element
/// enum, so it stays independent of the battle/tag code.
class BattleBackground extends StatefulWidget {
  const BattleBackground({
    super.key,
    required this.color,
    this.child,
    this.animate = true,
    this.moteCount = 18,
  });

  /// Element seed color. The sky is a darkened wash of it.
  final Color color;
  final Widget? child;

  /// Disable for golden/widget tests so the repeating controller doesn't
  /// block `pumpAndSettle`.
  final bool animate;
  final int moteCount;

  @override
  State<BattleBackground> createState() => _BattleBackgroundState();
}

class _BattleBackgroundState extends State<BattleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    // Fixed seed → deterministic layout (stable goldens, no test flake).
    final rng = Random(0xC0FFEE);
    _motes = [
      for (var i = 0; i < widget.moteCount; i++)
        _Mote(
          x: rng.nextDouble(),
          phase: rng.nextDouble(),
          speed: 0.4 + rng.nextDouble() * 0.8,
          radius: 0.6 + rng.nextDouble() * 1.8,
          drift: rng.nextDouble() * 2 - 1,
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _BattleBackgroundPainter(
            color: widget.color,
            motes: _motes,
            t: _controller.value,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Mote {
  const _Mote({
    required this.x,
    required this.phase,
    required this.speed,
    required this.radius,
    required this.drift,
  });

  /// Horizontal anchor 0..1; vertical position derives from time + phase.
  final double x;
  final double phase;
  final double speed;
  final double radius;

  /// Sideways sway amount, -1..1.
  final double drift;
}

class _BattleBackgroundPainter extends CustomPainter {
  _BattleBackgroundPainter({
    required this.color,
    required this.motes,
    required this.t,
  });

  final Color color;
  final List<_Mote> motes;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hsl = HSLColor.fromColor(color);
    final skyTop = hsl.withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)).toColor();

    // Sky: element wash up top fading into the deep base.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, kSceneBase],
          stops: const [0.0, 0.7],
        ).createShader(rect),
    );

    // Ground glow: a soft elliptical pool of element light near the bottom.
    final groundCenter = Offset(size.width / 2, size.height * 0.86);
    canvas.drawOval(
      Rect.fromCenter(
          center: groundCenter,
          width: size.width * 1.2,
          height: size.height * 0.4),
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.28), Colors.transparent],
        ).createShader(Rect.fromCenter(
            center: groundCenter,
            width: size.width * 1.2,
            height: size.height * 0.4)),
    );

    // Drifting motes rising through the scene.
    final motePaint = Paint();
    for (final m in motes) {
      final progress = (t * m.speed + m.phase) % 1.0;
      final y = size.height * (1 - progress);
      final x = (m.x + m.drift * 0.06 * sin(progress * 2 * pi)) * size.width;
      // Brightest mid-rise, fading at the top and bottom edges.
      final alpha = (sin(progress * pi)).clamp(0.0, 1.0) * 0.7;
      motePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), m.radius, motePaint);
    }
  }

  @override
  bool shouldRepaint(_BattleBackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
