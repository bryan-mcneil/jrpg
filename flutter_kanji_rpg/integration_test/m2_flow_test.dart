// The M2 gate, end to end on a device (DESIGN.md §7): learn 10 N5 kanji
// through the full lesson flow (info → trace → quiz), see the first
// reviews come due on the FSRS schedule, clear one, then pass the N5
// test-out exam. Run against a freshly cleared app install:
//
//   adb shell pm clear com.example.flutter_kanji_rpg
//   flutter test integration_test/m2_flow_test.dart -d <device>
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_drawing/path_drawing.dart';

import 'package:flutter_kanji_rpg/data/kanjivg_strokes.dart'
    show kanjiVgSize;
import 'package:flutter_kanji_rpg/main.dart' as app;
import 'package:flutter_kanji_rpg/util/kana.dart';
import 'package:flutter_kanji_rpg/widgets/trace_canvas.dart';

class KanjiData {
  KanjiData(this.literal, this.meanings, this.readings, this.strokes);

  final String literal;
  final List<String> meanings;
  final List<String> readings; // on then kun, like the app's reading quiz
  final List<String> strokes;
}

Future<Map<String, KanjiData>> loadKanjiData() async {
  final raw = await rootBundle.loadString('assets/data/kanji.json');
  final list = (jsonDecode(raw) as Map<String, dynamic>)['kanji'] as List;
  final map = <String, KanjiData>{};
  final n5InOrder = <String>[];
  for (final e in list.cast<Map<String, dynamic>>()) {
    final k = KanjiData(
      e['literal'] as String,
      List<String>.from(e['meanings'] as List),
      // Readings as the app displays them: on-readings in hiragana, kun
      // markup stripped (た.べる → たべる).
      [
        for (final r in List<String>.from(e['on'] as List)) toHiragana(r),
        for (final r in List<String>.from(e['kun'] as List))
          parseKun(r).reading,
      ],
      List<String>.from(e['strokes'] as List),
    );
    map[k.literal] = k;
    if (e['level'] == 5) n5InOrder.add(k.literal);
  }
  map['__n5_order__'] = KanjiData('', n5InOrder, const [], const []);
  return map;
}

/// All JMdict words the import shipped, for checking the example-word UI.
Future<Set<String>> loadVocabWords() async {
  final raw = await rootBundle.loadString('assets/data/vocab.json');
  final list = (jsonDecode(raw) as Map<String, dynamic>)['words'] as List;
  return {
    for (final e in list.cast<Map<String, dynamic>>()) e['word'] as String,
  };
}

/// Pumps until [finder] matches, failing after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

/// Traces one KanjiVG stroke on the on-screen TraceCanvas.
Future<void> traceStroke(WidgetTester tester, String d) async {
  // Inner drawing area sits inside the canvas container's 2px border.
  final rect = tester.getRect(find.byType(TraceCanvas)).deflate(2);
  final scale = rect.shortestSide / kanjiVgSize;
  final metric = parseSvgPathData(d).computeMetrics().first;
  const n = 24;
  final points = [
    for (var i = 0; i < n; i++)
      rect.topLeft +
          metric.getTangentForOffset(metric.length * i / (n - 1))!.position *
              scale,
  ];
  final gesture = await tester.startGesture(points.first);
  for (final p in points.skip(1)) {
    await gesture.moveTo(p);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 150));
}

/// Traces all strokes of [kanji], retrying rejected strokes.
Future<void> traceKanji(WidgetTester tester, KanjiData kanji) async {
  final state = tester.state<TraceCanvasState>(find.byType(TraceCanvas));
  var attempts = 0;
  while (!state.complete) {
    final before = state.strokesDone;
    await traceStroke(tester, kanji.strokes[before]);
    if (state.strokesDone == before && ++attempts > 3) {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      fail('Stroke ${before + 1} of ${kanji.literal} kept being rejected; '
          'on-screen text: $texts');
    }
    if (state.strokesDone != before) attempts = 0;
  }
}

/// Answers the currently shown multiple-choice question.
Future<void> answer(WidgetTester tester, String correct,
    {bool deliberatelyWrong = false}) async {
  var target = correct;
  if (deliberatelyWrong) {
    final options = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(FilledButton), matching: find.byType(Text)))
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => t != correct);
    target = options.first;
  }
  await tester.tap(find.text(target).last);
  // MultipleChoice shows feedback for ~900ms before advancing.
  await tester.pump(const Duration(milliseconds: 1100));
}

/// Runs one full lesson over [literals]; answers the final reading
/// question wrong when [lastReadingWrong] so that card comes due in ~1 min.
Future<void> runLesson(
  WidgetTester tester,
  Map<String, KanjiData> data,
  List<String> literals, {
  bool lastReadingWrong = false,
}) async {
  await tester.tap(find.byKey(const Key('menu-lesson')));
  for (var i = 0; i < literals.length; i++) {
    final kanji = data[literals[i]]!;
    await waitFor(tester, find.byKey(const Key('lesson-next')));
    expect(find.text(kanji.literal), findsWidgets,
        reason: 'lesson should be teaching ${kanji.literal}');
    await tester.tap(find.byKey(const Key('lesson-next')));
    await waitFor(tester, find.byType(TraceCanvas));
    await traceKanji(tester, kanji);

    await waitFor(tester, find.byKey(ValueKey('mq-${kanji.literal}')));
    await answer(tester, kanji.meanings.first);
    await waitFor(tester, find.byKey(ValueKey('rq-${kanji.literal}')));
    await answer(
      tester,
      kanji.readings.first,
      deliberatelyWrong: lastReadingWrong && i == literals.length - 1,
    );
  }
  await waitFor(tester, find.byKey(const Key('lesson-done')));
  await tester.tap(find.byKey(const Key('lesson-done')));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M2 gate: lessons, FSRS schedule, test-out', (tester) async {
    app.main();
    final data = await loadKanjiData();
    final n5 = data['__n5_order__']!.meanings; // lesson order

    // The app opens on the title screen; NEW GAME enters the milestone hub.
    await waitFor(tester, find.byKey(const Key('title-new-game')));
    await tester.tap(find.byKey(const Key('title-new-game')));

    // Fresh install: DB seeds from the asset, then the queue reads 0 due.
    await waitFor(tester, find.textContaining('— 0 due'),
        timeout: const Duration(minutes: 2));

    // Browser proves the dictionary seeded; the detail sheet proves the
    // JMdict vocab seeded — its example words must be real imported words
    // containing the kanji.
    final vocabWords = await loadVocabWords();
    await tester.tap(find.byKey(const Key('menu-browser')));
    await waitFor(tester, find.text(n5.first));
    await tester.tap(find.text(n5.first).first);
    await waitFor(tester, find.byKey(const Key('vocab-words')));
    final wordLines = tester
        .widgetList<Text>(find.descendant(
            of: find.byKey(const Key('vocab-words')),
            matching: find.byType(Text)))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(wordLines, isNotEmpty);
    for (final line in wordLines) {
      final word = line.split('【').first;
      expect(word, contains(n5.first));
      expect(vocabWords, contains(word),
          reason: 'example word should come from the JMdict import');
    }
    // Dismiss the sheet via the barrier, then leave the browser.
    await tester.tapAt(const Offset(20, 50));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));

    // Learn 10 N5 kanji in two lessons. One deliberate miss on the last
    // reading puts that card on the short relearning step (~1 min).
    await runLesson(tester, data, n5.sublist(0, 5));
    await runLesson(tester, data, n5.sublist(5, 10), lastReadingWrong: true);

    // FSRS schedule: the missed card becomes due about a minute later.
    await tester.pump(const Duration(seconds: 70));
    await tester.tap(find.byKey(const Key('menu-browser'))); // round trip
    await waitFor(tester, find.text(n5.first));
    await tester.pageBack(); // refreshes the due count
    await waitFor(tester, find.textContaining('— 1 due'),
        timeout: const Duration(seconds: 30));
    // Let the pop transition finish before tapping through the menu.
    await tester.pump(const Duration(milliseconds: 600));

    // Clear the queue: answer the due card correctly.
    final dueKanji = data[n5[9]]!;
    await tester.tap(find.byKey(const Key('menu-review')));
    await waitFor(tester, find.text(dueKanji.literal));
    await answer(tester, dueKanji.meanings.first);
    await waitFor(tester, find.byKey(const Key('review-done')));
    expect(find.textContaining('1 / 1 correct'), findsOneWidget);
    await tester.tap(find.text('Back to menu'));
    await tester.pump(const Duration(milliseconds: 500));

    // Test-out N5: answer all 12 from the dictionary; expect a pass and
    // the rest of the level seeded as well-known.
    await tester.tap(find.byKey(const Key('menu-testout')));
    for (var i = 0; i < 12; i++) {
      await waitFor(tester, find.byKey(ValueKey('exam-$i')));
      final literal = tester
          .widgetList<Text>(find.descendant(
              of: find.byKey(ValueKey('exam-$i')),
              matching: find.byType(Text)))
          .firstWhere((t) => t.style?.fontSize == 80)
          .data!;
      await answer(tester, data[literal]!.meanings.first);
    }
    await waitFor(tester, find.byKey(const Key('exam-result')));
    expect(find.textContaining('passed!'), findsOneWidget);
    expect(find.textContaining('marked well-known'), findsOneWidget);
  });
}
