import 'package:flutter/material.dart';

import '../data/kanjivg_strokes.dart';
import '../widgets/trace_canvas.dart';

/// M1 part 2: stroke-by-stroke tracing of 水 over a KanjiVG ghost guide.
/// The reusable canvas now lives in widgets/trace_canvas.dart; this screen
/// remains as the dev-menu harness for it.
class TraceTestScreen extends StatefulWidget {
  const TraceTestScreen({super.key});

  @override
  State<TraceTestScreen> createState() => _TraceTestScreenState();
}

class _TraceTestScreenState extends State<TraceTestScreen> {
  static const String _targetKanji = '水';

  final _canvasKey = GlobalKey<TraceCanvasState>();
  String _status = 'Trace stroke 1 of ${mizuStrokePaths.length} — '
      'start at the green dot';
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracing Test (M1)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)),
          ),
          if (_complete)
            Container(
              key: const Key('trace-complete'),
              width: double.infinity,
              color: Colors.green.shade800,
              padding: const EdgeInsets.all(12),
              child: const Text(
                '$_targetKanji traced!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TraceCanvas(
                  key: _canvasKey,
                  strokePaths: mizuStrokePaths,
                  onStrokeResult: (accepted, message) =>
                      setState(() => _status = message),
                  onCompleted: () => setState(() => _complete = true),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () {
                _canvasKey.currentState?.reset();
                setState(() {
                  _complete = false;
                  _status = 'Trace stroke 1 of ${mizuStrokePaths.length} — '
                      'start at the green dot';
                });
              },
              icon: const Icon(Icons.replay),
              label: const Text('Restart'),
            ),
          ),
        ],
      ),
    );
  }
}
