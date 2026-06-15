import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps a sprite/card and, on [HitShakeState.hit], jolts it sideways and
/// flashes a tint — the "I got hit" feedback for enemy cards and the player
/// HUD (DESIGN.md §3.4). Trigger it imperatively via a [GlobalKey], the same
/// pattern the spell canvas uses:
///
/// ```dart
/// final key = GlobalKey<HitShakeState>();
/// HitShake(key: key, child: enemyCard);
/// // when damage lands:
/// key.currentState?.hit();
/// ```
class HitShake extends StatefulWidget {
  const HitShake({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
  });

  final Widget child;
  final Duration duration;

  @override
  State<HitShake> createState() => HitShakeState();
}

class HitShakeState extends State<HitShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  Color _flash = const Color(0xFFFF5A4D);
  double _intensity = 8;

  /// Plays the jolt. [flash] tints the child (white for a crit, red for a
  /// plain hit, an element color for typed magic); [intensity] is the peak
  /// horizontal offset in logical pixels.
  void hit({Color flash = const Color(0xFFFF5A4D), double intensity = 8}) {
    _flash = flash;
    _intensity = intensity;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Damped oscillation: a few shakes that decay to rest.
        final dx = t == 0
            ? 0.0
            : sin(t * pi * 6) * _intensity * (1 - t);
        final flashOpacity = t == 0 ? 0.0 : (1 - t) * 0.55;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Stack(
            children: [
              child!,
              if (flashOpacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: _flash.withValues(alpha: flashOpacity),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
