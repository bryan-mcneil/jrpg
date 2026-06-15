import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../data/kanjivg_strokes.dart' show kanjiVgSize;

/// Reusable stroke-by-stroke tracing canvas over a KanjiVG ghost guide
/// (extracted from the M1 tracing test). Strictness lives here per
/// DESIGN.md §4: shape, start point, and direction are all checked.
class TraceCanvas extends StatefulWidget {
  const TraceCanvas({
    super.key,
    required this.strokePaths,
    this.onStrokeResult,
    this.onCompleted,
  });

  /// KanjiVG SVG path strings in stroke order (109×109 space).
  final List<String> strokePaths;

  /// Called after each attempted stroke with the accept/reject message.
  final void Function(bool accepted, String message)? onStrokeResult;

  /// Called once when the final stroke is accepted.
  final VoidCallback? onCompleted;

  @override
  State<TraceCanvas> createState() => TraceCanvasState();
}

class TraceCanvasState extends State<TraceCanvas>
    with SingleTickerProviderStateMixin {
  /// Points sampled along each path when comparing shapes.
  static const int _samples = 32;

  /// Mean deviation allowed between traced and guide stroke, as a fraction
  /// of the canvas side. Finger tracing is wobbly; stay lenient.
  static const double _meanTolerance = 0.10;

  /// Allowed start/end point deviation, as a fraction of the canvas side.
  /// Start tolerance doubles as the direction check: tracing a stroke
  /// backwards puts the start a whole stroke-length away.
  static const double _endpointTolerance = 0.16;

  late List<Path> _guidePaths; // in 109x109 KanjiVG space
  late final AnimationController _hintController;

  int _nextStroke = 0;
  List<Offset> _activeStroke = [];
  List<Offset>? _rejectedStroke;

  bool get complete => _nextStroke >= _guidePaths.length;
  int get strokesDone => _nextStroke;

  @override
  void initState() {
    super.initState();
    _guidePaths = [for (final d in widget.strokePaths) parseSvgPathData(d)];
    _hintController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void didUpdateWidget(TraceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Content comparison: parents often rebuild with a freshly decoded
    // (but identical) list, which must not reset tracing progress.
    if (!listEquals(oldWidget.strokePaths, widget.strokePaths)) {
      _guidePaths = [for (final d in widget.strokePaths) parseSvgPathData(d)];
      reset();
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void reset() {
    setState(() {
      _nextStroke = 0;
      _activeStroke = [];
      _rejectedStroke = null;
    });
  }

  void _startStroke(Offset point) {
    if (complete) return;
    setState(() {
      _rejectedStroke = null;
      _activeStroke = [point];
    });
  }

  void _extendStroke(Offset point) {
    if (complete || _activeStroke.isEmpty) return;
    setState(() => _activeStroke.add(point));
  }

  void _endStroke(Size canvasSize) {
    if (complete || _activeStroke.length < 2) {
      setState(() => _activeStroke = []);
      return;
    }
    final side = canvasSize.shortestSide;
    final guide = _samplePath(_scaledGuide(_nextStroke, side), _samples);
    final traced = _resample(_activeStroke, _samples);

    final startOk =
        (traced.first - guide.first).distance <= _endpointTolerance * side;
    final endOk =
        (traced.last - guide.last).distance <= _endpointTolerance * side;
    var sum = 0.0;
    for (var i = 0; i < _samples; i++) {
      sum += (traced[i] - guide[i]).distance;
    }
    final meanOk = sum / _samples <= _meanTolerance * side;

    final accepted = startOk && endOk && meanOk;
    setState(() {
      if (accepted) {
        _nextStroke++;
      } else {
        _rejectedStroke = _activeStroke;
      }
      _activeStroke = [];
    });

    final message = accepted
        ? (complete
            ? 'All ${_guidePaths.length} strokes correct!'
            : 'Stroke $_nextStroke ✓ — now stroke ${_nextStroke + 1} '
                'of ${_guidePaths.length}')
        : !startOk
            ? 'Wrong start — begin at the green dot'
            : !meanOk
                ? 'Too far off the stroke — follow the orange guide'
                : 'Finish the whole stroke';
    widget.onStrokeResult?.call(accepted, message);
    if (accepted && complete) widget.onCompleted?.call();
  }

  /// Guide path [i] scaled from KanjiVG space to a canvas of [side].
  Path _scaledGuide(int i, double side) {
    final scale = side / kanjiVgSize;
    return _guidePaths[i]
        .transform(Matrix4.diagonal3Values(scale, scale, 1).storage);
  }

  /// [n] points evenly spaced by arc length along [path].
  static List<Offset> _samplePath(Path path, int n) {
    final PathMetric metric = path.computeMetrics().first;
    return [
      for (var i = 0; i < n; i++)
        metric.getTangentForOffset(metric.length * i / (n - 1))!.position,
    ];
  }

  /// Resamples a polyline to [n] points evenly spaced by arc length.
  static List<Offset> _resample(List<Offset> points, int n) {
    final lengths = [0.0];
    for (var i = 1; i < points.length; i++) {
      lengths.add(lengths.last + (points[i] - points[i - 1]).distance);
    }
    final total = lengths.last;
    if (total == 0) return List.filled(n, points.first);
    final out = <Offset>[];
    var seg = 0;
    for (var i = 0; i < n; i++) {
      final target = total * i / (n - 1);
      while (seg < points.length - 2 && lengths[seg + 1] < target) {
        seg++;
      }
      final segLen = lengths[seg + 1] - lengths[seg];
      final t = segLen == 0 ? 0.0 : (target - lengths[seg]) / segLen;
      out.add(Offset.lerp(points[seg], points[seg + 1], t)!);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF241B2F),
          border: Border.all(color: Colors.white24, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              return GestureDetector(
                onPanStart: (d) => _startStroke(d.localPosition),
                onPanUpdate: (d) => _extendStroke(d.localPosition),
                onPanEnd: (_) => _endStroke(size),
                child: AnimatedBuilder(
                  animation: _hintController,
                  builder: (context, _) => CustomPaint(
                    painter: _TracePainter(
                      guides: [
                        for (var i = 0; i < _guidePaths.length; i++)
                          _scaledGuide(i, size.shortestSide),
                      ],
                      nextStroke: _nextStroke,
                      hintProgress: _hintController.value,
                      activeStroke: _activeStroke,
                      rejectedStroke: _rejectedStroke,
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.guides,
    required this.nextStroke,
    required this.hintProgress,
    required this.activeStroke,
    required this.rejectedStroke,
  });

  /// All guide strokes, already scaled to canvas space.
  final List<Path> guides;
  final int nextStroke;

  /// 0..1 loop driving the draw-along hint on the current stroke.
  final double hintProgress;
  final List<Offset> activeStroke;
  final List<Offset>? rejectedStroke;

  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Ghost: every not-yet-traced stroke, faint.
    for (var i = nextStroke; i < guides.length; i++) {
      canvas.drawPath(guides[i], stroke(Colors.white24, 10));
    }
    // Completed strokes, solid.
    for (var i = 0; i < nextStroke; i++) {
      canvas.drawPath(guides[i], stroke(Colors.white, 10));
    }

    // Current stroke: draw-along hint in ember orange plus a start dot.
    if (nextStroke < guides.length) {
      final metric = guides[nextStroke].computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * hintProgress),
        stroke(const Color(0xFFE25822), 10),
      );
      final start = metric.getTangentForOffset(0)!.position;
      canvas.drawCircle(start, 9, Paint()..color = Colors.greenAccent);
    }

    void drawPolyline(List<Offset> points, Color color) {
      if (points.length < 2) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stroke(color, 8));
    }

    drawPolyline(activeStroke, Colors.white70);
    if (rejectedStroke != null) {
      drawPolyline(rejectedStroke!, Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) => true;
}
