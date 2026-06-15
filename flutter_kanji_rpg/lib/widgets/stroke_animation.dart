import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../data/kanjivg_strokes.dart' show kanjiVgSize;

/// Looping KanjiVG stroke-order animation: strokes draw themselves in
/// order over a faint ghost, then the loop restarts.
class KanjiStrokeAnimation extends StatefulWidget {
  const KanjiStrokeAnimation({
    super.key,
    required this.strokePaths,
    this.size = 160,
  });

  final List<String> strokePaths;
  final double size;

  @override
  State<KanjiStrokeAnimation> createState() => _KanjiStrokeAnimationState();
}

class _KanjiStrokeAnimationState extends State<KanjiStrokeAnimation>
    with SingleTickerProviderStateMixin {
  static const _secondsPerStroke = 0.6;
  static const _pauseSeconds = 1.0;

  late List<Path> _paths;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _paths = [for (final d in widget.strokePaths) parseSvgPathData(d)];
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: (widget.strokePaths.length * _secondsPerStroke *
                      1000 +
                  _pauseSeconds * 1000)
              .round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(KanjiStrokeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.strokePaths, widget.strokePaths)) {
      _paths = [for (final d in widget.strokePaths) parseSvgPathData(d)];
      _controller.duration = Duration(
          milliseconds: (widget.strokePaths.length * _secondsPerStroke *
                      1000 +
                  _pauseSeconds * 1000)
              .round());
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _AnimationPainter(
            paths: _paths,
            // 0.._paths.length over the drawing portion, then holds.
            progress: _controller.value *
                (_paths.length + _pauseSeconds / _secondsPerStroke),
          ),
        ),
      ),
    );
  }
}

class _AnimationPainter extends CustomPainter {
  _AnimationPainter({required this.paths, required this.progress});

  final List<Path> paths;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / kanjiVgSize;
    final matrix = Matrix4.diagonal3Values(scale, scale, 1).storage;

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final p in paths) {
      canvas.drawPath(p.transform(matrix), stroke(Colors.white12, 6));
    }
    for (var i = 0; i < paths.length; i++) {
      if (progress <= i) break;
      final scaled = paths[i].transform(matrix);
      if (progress >= i + 1) {
        canvas.drawPath(scaled, stroke(Colors.white, 6));
      } else {
        final metric = scaled.computeMetrics().first;
        canvas.drawPath(
          metric.extractPath(0, metric.length * (progress - i)),
          stroke(const Color(0xFFE25822), 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AnimationPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.paths != paths;
}
