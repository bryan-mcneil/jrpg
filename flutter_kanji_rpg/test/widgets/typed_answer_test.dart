import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/question_bank.dart';
import 'package:flutter_kanji_rpg/widgets/typed_answer.dart';

BattleQuestion _fireReading() => BattleQuestion(
      literal: '火',
      format: QuestionFormat.kanjiToReading,
      prompt: '火',
      options: const ['か'],
      correct: 'か',
      mode: QuestionMode.typed,
      accepted: const {'か', 'ひ'},
    );

void main() {
  testWidgets('romaji converts live in the preview', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypedAnswerQuestion(
          question: _fireReading(),
          duration: const Duration(seconds: 8),
          onAnswered: (_, _) {},
        ),
      ),
    ));
    await tester.enterText(find.byKey(const Key('typed-field')), 'ka');
    await tester.pump();
    expect(find.text('→ か'), findsOneWidget);
  });

  testWidgets('a correct typed reading reports success with a speed bonus',
      (tester) async {
    bool? correct;
    double? frac;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypedAnswerQuestion(
          question: _fireReading(),
          duration: const Duration(seconds: 8),
          onAnswered: (c, f) {
            correct = c;
            frac = f;
          },
        ),
      ),
    ));
    await tester.enterText(find.byKey(const Key('typed-field')), 'ka');
    await tester.pump();
    await tester.tap(find.byKey(const Key('typed-submit')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isTrue);
    expect(frac, greaterThan(0), reason: 'answered before the timer ran out');
  });

  testWidgets('an alternate valid reading (ひ) is also accepted',
      (tester) async {
    bool? correct;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypedAnswerQuestion(
          question: _fireReading(),
          duration: const Duration(seconds: 8),
          onAnswered: (c, _) => correct = c,
        ),
      ),
    ));
    // Type kana directly (as a Japanese IME would deliver it).
    await tester.enterText(find.byKey(const Key('typed-field')), 'ひ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('typed-submit')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isTrue);
  });

  testWidgets('a wrong reading fails and reveals the answer', (tester) async {
    bool? correct;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypedAnswerQuestion(
          question: _fireReading(),
          duration: const Duration(seconds: 8),
          onAnswered: (c, _) => correct = c,
        ),
      ),
    ));
    await tester.enterText(find.byKey(const Key('typed-field')), 'mizu');
    await tester.pump();
    await tester.tap(find.byKey(const Key('typed-submit')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(correct, isFalse);
    expect(find.text('answer: か'), findsOneWidget);
  });

  testWidgets('timeout counts as a miss with zero speed bonus',
      (tester) async {
    bool? correct;
    double? frac;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TypedAnswerQuestion(
          question: _fireReading(),
          duration: const Duration(seconds: 2),
          onAnswered: (c, f) {
            correct = c;
            frac = f;
          },
        ),
      ),
    ));
    // Let the countdown lapse without answering: the timer completes (firing
    // the auto-submit), then the feedback delay elapses.
    await tester.pump(const Duration(seconds: 2)); // timer reaches the end
    await tester.pump(const Duration(milliseconds: 100)); // completed → _submit
    await tester.pump(const Duration(milliseconds: 900)); // feedback delay
    expect(correct, isFalse);
    expect(frac, 0);
  });
}
