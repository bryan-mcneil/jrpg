import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps a whole scene and shakes it on demand — reserved for weight:
/// boss "big attacks", amp-type (大) spells, a defeat (DESIGN.md §3.4, §3.7).
/// Trigger via a [GlobalKey]:
///
/// ```dart
/// final shakeKey = GlobalKey<ScreenShakeState>();
/// ScreenShake(key: shakeKey, child: battleBody);
/// shakeKey.currentState?.shake(intensity: 14); // boss slam
/// ```
class ScreenShake extends StatefulWidget {
  const ScreenShake({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 480),
  });

  final Widget child;
  final Duration duration;

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  final _random = Random();
  double _intensity = 10;

  /// Plays a decaying jitter. [intensity] is the peak displacement in
  /// logical pixels — keep it small (6–8) for light hits, larger (12–16)
  /// for telegraphed boss attacks.
  void shake({double intensity = 10}) {
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
        if (t == 0 || t == 1) return child!;
        final decay = (1 - t) * (1 - t);
        final amp = _intensity * decay;
        final offset = Offset(
          (_random.nextDouble() * 2 - 1) * amp,
          (_random.nextDouble() * 2 - 1) * amp,
        );
        return Transform.translate(offset: offset, child: child);
      },
      child: widget.child,
    );
  }
}
