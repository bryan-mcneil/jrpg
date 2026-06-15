import 'package:flutter/material.dart';

import '../backgrounds/menu_background.dart';
import '../battle/models.dart' show QuestionMode;
import '../battle/question_bank.dart';
import '../util/romaji.dart';
import '../widgets/multiple_choice.dart';
import '../world/quest_map.dart';

/// An NPC-conversation node (DESIGN.md §3.2): read a short dialogue, then
/// answer a few pick/type "responses" — disguised reading & writing review
/// drawn from the player's learned pool. Pops `true` when the talk is seen
/// through (the score is practice, not a gate). The questions reuse the battle
/// [QuestionBank], so a fresh player who just did the lesson node can answer.
class NpcDialogueScreen extends StatefulWidget {
  const NpcDialogueScreen({super.key, required this.node, this.bank});

  final QuestNode node;

  /// Source for the response questions; null/absent → dialogue only.
  final QuestionBank? bank;

  @override
  State<NpcDialogueScreen> createState() => _NpcDialogueScreenState();
}

enum _Phase { dialogue, questions }

class _NpcDialogueScreenState extends State<NpcDialogueScreen> {
  _Phase _phase = _Phase.dialogue;
  int _lineIndex = 0;
  int _qIndex = 0;
  late final List<BattleQuestion> _questions = _buildQuestions();

  List<BattleQuestion> _buildQuestions() {
    final bank = widget.bank;
    if (bank == null || !bank.usable || widget.node.ask <= 0) return const [];
    return switch (widget.node.askMode) {
      NpcAskMode.pick => bank.volley(widget.node.ask, attackFormats),
      NpcAskMode.type => bank.volley(
          widget.node.ask,
          const [QuestionFormat.kanjiToReading],
          floor: QuestionMode.typed,
        ),
    };
  }

  void _advanceLine() {
    if (_lineIndex + 1 < widget.node.dialogue.length) {
      setState(() => _lineIndex++);
    } else if (_questions.isEmpty) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _phase = _Phase.questions);
    }
  }

  void _answered(bool correct) {
    if (_qIndex + 1 < _questions.length) {
      setState(() => _qIndex++);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.node.title)),
      body: MenuBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _phase == _Phase.dialogue ? _dialogueView() : _questionView(),
          ),
        ),
      ),
    );
  }

  Widget _dialogueView() {
    final line = widget.node.dialogue[_lineIndex];
    final last = _lineIndex + 1 >= widget.node.dialogue.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advanceLine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.speaker != null)
                      Text(line.speaker!,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFFE0B341),
                              fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(line.jp,
                        key: const Key('npc-jp'),
                        style: const TextStyle(fontSize: 24, height: 1.5)),
                    if (line.en != null) ...[
                      const SizedBox(height: 12),
                      Text(line.en!,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.white60)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${_lineIndex + 1} / ${widget.node.dialogue.length}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('npc-next'),
            onPressed: _advanceLine,
            child: Text(last && _questions.isEmpty
                ? 'Continue'
                : last
                    ? 'Answer'
                    : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _questionView() {
    final q = _questions[_qIndex];
    return Column(
      children: [
        Text('Response ${_qIndex + 1} / ${_questions.length}',
            style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: q.mode == QuestionMode.typed
                ? _TypeResponse(
                    key: ValueKey('npc-type-$_qIndex'),
                    question: q,
                    onAnswered: _answered,
                  )
                : MultipleChoice(
                    key: ValueKey('npc-pick-$_qIndex'),
                    prompt: Column(
                      children: [
                        Text(_instruction(q.format),
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(q.prompt, style: const TextStyle(fontSize: 64)),
                      ],
                    ),
                    options: q.options,
                    correct: q.correct,
                    onAnswered: _answered,
                  ),
          ),
        ),
      ],
    );
  }

  String _instruction(QuestionFormat format) => switch (format) {
        QuestionFormat.kanjiToMeaning => 'What does it mean?',
        QuestionFormat.kanjiToReading => 'How is it read?',
        _ => 'Answer the spirit:',
      };
}

/// Untimed typed-reading response — the same romaji→kana echo and accepted-set
/// check as the battle's `TypedAnswerQuestion`, minus the clock (NPC talk is
/// low-stakes practice).
class _TypeResponse extends StatefulWidget {
  const _TypeResponse({super.key, required this.question, required this.onAnswered});

  final BattleQuestion question;
  final void Function(bool correct) onAnswered;

  @override
  State<_TypeResponse> createState() => _TypeResponseState();
}

class _TypeResponseState extends State<_TypeResponse> {
  final _controller = TextEditingController();
  bool? _correct;

  String get _kana => romajiToHiragana(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_correct != null) return;
    final ok = widget.question.accepted.contains(_kana.trim());
    setState(() => _correct = ok);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) widget.onAnswered(ok);
  }

  @override
  Widget build(BuildContext context) {
    final answered = _correct != null;
    final fieldColor = _correct == null
        ? null
        : (_correct! ? Colors.green.shade800 : Colors.red.shade900);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Write the reading', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(widget.question.prompt,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        TextField(
          key: const Key('npc-typed-field'),
          controller: _controller,
          enabled: !answered,
          autofocus: true,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 24, letterSpacing: 2),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldColor ?? const Color(0xFF241B2F),
            border: const OutlineInputBorder(),
            hintText: 'かな',
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 6),
        Text(_kana.isEmpty ? '　' : '→ $_kana',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Color(0xFFB57EDC))),
        if (_correct == false)
          Text('answer: ${widget.question.correct}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('npc-typed-submit'),
          onPressed: answered ? null : _submit,
          child: const Text('Answer'),
        ),
      ],
    );
  }
}
