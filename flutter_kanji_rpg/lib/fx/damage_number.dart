import 'package:flutter/material.dart';

/// What a piece of floating combat text means, which fixes its color and
/// any glyph prefix. Battle feedback for DESIGN.md §3.4–3.6 (damage, heals,
/// misses, status ticks) — the engine owns the numbers, this only displays.
enum CombatTextKind {
  damage(Color(0xFFFF5A4D)),
  crit(Color(0xFFFFC857)),
  heal(Color(0xFF6FCF73), prefix: '+'),
  mana(Color(0xFF5AA9E6), prefix: '+'),
  miss(Color(0xFFB8B8C0)),
  status(Color(0xFFB57EDC));

  const CombatTextKind(this.color, {this.prefix = ''});

  final Color color;
  final String prefix;
}

/// A single number (or word) that floats upward and fades, then removes
/// itself by calling [onComplete]. Drop one over an enemy card or the
/// player HUD when a hit lands; spawn fresh instances per hit rather than
/// reusing one.
///
/// Self-contained: takes only a value + kind, so the battle screen can wire
/// it in with a one-liner once it adopts the kit.
class FloatingCombatText extends StatefulWidget {
  const FloatingCombatText({
    super.key,
    required this.text,
    this.kind = CombatTextKind.damage,
    this.onComplete,
    this.rise = 36,
    this.duration = const Duration(milliseconds: 850),
  });

  /// Convenience for the common case: an integer amount.
  factory FloatingCombatText.amount(
    int amount, {
    Key? key,
    CombatTextKind kind = CombatTextKind.damage,
    VoidCallback? onComplete,
  }) =>
      FloatingCombatText(
        key: key,
        text: '${kind.prefix}$amount',
        kind: kind,
        onComplete: onComplete,
      );

  final String text;
  final CombatTextKind kind;
  final VoidCallback? onComplete;

  /// Logical pixels the text drifts up over its lifetime.
  final double rise;
  final Duration duration;

  @override
  State<FloatingCombatText> createState() => _FloatingCombatTextState();
}

class _FloatingCombatTextState extends State<FloatingCombatText>
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
    final isCrit = widget.kind == CombatTextKind.crit;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          // A quick pop-in scale, then hold; fade lives in the last third.
          final scale = isCrit ? 1.0 + 0.6 * (1 - t) : 0.8 + 0.2 * (t * 3).clamp(0.0, 1.0);
          final opacity = (1 - (t - 0.66) / 0.34).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -widget.rise * Curves.easeOut.transform(t)),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: isCrit ? 28 : 20,
            fontWeight: FontWeight.bold,
            color: widget.kind.color,
            height: 1,
            shadows: const [
              Shadow(blurRadius: 0, offset: Offset(1, 1), color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
