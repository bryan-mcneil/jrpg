import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

/// M1 part 1: freehand drawing canvas wired to ML Kit Digital Ink
/// Recognition with the Japanese model. Gate: draw 火 with a finger,
/// the app says 火.
class DrawTestScreen extends StatefulWidget {
  const DrawTestScreen({super.key});

  @override
  State<DrawTestScreen> createState() => _DrawTestScreenState();
}

class _DrawTestScreenState extends State<DrawTestScreen> {
  static const String _languageCode = 'ja';
  static const String _targetKanji = '火';

  final _modelManager = mlkit.DigitalInkRecognizerModelManager();
  final _recognizer =
      mlkit.DigitalInkRecognizer(languageCode: _languageCode);

  /// Strokes for painting, mirrored into [_ink] for recognition.
  final List<List<Offset>> _strokes = [];
  final mlkit.Ink _ink = mlkit.Ink();

  List<mlkit.RecognitionCandidate> _candidates = [];
  bool _modelReady = false;
  bool _recognizing = false;
  String _status = 'Checking for Japanese ink model…';

  @override
  void initState() {
    super.initState();
    _prepareModel();
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _prepareModel() async {
    try {
      final downloaded =
          await _modelManager.isModelDownloaded(_languageCode);
      if (!downloaded) {
        setState(() => _status = 'Downloading Japanese ink model (~20 MB)…');
        await _modelManager.downloadModel(_languageCode);
      }
      if (!mounted) return;
      setState(() {
        _modelReady = true;
        _status = 'Draw $_targetKanji in the box';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Model download failed: $e');
    }
  }

  void _startStroke(Offset point) {
    if (!_modelReady) return;
    setState(() {
      _strokes.add([point]);
      _ink.strokes.add(mlkit.Stroke());
      _addPoint(point);
    });
  }

  void _extendStroke(Offset point) {
    if (!_modelReady || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(point);
      _addPoint(point);
    });
  }

  void _addPoint(Offset point) {
    _ink.strokes.last.points.add(
      mlkit.StrokePoint(
        x: point.dx,
        y: point.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _endStroke() async {
    if (!_modelReady || _ink.strokes.isEmpty || _recognizing) return;
    setState(() => _recognizing = true);
    try {
      final candidates = await _recognizer.recognize(_ink);
      if (!mounted) return;
      setState(() => _candidates = candidates.take(5).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Recognition failed: $e');
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _ink.strokes.clear();
      _candidates = [];
      if (_modelReady) _status = 'Draw $_targetKanji in the box';
    });
  }

  bool get _matched =>
      _candidates.isNotEmpty && _candidates.first.text == _targetKanji;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drawing Test (M1)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status, style: const TextStyle(fontSize: 18)),
          ),
          if (_matched)
            Container(
              key: const Key('match-banner'),
              width: double.infinity,
              color: Colors.green.shade800,
              padding: const EdgeInsets.all(12),
              child: Text(
                '$_targetKanji recognized!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF241B2F),
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: GestureDetector(
                  onPanStart: (d) => _startStroke(d.localPosition),
                  onPanUpdate: (d) => _extendStroke(d.localPosition),
                  onPanEnd: (_) => _endStroke(),
                  child: CustomPaint(
                    painter: _InkPainter(_strokes),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: _candidates.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final c in _candidates)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Chip(
                            label: Text(
                              c.text,
                              style: TextStyle(
                                fontSize: 22,
                                color: c.text == _targetKanji
                                    ? Colors.greenAccent
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],
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
