import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

/// Recognition hook so tests (and future platforms) can swap ML Kit out.
typedef InkRecognizerFn = Future<List<String>> Function(mlkit.Ink ink);

/// Freehand kanji pad for casting: collects strokes, runs digital-ink
/// recognition after every stroke, and reports the candidate list plus
/// elapsed drawing time. Recognition only — stroke order is never failed
/// mid-battle (DESIGN.md §4).
class SpellCanvas extends StatefulWidget {
  const SpellCanvas({
    super.key,
    required this.onCandidates,
    this.recognizer,
    this.enabled = true,
  });

  /// Top recognition candidates after each stroke, with time since the
  /// first stroke began (the speed-grade input).
  final void Function(List<String> candidates, Duration elapsed) onCandidates;
  final InkRecognizerFn? recognizer;
  final bool enabled;

  @override
  State<SpellCanvas> createState() => SpellCanvasState();
}

class SpellCanvasState extends State<SpellCanvas> {
  static const _languageCode = 'ja';

  final _modelManager = mlkit.DigitalInkRecognizerModelManager();
  late final mlkit.DigitalInkRecognizer _mlkitRecognizer;

  final List<List<Offset>> _strokes = [];
  final mlkit.Ink _ink = mlkit.Ink();
  DateTime? _firstStrokeAt;
  bool _modelReady = false;
  bool _recognizing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.recognizer == null) {
      _mlkitRecognizer =
          mlkit.DigitalInkRecognizer(languageCode: _languageCode);
      _prepareModel();
    } else {
      _modelReady = true;
    }
  }

  @override
  void dispose() {
    if (widget.recognizer == null) _mlkitRecognizer.close();
    super.dispose();
  }

  Future<void> _prepareModel() async {
    try {
      if (!await _modelManager.isModelDownloaded(_languageCode)) {
        await _modelManager.downloadModel(_languageCode);
      }
      if (mounted) setState(() => _modelReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ink model unavailable: $e');
    }
  }

  Future<List<String>> _recognize(mlkit.Ink ink) async {
    final custom = widget.recognizer;
    if (custom != null) return custom(ink);
    final candidates = await _mlkitRecognizer.recognize(ink);
    return [for (final c in candidates.take(5)) c.text];
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _ink.strokes.clear();
      _firstStrokeAt = null;
    });
  }

  bool get _accepting => widget.enabled && _modelReady;

  void _startStroke(Offset point) {
    if (!_accepting) return;
    _firstStrokeAt ??= DateTime.now();
    setState(() {
      _strokes.add([point]);
      _ink.strokes.add(mlkit.Stroke());
      _addPoint(point);
    });
  }

  void _extendStroke(Offset point) {
    if (!_accepting || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(point);
      _addPoint(point);
    });
  }

  void _addPoint(Offset point) {
    _ink.strokes.last.points.add(mlkit.StrokePoint(
      x: point.dx,
      y: point.dy,
      t: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> _endStroke() async {
    if (!_accepting || _ink.strokes.isEmpty || _recognizing) return;
    setState(() => _recognizing = true);
    try {
      final candidates = await _recognize(_ink);
      if (!mounted) return;
      widget.onCandidates(
        candidates,
        DateTime.now().difference(_firstStrokeAt ?? DateTime.now()),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Recognition failed: $e');
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF241B2F),
        border: Border.all(color: Colors.white24, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: !_modelReady && _error == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : GestureDetector(
                    onPanStart: (d) => _startStroke(d.localPosition),
                    onPanUpdate: (d) => _extendStroke(d.localPosition),
                    onPanEnd: (_) => _endStroke(),
                    child: CustomPaint(
                      painter: _InkPainter(_strokes),
                      size: Size.infinite,
                    ),
                  ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawPoints(PointMode.points, stroke, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter oldDelegate) => true;
}
