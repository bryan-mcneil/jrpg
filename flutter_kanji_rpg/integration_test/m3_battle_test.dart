// The M3 gate, end to end on a device (DESIGN.md §7): a full boss fight is
// winnable AND losable; 火+嵐 (storm) hits both skirmish enemies while
// 火+剣 (blade) hits one; the 水 boss takes 0.5× from 火. A 火+力 (boon)
// buff raises a temporary +ATK, and a 火炎の札 ITEM burns the boss. The boss
// is the hardest fight (§3.4): its reading-recall questions must be spelled out
// (typed kana) and its kanji-production questions must be *drawn* (real ML Kit
// ink), not tapped. Enemy volleys also mix in listen-and-translate questions
// (real device TTS speaks the word; the clock waits for the audio). Every
// round runs the two-turn flow (player turn ATTACK/MAGIC/ITEM, then the
// NPC-turn reaction DEFEND/SUPPORT/ITEM), with target selection, real ML Kit
// spell drawing, and the boss telegraph→DEFEND window. Run against a freshly
// cleared install:
//
//   adb shell pm clear com.example.flutter_kanji_rpg
//   flutter test integration_test/m3_battle_test.dart -d <device>
@Timeout(Duration(minutes: 25))
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, TextInputAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_drawing/path_drawing.dart';

import 'package:flutter_kanji_rpg/data/kanjivg_strokes.dart' show kanjiVgSize;
import 'package:flutter_kanji_rpg/main.dart' as app;
import 'package:flutter_kanji_rpg/util/kana.dart';
import 'package:flutter_kanji_rpg/widgets/spell_canvas.dart';

class KanjiData {
  KanjiData(this.literal, this.meanings, this.readings, this.allReadings,
      this.strokes);

  final String literal;
  final List<String> meanings;
  final List<String> readings; // on then kun — readings.first matches the app
  final Set<String> allReadings;
  final List<String> strokes;
}

Future<Map<String, KanjiData>> loadKanjiData() async {
  final raw = await rootBundle.loadString('assets/data/kanji.json');
  final list = (jsonDecode(raw) as Map<String, dynamic>)['kanji'] as List;
  final map = <String, KanjiData>{};
  for (final e in list.cast<Map<String, dynamic>>()) {
    // Readings as the app displays them: on-readings in hiragana, kun
    // markup stripped (た.べる → たべる).
    final on = [
      for (final r in List<String>.from(e['on'] as List)) toHiragana(r)
    ];
    final kun = [
      for (final r in List<String>.from(e['kun'] as List)) parseKun(r).reading
    ];
    final k = KanjiData(
      e['literal'] as String,
      List<String>.from(e['meanings'] as List),
      [...on, ...kun],
      {...on, ...kun},
      List<String>.from(e['strokes'] as List),
    );
    map[k.literal] = k;
  }
  return map;
}

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

/// Waits until any of [finders] matches (e.g. "victory OR the reaction
/// menu"); branch on what is actually on screen afterwards.
Future<void> waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    for (final f in finders) {
      if (f.evaluate().isNotEmpty) return;
    }
  }
  fail('Timed out waiting for any of $finders');
}

String textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

(int, int) enemyHp(WidgetTester tester, int index) {
  final parts = textOf(tester, Key('enemy-hp-$index')).split('/');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

/// Option texts of the multiple-choice buttons currently on screen.
List<String> optionTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(
        of: find.byType(FilledButton), matching: find.byType(Text)))
    .map((t) => t.data)
    .whereType<String>()
    .toList();

/// Counts how many typed (spell-it-out) reading questions were answered, so
/// the test can prove the §3.4 hard-difficulty path was exercised end to end.
int typedAnswered = 0;

/// Likewise for drawn (freehand kanji) production questions.
int drawnAnswered = 0;

/// And for listen-and-translate questions (heard, not seen) — proves the
/// real device TTS path runs in a live fight without deadlocking the clock.
int listenAnswered = 0;

/// Answers the visible battle question using the dictionary; wrong answers
/// pick any other option. Handles both multiple choice and the typed reading
/// question the boss (and mastered kanji) demand.
Future<void> answerBattleQuestion(
  WidgetTester tester,
  Map<String, KanjiData> data, {
  bool wrong = false,
}) async {
  // Drawn kanji-production question (DESIGN.md §3.4): draw the kanji that reads
  // the shown prompt. The target literal rides an offstage seam (never shown
  // on screen), so the test knows which strokes to trace. Robust to a fresh
  // per-question ink recognizer needing a beat to warm up: trace only while
  // the canvas is present, wipe and retry if a pass doesn't land, and move on
  // once the question resolves (recognized, or the generous clock lapses).
  if (find.byKey(const Key('drawn-submit')).evaluate().isNotEmpty) {
    final literal = tester
        .widget<Text>(
            find.byKey(const Key('drawn-answer'), skipOffstage: false))
        .data!;
    bool resolved() {
      final submit = find.byKey(const Key('drawn-submit'));
      return submit.evaluate().isEmpty ||
          tester.widget<FilledButton>(submit).onPressed == null;
    }

    for (var attempt = 0; attempt < 6 && !resolved(); attempt++) {
      for (final d in data[literal]!.strokes) {
        if (resolved() || find.byType(SpellCanvas).evaluate().isEmpty) break;
        await drawStroke(tester, d);
      }
      // Recognition auto-submits; the button disables (or the card is gone)
      // on success or when the clock lapses. Give the pass a few seconds.
      final end = DateTime.now().add(const Duration(seconds: 6));
      while (DateTime.now().isBefore(end) && !resolved()) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      if (resolved()) break;
      // The trace didn't land (recognizer still warming) — wipe and retry.
      if (find.byKey(const Key('drawn-clear')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('drawn-clear')));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    drawnAnswered++;
    await tester.pump(const Duration(milliseconds: 900)); // settle → advance
    return;
  }

  // Listen-and-translate (DESIGN.md §3.4): the word is spoken, not shown, so
  // there's no bq-prompt to read — the correct meaning rides an offstage seam.
  // On a real device the clock (and the answer buttons) stay locked until the
  // TTS playback finishes, so poll until an answer is tappable, then tap it.
  if (find.byKey(const Key('listen-replay')).evaluate().isNotEmpty) {
    final answer = tester
        .widget<Text>(
            find.byKey(const Key('listen-answer'), skipOffstage: false))
        .data!;
    final end = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(end)) {
      final replay = tester.widget<ButtonStyleButton>(
          find.byKey(const Key('listen-replay')));
      if (replay.onPressed != null) break; // playback done → answers live
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Drop the replay button's own label so only the meaning options remain.
    final options = optionTexts(tester)
        .where((o) => o != 'Replay' && o != 'Listening…')
        .toList();
    final tap = wrong ? options.firstWhere((o) => o != answer) : answer;
    await tester.tap(find.text(tap).last);
    listenAnswered++;
    await tester.pump(const Duration(milliseconds: 1000));
    return;
  }

  // Typed reading question (DESIGN.md §3.4): spell the reading into the field.
  if (find.byKey(const Key('typed-field')).evaluate().isNotEmpty) {
    final prompt = textOf(tester, const Key('bq-prompt'));
    final runes = prompt.runes.toList();
    final literal = String.fromCharCode(runes.first);
    final okurigana = String.fromCharCodes(runes.skip(1));
    final reading = okurigana.isEmpty
        ? data[literal]!.readings.first
        : data[literal]!.allReadings.firstWhere((r) => r.endsWith(okurigana));
    // A wrong answer: a real reading with a stray ん appended is never accepted.
    await tester.enterText(
        find.byKey(const Key('typed-field')), wrong ? '$readingん' : reading);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    typedAnswered++;
    // 800ms feedback flash, then the runner advances.
    await tester.pump(const Duration(milliseconds: 1000));
    return;
  }

  final instruction = textOf(tester, const Key('bq-format'));
  final prompt = textOf(tester, const Key('bq-prompt'));
  final options = optionTexts(tester);
  final String target;
  switch (instruction) {
    case 'What does this mean?':
      target = data[prompt]!.meanings.first;
    case 'How is it read?':
      // The prompt may be a word form (食べる) quizzing any reading of its
      // leading kanji; the bank guarantees exactly one option truly reads it.
      final literal = String.fromCharCode(prompt.runes.first);
      target =
          options.firstWhere((o) => data[literal]!.allReadings.contains(o));
    case 'Pick the kanji for…':
      target =
          options.firstWhere((o) => data[o]?.meanings.first == prompt);
    case 'Which kanji reads…':
      target = options
          .firstWhere((o) => data[o]?.allReadings.contains(prompt) ?? false);
    default:
      fail('Unknown question instruction: $instruction');
  }
  final tap = wrong ? options.firstWhere((o) => o != target) : target;
  await tester.tap(find.text(tap).last);
  // 700ms feedback flash, then the runner advances.
  await tester.pump(const Duration(milliseconds: 1000));
}

/// Answers exactly [n] player-volley questions, the first [wrongFirst]
/// deliberately wrong.
Future<void> answerVolley(
  WidgetTester tester,
  Map<String, KanjiData> data,
  int n, {
  int wrongFirst = 0,
}) async {
  for (var i = 0; i < n; i++) {
    await waitFor(tester, find.byKey(const Key('bq-format')));
    await answerBattleQuestion(tester, data, wrong: i < wrongFirst);
  }
}

/// Pumps through the enemy phase (banners + volleys, answered correctly)
/// until the command grid, victory, or defeat shows.
Future<void> playUntilCommand(
  WidgetTester tester,
  Map<String, KanjiData> data, {
  Duration timeout = const Duration(minutes: 4),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.byKey(const Key('cmd-attack')).evaluate().isNotEmpty ||
        find.byKey(const Key('battle-victory')).evaluate().isNotEmpty ||
        find.byKey(const Key('battle-defeat')).evaluate().isNotEmpty) {
      return;
    }
    if (find.byKey(const Key('bq-format')).evaluate().isNotEmpty) {
      await answerBattleQuestion(tester, data);
    }
  }
  fail('Battle never returned to the command phase');
}

bool commandEnabled(WidgetTester tester, String name) {
  final button =
      tester.widget<FilledButton>(find.byKey(Key('cmd-$name')));
  return button.onPressed != null;
}

/// The NPC-turn reaction: DEFEND when usable (answering its 5 reverse
/// questions), else SUPPORT (instant). Call with the reaction menu shown.
Future<void> react(WidgetTester tester, Map<String, KanjiData> data) async {
  await waitFor(tester, find.byKey(const Key('cmd-defend')));
  if (commandEnabled(tester, 'defend')) {
    await tester.tap(find.byKey(const Key('cmd-defend')));
    await answerVolley(tester, data, 5);
  } else {
    await tester.tap(find.byKey(const Key('cmd-support')));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// After an offensive action: settles on victory, the reaction menu, or a
/// straight-to-enemy volley (auto-skipped reaction), reacts if asked to,
/// then plays through the enemy actions to the next player turn.
Future<void> finishRound(
  WidgetTester tester,
  Map<String, KanjiData> data,
) async {
  await waitForAny(tester, [
    find.byKey(const Key('battle-victory')),
    find.byKey(const Key('cmd-defend')),
    find.byKey(const Key('bq-format')),
  ], timeout: const Duration(minutes: 2));
  if (find.byKey(const Key('cmd-defend')).evaluate().isNotEmpty) {
    await react(tester, data);
  }
  await playUntilCommand(tester, data);
}

/// Draws one KanjiVG stroke centered on the spell canvas.
Future<void> drawStroke(WidgetTester tester, String d) async {
  final rect = tester.getRect(find.byType(SpellCanvas)).deflate(8);
  final scale = rect.shortestSide / kanjiVgSize * 0.9;
  final origin = rect.center -
      Offset(kanjiVgSize * scale / 2, kanjiVgSize * scale / 2);
  final metric = parseSvgPathData(d).computeMetrics().first;
  const n = 24;
  final points = [
    for (var i = 0; i < n; i++)
      origin +
          metric.getTangentForOffset(metric.length * i / (n - 1))!.position *
              scale,
  ];
  final gesture = await tester.startGesture(points.first);
  for (final p in points.skip(1)) {
    await gesture.moveTo(p);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 250));
}

/// Draws [kanji] into spell slot [slot], retrying until the slot chip
/// recognizes the right literal.
Future<void> drawIntoSlot(
  WidgetTester tester,
  KanjiData kanji,
  int slot, {
  int attempts = 3,
}) async {
  final chip = find.descendant(
      of: find.byKey(Key('spell-slot-$slot')),
      matching: find.text(kanji.literal));
  for (var attempt = 0; attempt < attempts; attempt++) {
    for (final d in kanji.strokes) {
      await drawStroke(tester, d);
    }
    // Give the last recognition pass a moment.
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (chip.evaluate().isNotEmpty) return;
    }
    await tester.tap(find.byKey(const Key('spell-clear')));
    await tester.pump(const Duration(milliseconds: 300));
  }
  fail('${kanji.literal} was never recognized into slot $slot');
}

/// Waits for the ML Kit model spinner inside the spell canvas to clear.
Future<void> waitForCanvasReady(WidgetTester tester) async {
  final spinner = find.descendant(
      of: find.byType(SpellCanvas),
      matching: find.byType(CircularProgressIndicator));
  final end = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (spinner.evaluate().isEmpty) return;
  }
  fail('Japanese ink model never became ready');
}

/// Multiple-choice answer for the (untimed) test-out exam.
Future<void> answerExam(WidgetTester tester, String correct) async {
  await tester.tap(find.text(correct).last);
  await tester.pump(const Duration(milliseconds: 1100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M3 gate: commands, spell shapes, matchups, win & lose',
      (tester) async {
    app.main();
    final data = await loadKanjiData();

    // The app opens on the title screen; NEW GAME enters the milestone hub.
    await waitFor(tester, find.byKey(const Key('title-new-game')));
    await tester.tap(find.byKey(const Key('title-new-game')));

    // Fresh install: DB seeds, queue reads 0 due.
    await waitFor(tester, find.textContaining('— 0 due'),
        timeout: const Duration(minutes: 2));

    // Seed the learned pool quickly: pass the N5 test-out.
    await tester.tap(find.byKey(const Key('menu-testout')));
    for (var i = 0; i < 12; i++) {
      await waitFor(tester, find.byKey(ValueKey('exam-$i')));
      final literal = tester
          .widgetList<Text>(find.descendant(
              of: find.byKey(ValueKey('exam-$i')),
              matching: find.byType(Text)))
          .firstWhere((t) => t.style?.fontSize == 80)
          .data!;
      await answerExam(tester, data[literal]!.meanings.first);
    }
    await waitFor(tester, find.byKey(const Key('exam-result')));
    expect(find.textContaining('passed!'), findsOneWidget);
    await tester.tap(find.text('Back to menu'));
    await tester.pump(const Duration(milliseconds: 600));

    // --- Skirmish, god mode (so 嵐/剣 are castable) -----------------------
    await tester.tap(find.byKey(const Key('menu-battle')));
    await waitFor(tester, find.byKey(const Key('setup-godmode')));
    await tester.ensureVisible(find.byKey(const Key('setup-godmode')));
    await tester.tap(find.byKey(const Key('setup-godmode')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('setup-start')));
    await tester.tap(find.byKey(const Key('setup-start')));
    await waitFor(tester, find.byKey(const Key('cmd-attack')),
        timeout: const Duration(seconds: 90));
    expect(enemyHp(tester, 0), (40, 40));
    expect(enemyHp(tester, 1), (40, 40));

    // ATTACK with target selection: hit the bat (1), kobold untouched.
    await tester.tap(find.byKey(const Key('cmd-attack')));
    await waitFor(tester, find.byKey(const Key('target-cancel')));
    await tester.tap(find.byKey(const Key('target-1')));
    await answerVolley(tester, data, 5, wrongFirst: 2); // 3/5 — no kill
    await finishRound(tester, data);
    final batAfterAttack = enemyHp(tester, 1).$1;
    expect(batAfterAttack, lessThan(40));
    expect(enemyHp(tester, 0).$1, 40,
        reason: 'ATTACK must hit only its target');

    // MAGIC 火+剣 (blade): bursts the kobold alone.
    await tester.tap(find.byKey(const Key('cmd-magic')));
    await waitFor(tester, find.byKey(const Key('spell-cast')));
    await waitForCanvasReady(tester);
    await drawIntoSlot(tester, data['火']!, 0);
    await tester.tap(find.byKey(const Key('spell-add-modifier')));
    await tester.pump(const Duration(milliseconds: 300));
    await drawIntoSlot(tester, data['剣']!, 1);
    await tester.tap(find.byKey(const Key('spell-cast')));
    await waitFor(tester, find.byKey(const Key('target-cancel')));
    await tester.tap(find.byKey(const Key('target-0')));
    await finishRound(tester, data);
    final koboldAfterBlade = enemyHp(tester, 0).$1;
    expect(koboldAfterBlade, lessThan(40), reason: '火+剣 hits its target');
    expect(enemyHp(tester, 1).$1, batAfterAttack,
        reason: '火+剣 must hit ONE enemy');

    // MAGIC 火+嵐 (storm): hits BOTH — no target picker.
    await tester.tap(find.byKey(const Key('cmd-magic')));
    await waitFor(tester, find.byKey(const Key('spell-cast')));
    await waitForCanvasReady(tester);
    await drawIntoSlot(tester, data['火']!, 0);
    await tester.tap(find.byKey(const Key('spell-add-modifier')));
    await tester.pump(const Duration(milliseconds: 300));
    await drawIntoSlot(tester, data['嵐']!, 1);
    await tester.tap(find.byKey(const Key('spell-cast')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(enemyHp(tester, 0).$1, lessThan(koboldAfterBlade),
        reason: '火+嵐 hits the kobold');
    expect(enemyHp(tester, 1).$1, lessThan(batAfterAttack),
        reason: '火+嵐 hits the bat too');

    // Storm should have finished both off; mop up if anything survived.
    await finishRound(tester, data);
    for (var round = 0;
        round < 6 &&
            find.byKey(const Key('battle-victory')).evaluate().isEmpty;
        round++) {
      await tester.tap(find.byKey(const Key('cmd-attack')));
      await tester.pump(const Duration(milliseconds: 400));
      if (find.byKey(const Key('target-cancel')).evaluate().isNotEmpty) {
        final target = enemyHp(tester, 0).$1 > 0 ? 0 : 1;
        await tester.tap(find.byKey(Key('target-$target')));
      }
      await answerVolley(tester, data, 5);
      await finishRound(tester, data);
    }
    await waitFor(tester, find.byKey(const Key('battle-victory')));
    await tester.tap(find.byKey(const Key('battle-continue')));

    // --- Boss: 忘水の精 (水), god mode still on --------------------------
    await waitFor(tester, find.byKey(const Key('setup-boss')));
    await tester.ensureVisible(find.byKey(const Key('setup-boss')));
    await tester.tap(find.byKey(const Key('setup-boss')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('setup-start')));
    await tester.tap(find.byKey(const Key('setup-start')));
    await waitFor(tester, find.byKey(const Key('cmd-attack')),
        timeout: const Duration(seconds: 90));

    // Round 1 — 火 vs 水: the resist gate. Single enemy → no picker.
    await tester.tap(find.byKey(const Key('cmd-magic')));
    await waitFor(tester, find.byKey(const Key('spell-cast')));
    await waitForCanvasReady(tester);
    await drawIntoSlot(tester, data['火']!, 0);
    await tester.tap(find.byKey(const Key('spell-cast')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(textOf(tester, const Key('battle-log-last')), contains('×0.5'),
        reason: 'the 水 boss must resist 火');
    final bossAfterFire = enemyHp(tester, 0).$1;
    expect(150 - bossAfterFire, lessThanOrEqualTo(6),
        reason: 'resisted fire should chip, not chunk');
    await finishRound(tester, data); // DEFEND reaction, then 水撃 volley

    // Round 2 — ATTACK, then SUPPORT as the reaction: SP spent, charges up.
    await tester.tap(find.byKey(const Key('cmd-attack')));
    await answerVolley(tester, data, 5);
    await waitFor(tester, find.byKey(const Key('cmd-support')));
    await tester.tap(find.byKey(const Key('cmd-support')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(textOf(tester, const Key('player-sp')), contains('6/10'));
    expect(find.byKey(const Key('support-charges')), findsOneWidget);
    await playUntilCommand(tester, data); // 忘却の霧 — confusion banner

    // Round 3 — ATTACK while confused (options reshuffle mid-question).
    await tester.tap(find.byKey(const Key('cmd-attack')));
    await answerVolley(tester, data, 5);
    await finishRound(tester, data); // telegraph: 大水流 charging
    expect(find.textContaining('大水流'), findsWidgets,
        reason: 'boss should be visibly charging its big attack');

    // Round 4 — offense first, then the DEFEND window vs the big volley.
    await tester.tap(find.byKey(const Key('cmd-attack')));
    await answerVolley(tester, data, 5);
    await react(tester, data); // DEFEND 5/5
    await playUntilCommand(tester, data); // 大水流, answered perfectly
    expect(textOf(tester, const Key('player-hp')), contains('100/100'),
        reason: 'perfect answers + DEFEND = unscathed');

    // MAGIC 火+力 (boon): a no-target party buff. Proves a boon-tagged kanji
    // is castable from the seeded dictionary and raises the temporary +ATK
    // badge; the +ATK then rides the attacks that finish the boss.
    await tester.tap(find.byKey(const Key('cmd-magic')));
    await waitFor(tester, find.byKey(const Key('spell-cast')));
    await waitForCanvasReady(tester);
    await drawIntoSlot(tester, data['火']!, 0);
    await tester.tap(find.byKey(const Key('spell-add-modifier')));
    await tester.pump(const Duration(milliseconds: 300));
    await drawIntoSlot(tester, data['力']!, 1);
    await tester.tap(find.byKey(const Key('spell-cast')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('atk-buff')), findsOneWidget,
        reason: 'a boon spell raises the temporary +ATK badge');
    expect(textOf(tester, const Key('battle-log-last')), contains('empowered'));
    await finishRound(tester, data);

    // ITEM: 火炎の札 burns the boss. The command is live now that the bag is
    // stocked; the 水 boss isn't burn-immune. Single enemy → no target picker.
    expect(commandEnabled(tester, 'item'), isTrue,
        reason: 'ITEM enables once the bag has items');
    await tester.tap(find.byKey(const Key('cmd-item')));
    await waitFor(tester, find.byKey(const Key('item-firecharm')));
    await tester.tap(find.byKey(const Key('item-firecharm')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(textOf(tester, const Key('battle-log-last')), contains('火傷'),
        reason: 'the firecharm lands a burn on the boss');
    await finishRound(tester, data);

    // Rounds 5+ — finish it. 言霊封じ may seal ATTACK or DEFEND; adapt.
    for (var round = 0;
        round < 14 &&
            find.byKey(const Key('battle-victory')).evaluate().isEmpty;
        round++) {
      if (find.byKey(const Key('cmd-attack')).evaluate().isNotEmpty) {
        if (commandEnabled(tester, 'attack')) {
          await tester.tap(find.byKey(const Key('cmd-attack')));
          await answerVolley(tester, data, 5);
        } else {
          // ATTACK sealed — burn the player turn with a drawn 火 bolt.
          await tester.tap(find.byKey(const Key('cmd-magic')));
          await waitFor(tester, find.byKey(const Key('spell-cast')));
          await waitForCanvasReady(tester);
          await drawIntoSlot(tester, data['火']!, 0);
          await tester.tap(find.byKey(const Key('spell-cast')));
          await tester.pump(const Duration(milliseconds: 400));
        }
        await finishRound(tester, data);
      } else {
        await playUntilCommand(tester, data);
      }
    }
    await waitFor(tester, find.byKey(const Key('battle-victory')));
    expect(enemyHp(tester, 0).$1, 0);
    expect(typedAnswered, greaterThan(0),
        reason: 'the boss forces reading questions to be typed, not tapped '
            '(DESIGN.md §3.4)');
    expect(drawnAnswered, greaterThan(0),
        reason: 'the boss forces kanji-production questions to be drawn, not '
            'tapped (DESIGN.md §3.4)');
    expect(listenAnswered, greaterThan(0),
        reason: 'enemy volleys mix in listen-and-translate questions, and the '
            'device TTS path must run in a live fight (DESIGN.md §3.4)');
    await tester.tap(find.byKey(const Key('battle-continue')));

    // --- Losable: glass cannon vs the boss, ignore the volley ------------
    await waitFor(tester, find.byKey(const Key('setup-hp1')));
    await tester.ensureVisible(find.byKey(const Key('setup-hp1')));
    await tester.tap(find.byKey(const Key('setup-hp1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('setup-start')));
    await tester.tap(find.byKey(const Key('setup-start')));
    await waitFor(tester, find.byKey(const Key('cmd-attack')),
        timeout: const Duration(seconds: 90));
    // Whiff the player turn (ATTACK questions all time out, 0 damage),
    // then SUPPORT as the reaction — no DEFEND bracing.
    await tester.tap(find.byKey(const Key('cmd-attack')));
    await waitFor(tester, find.byKey(const Key('cmd-support')),
        timeout: const Duration(minutes: 2));
    await tester.tap(find.byKey(const Key('cmd-support')));
    final end = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(end) &&
        find.byKey(const Key('battle-defeat')).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 500)); // let timers lapse
    }
    expect(find.byKey(const Key('battle-defeat')), findsOneWidget,
        reason: 'an unanswered boss volley must be lethal at 1 HP');
  });
}
