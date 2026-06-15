import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/question_bank.dart';
import 'package:flutter_kanji_rpg/widgets/drawn_answer.dart';
import 'package:flutter_kanji_rpg/widgets/spell_canvas.dart';

// A reading→kanji question whose answer is 火 (drawn, not tapped).
BattleQuestion _drawQuestion() => BattleQuestion(
      literal: '火',
      format: QuestionFormat.readingToKanji,
      prompt: 'か',
      options: const ['火'],
      correct: '火',
      mode: QuestionMode.drawn,
      accepted: const {'火'},
    );

/// Pumps a DrawnAnswerQuestion whose canvas recognizes [candidates] after a
/// stroke, then draws one stroke on it.
Future<void> _pumpAndStroke(
  WidgetTester tester,
  List<String> candidates, {
  required void Function(bool, double) onAnswered,
  Duration duration = const Duration(seconds: 12),
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DrawnAnswerQuestion(
        question: _drawQuestion(),
        duration: duration,
        recognizer: (ink) async => candidates,
        onAnswered: onAnswered,
      ),
    ),
  ));
  await tester.pump(); // canvas is ready immediately with a custom recognizer
  await tester.drag(find.byType(SpellCanvas), const Offset(40, 40));
  await tester.pump(); // recognize() resolves → onCandidates fires
}

void main() {
  testWidgets('drawing the right kanji is accepted with a speed bonus',
      (tester) async {
    bool? correct;
    double? frac;
    await _pumpAndStroke(tester, ['火'],
        onAnswered: (c, f) {
      correct = c;
      frac = f;
    });
    await tester.pump(const Duration(milliseconds: 900)); // feedback flash
    expect(correct, isTrue);
    expect(frac, greaterThan(0), reason: 'drawn before the timer ran out');
  });

  testWidgets('a wrong drawing fails and reveals the answer', (tester) async {
    bool? correct;
    await _pumpAndStroke(tester, ['水'], // recognized as something else
        onAnswered: (c, _) => correct = c);
    // Not the target, so nothing auto-submits — the player commits it manually.
    // The literal seam is offstage (never shown), so opt finders into it.
    expect(find.byKey(const Key('drawn-answer'), skipOffstage: false),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('drawn-submit')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isFalse);
    expect(find.text('answer: 火'), findsOneWidget);
  });

  testWidgets('a lower-ranked match still counts', (tester) async {
    // ML Kit returns several candidates; the target need only appear among them.
    bool? correct;
    await _pumpAndStroke(tester, ['大', '火', '太'],
        onAnswered: (c, _) => correct = c);
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isTrue);
  });

  testWidgets('timeout counts as a miss with zero speed bonus', (tester) async {
    bool? correct;
    double? frac;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DrawnAnswerQuestion(
          question: _drawQuestion(),
          duration: const Duration(seconds: 2),
          recognizer: (ink) async => const ['火'],
          onAnswered: (c, f) {
            correct = c;
            frac = f;
          },
        ),
      ),
    ));
    // Never draw: the timer completes (auto-submit), then the feedback delay.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isFalse);
    expect(frac, 0);
  });
}
