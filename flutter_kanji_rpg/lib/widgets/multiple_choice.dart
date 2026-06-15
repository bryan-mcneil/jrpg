import 'package:flutter/material.dart';

/// Four-option quiz question with tap feedback: the chosen answer flashes
/// green/red (the correct one is revealed on a miss), then [onAnswered]
/// fires after a short beat.
class MultipleChoice extends StatefulWidget {
  const MultipleChoice({
    super.key,
    required this.prompt,
    required this.options,
    required this.correct,
    required this.onAnswered,
  });

  final Widget prompt;
  final List<String> options;
  final String correct;
  final void Function(bool correct) onAnswered;

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  String? _chosen;

  Future<void> _choose(String option) async {
    if (_chosen != null) return;
    setState(() => _chosen = option);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) widget.onAnswered(option == widget.correct);
  }

  Color? _optionColor(String option) {
    if (_chosen == null) return null;
    if (option == widget.correct) return Colors.green.shade800;
    if (option == _chosen) return Colors.red.shade800;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: widget.prompt),
        const SizedBox(height: 24),
        for (final option in widget.options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: _optionColor(option),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _choose(option),
              child: Text(option,
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    );
  }
}
