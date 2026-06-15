import 'dart:math';

import 'package:flutter/material.dart';

/// A one-shot radial burst — an expanding ring plus motes flung outward in
/// an element color — played when a spell resolves (DESIGN.md §3.7). Pass
/// the element [color] (e.g. `tagInfo[element].color`) and, optionally, the
/// element [glyph] to flash at the center. Removes itself via [onComplete].
///
/// Decoupled by design: takes a color, not an element enum, so it never
/// imports the battle/tag code.
class CastBurst extends StatefulWidget {
  const CastBurst({
    super.key,
    required this.color,
    this.glyph,
    this.size = 120,
    this.moteCount = 12,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
  });

  final Color color;
  final String? glyph;
  final double size;
  final int moteCount;
  final VoidCallback? onComplete;
  final Duration duration;

  @override
  State<CastBurst> createState() => _CastBurstState();
}

class _CastBurstState extends State<CastBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeOut.transform(_controller.value);
            return CustomPaint(
              painter: _BurstPainter(
                color: widget.color,
                t: t,
                moteCount: widget.moteCount,
              ),
              child: child,
            );
          },
          child: widget.glyph == null
              ? null
              : Center(
                  child: _BurstGlyph(
                    glyph: widget.glyph!,
                    color: widget.color,
                    controller: _controller,
                  ),
                ),
        ),
      ),
    );
  }
}

class _BurstGlyph extends StatelessWidget {
  const _BurstGlyph({
    required this.glyph,
    required this.color,
    required this.controller,
  });

  final String glyph;
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final scale = 0.6 + 0.8 * Curves.easeOut.transform(t);
        final opacity = (1 - t).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 44,
                color: color,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 12, color: color)],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.color,
    required this.t,
    required this.moteCount,
  });

  final Color color;
  final double t;
  final int moteCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    // Expanding ring that thins and fades as it grows.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1 - t) * 6 + 1
      ..color = color.withValues(alpha: (1 - t) * 0.8);
    canvas.drawCircle(center, maxRadius * t, ring);

    // Motes flung outward along evenly-spaced spokes.
    final mote = Paint()..color = color.withValues(alpha: (1 - t).clamp(0.0, 1.0));
    final moteRadius = maxRadius * (0.85 * t + 0.1);
    final dotSize = (1 - t) * 3 + 1;
    for (var i = 0; i < moteCount; i++) {
      final angle = (i / moteCount) * 2 * pi;
      final p = center + Offset(cos(angle), sin(angle)) * moteRadius;
      canvas.drawCircle(p, dotSize, mote);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
