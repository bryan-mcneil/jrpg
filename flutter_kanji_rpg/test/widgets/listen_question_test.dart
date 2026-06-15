import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/question_bank.dart';
import 'package:flutter_kanji_rpg/widgets/listen_question.dart';

// A listen-and-translate question: hear 火, tap its meaning ("fire").
BattleQuestion _listenQuestion() => BattleQuestion(
      literal: '火',
      format: QuestionFormat.listenToMeaning,
      prompt: '火',
      options: const ['fire', 'water', 'tree', 'gold'],
      correct: 'fire',
    );

ButtonStyleButton _replay(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(find.byKey(const Key('listen-replay')));

void main() {
  testWidgets('hearing the word, then tapping its meaning, scores a bonus',
      (tester) async {
    bool? correct;
    double? frac;
    final spoken = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenQuestion(
          question: _listenQuestion(),
          duration: const Duration(seconds: 10),
          speaker: (t) async => spoken.add(t),
          onAnswered: (c, f) {
            correct = c;
            frac = f;
          },
        ),
      ),
    ));
    await tester.pump(); // _begin: speak resolves → clock starts
    await tester.pump();
    expect(spoken, ['火'], reason: 'the prompt is spoken once on appear');
    await tester.tap(find.text('fire'));
    await tester.pump(const Duration(milliseconds: 800)); // feedback flash
    expect(correct, isTrue);
    expect(frac, greaterThan(0), reason: 'answered before the clock ran out');
  });

  testWidgets('tapping the wrong meaning is a miss', (tester) async {
    bool? correct;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenQuestion(
          question: _listenQuestion(),
          duration: const Duration(seconds: 10),
          speaker: (_) async {},
          onAnswered: (c, _) => correct = c,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('water'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(correct, isFalse);
  });

  testWidgets('the clock does not start until the first playback finishes',
      (tester) async {
    final gate = Completer<void>();
    var calls = 0;
    var answered = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenQuestion(
          question: _listenQuestion(),
          duration: const Duration(seconds: 2),
          speaker: (_) {
            calls++;
            return gate.future; // never resolves until we let it
          },
          onAnswered: (_, _) => answered = true,
        ),
      ),
    ));
    await tester.pump();
    expect(calls, 1, reason: 'plays as soon as the question appears');
    // Still listening: replay and the answers are locked, the bar is frozen.
    expect(_replay(tester).onPressed, isNull);
    // Pump well past the 2s clock (but under the 8s audio safety net): with
    // the prompt still playing, the question must not time out…
    await tester.pump(const Duration(seconds: 4));
    expect(answered, isFalse, reason: 'never timed against unheard audio');
    // …and an answer tapped before it's heard is ignored.
    await tester.tap(find.text('fire'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(answered, isFalse, reason: 'options locked until the word plays');

    // Playback finishes → the clock starts and the answers unlock.
    gate.complete();
    await tester.pump(); // flush the speak() continuation (_ready = true)
    await tester.pump(); // rebuild reflects the unlocked state
    expect(_replay(tester).onPressed, isNotNull);
    // The 2s clock now runs; leaving it unanswered times out as a miss.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
    expect(answered, isTrue);
  });

  testWidgets('replay speaks again and leaves the clock running',
      (tester) async {
    final spoken = <String>[];
    bool? correct;
    double? frac;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenQuestion(
          question: _listenQuestion(),
          duration: const Duration(seconds: 10),
          speaker: (t) async => spoken.add(t),
          onAnswered: (c, f) {
            correct = c;
            frac = f;
          },
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(spoken, ['火']);
    // Let ~4s of the 10s clock elapse, then replay.
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('listen-replay')));
    await tester.pump();
    expect(spoken, ['火', '火'], reason: 'replay plays the same word again');
    // The clock kept running across the replay, so the bonus is reduced but
    // still positive — replaying didn't reset the timer.
    await tester.tap(find.text('fire'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(correct, isTrue);
    expect(frac, greaterThan(0));
    expect(frac, lessThan(0.7), reason: '~4s of the 10s clock already spent');
  });
}
