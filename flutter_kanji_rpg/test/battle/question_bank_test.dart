import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/question_bank.dart';
import 'package:flutter_kanji_rpg/db/database.dart' show KanjiEntryLists;

import 'helpers.dart';

void main() {
  final pool = [
    kanji('火', meanings: ['fire'], on: ['カ'], kun: ['ひ']),
    kanji('水', meanings: ['water'], on: ['スイ'], kun: ['みず']),
    kanji('木', meanings: ['tree'], on: ['モク'], kun: ['き']),
    kanji('金', meanings: ['gold'], on: ['キン'], kun: ['かね']),
    kanji('土', meanings: ['earth'], on: ['ド'], kun: ['つち']),
    kanji('日', meanings: ['day'], on: ['ニチ'], kun: ['ひ']),
    kanji('月', meanings: ['moon'], on: ['ゲツ'], kun: ['つき']),
    kanji('山', meanings: ['mountain'], on: ['サン'], kun: ['やま']),
    kanji('川', meanings: ['river'], on: ['セン'], kun: ['かわ']),
    kanji('人', meanings: ['person'], on: ['ジン'], kun: ['ひと']),
  ];

  test('volleys produce 4 unique options containing exactly one answer', () {
    final bank = QuestionBank(pool, const {}, rng: Random(7));
    for (final q in bank.volley(50, QuestionFormat.values)) {
      expect(q.options, hasLength(4));
      expect(q.options.toSet(), hasLength(4), reason: 'options must differ');
      expect(q.options, contains(q.correct));
    }
  });

  test('a volley never repeats a kanji', () {
    final bank = QuestionBank(pool, const {}, rng: Random(7));
    final volley = bank.volley(5, attackFormats);
    expect(volley.map((q) => q.literal).toSet(), hasLength(5));
  });

  test('reverse formats never offer a distractor that also fits', () {
    // 火 and 日 share the kun reading ひ — a ひ→kanji question must not
    // offer both.
    final bank = QuestionBank(pool, const {}, rng: Random(3));
    for (var i = 0; i < 60; i++) {
      for (final q in bank.volley(8, const [QuestionFormat.readingToKanji])) {
        if (q.prompt == 'ひ') {
          expect(q.options.toSet().intersection({'火', '日'}), hasLength(1),
              reason: 'both 火 and 日 read ひ — only the answer may appear');
        }
      }
    }
  });

  test('due kanji appear ~3× more often (FSRS weighting, §3.2)', () {
    final bank = QuestionBank(pool, const {'火'}, rng: Random(42));
    var fire = 0, water = 0;
    for (var i = 0; i < 600; i++) {
      final q = bank.volley(1, attackFormats).single;
      if (q.literal == '火') fire++;
      if (q.literal == '水') water++;
    }
    // Expected ≈ 600·3/12 = 150 vs 600·1/12 = 50.
    expect(fire, greaterThan(water * 2));
  });

  test('attack and defend formats point the right way', () {
    final bank = QuestionBank(pool, const {}, rng: Random(1));
    for (final q in bank.volley(20, attackFormats)) {
      // Reading prompts may carry okurigana (食べる), but always lead with
      // the quizzed kanji.
      expect(q.prompt, startsWith(q.literal), reason: 'ATTACK shows the kanji');
    }
    for (final q in bank.volley(20, defendFormats)) {
      expect(q.correct, q.literal, reason: 'DEFEND asks for the kanji');
    }
  });

  test('okurigana kun readings quiz as word forms', () {
    final eatPool = [
      kanji('食', meanings: ['eat'], on: ['ショク'], kun: ['た.べる', 'く.う']),
      ...pool.where((k) => k.literal != '食'),
    ];
    final bank = QuestionBank(eatPool, const {}, rng: Random(11));
    var sawWordForm = false;
    for (var i = 0; i < 200 && !sawWordForm; i++) {
      for (final q in bank.volley(8, const [QuestionFormat.kanjiToReading])) {
        if (q.prompt == '食べる') {
          sawWordForm = true;
          expect(q.correct, 'たべる', reason: 'answer is the full kana');
          // No option may leak the answer through a mismatched ending.
          for (final o in q.options) {
            expect(o, endsWith('べる'),
                reason: 'options share the visible okurigana');
          }
        }
      }
    }
    expect(sawWordForm, isTrue, reason: '食べる should get quizzed eventually');
  });

  test('reading options never include an alternate reading of the kanji', () {
    // 灯 is kun-only ひ — without the guard it could appear as a distractor
    // for 火 (correct か), yet ひ also reads 火.
    final firePool = [
      kanji('灯', meanings: ['lamp'], on: [], kun: ['ひ']),
      ...pool,
    ];
    final bank = QuestionBank(firePool, const {}, rng: Random(5));
    for (var i = 0; i < 100; i++) {
      for (final q in bank.volley(8, const [QuestionFormat.kanjiToReading])) {
        if (q.literal == '火') {
          final valid = {'か', 'ひ'};
          expect(q.options.where(valid.contains), [q.correct],
              reason: 'only the answer may be a true reading of 火');
        }
      }
    }
  });

  test('unusable below the minimum pool', () {
    expect(QuestionBank(pool.sublist(0, 4), const {}).usable, isFalse);
    expect(QuestionBank(pool, const {}).usable, isTrue);
  });

  group('difficulty — typed reading (§3.4)', () {
    test('everything is multiple choice by default', () {
      final bank = QuestionBank(pool, const {}, rng: Random(7));
      for (final q in bank.volley(50, QuestionFormat.values)) {
        expect(q.mode, QuestionMode.choice);
        expect(q.options, hasLength(4));
      }
    });

    test('a typed floor types reading questions, leaves the rest tapped', () {
      final bank = QuestionBank(pool, const {}, rng: Random(7));
      var sawTyped = false, sawChoice = false;
      for (final q in bank.volley(50, QuestionFormat.values,
          floor: QuestionMode.typed)) {
        if (q.format == QuestionFormat.kanjiToReading) {
          sawTyped = true;
          expect(q.mode, QuestionMode.typed);
          expect(q.options, [q.correct], reason: 'typed has no distractors');
          expect(q.accepted, contains(q.correct));
        } else {
          sawChoice = true;
          expect(q.mode, QuestionMode.choice,
              reason: 'only readings have a typed form yet');
          expect(q.options, hasLength(4));
        }
      }
      expect(sawTyped && sawChoice, isTrue);
    });

    test('mastered kanji are typed even without an encounter floor', () {
      final bank =
          QuestionBank(pool, const {}, typedMastered: {'火'}, rng: Random(2));
      var checkedFire = false;
      for (var i = 0; i < 80; i++) {
        for (final q
            in bank.volley(8, const [QuestionFormat.kanjiToReading])) {
          if (q.literal == '火') {
            checkedFire = true;
            expect(q.mode, QuestionMode.typed, reason: '火 is mastered');
          } else {
            expect(q.mode, QuestionMode.choice,
                reason: 'unmastered kanji stay multiple choice');
          }
        }
      }
      expect(checkedFire, isTrue);
    });

    test('typed reading accepts every reading of the shown word-form', () {
      // Bare 火 reads か or ひ — both must be accepted; the okurigana word
      // 食べる pins exactly one answer.
      final mixedPool = [
        kanji('火', meanings: ['fire'], on: ['カ'], kun: ['ひ']),
        kanji('食', meanings: ['eat'], on: ['ショク'], kun: ['た.べる']),
        ...pool.where((k) => k.literal != '火'),
      ];
      final bank = QuestionBank(mixedPool, const {}, rng: Random(9));
      var sawFire = false, sawEat = false;
      for (var i = 0; i < 200 && !(sawFire && sawEat); i++) {
        for (final q in bank.volley(8, const [QuestionFormat.kanjiToReading],
            floor: QuestionMode.typed)) {
          expect(q.accepted, contains(q.correct));
          if (q.prompt == '火') {
            sawFire = true;
            expect(q.accepted, {'か', 'ひ'});
          }
          if (q.prompt == '食べる') {
            sawEat = true;
            expect(q.accepted, {'たべる'});
          }
        }
      }
      expect(sawFire && sawEat, isTrue);
    });
  });

  group('difficulty — drawn kanji (§3.4)', () {
    test('a drawn floor draws reading→kanji, types reading, taps the rest', () {
      final bank = QuestionBank(pool, const {}, rng: Random(7));
      var sawDrawn = false, sawTyped = false, sawChoice = false;
      for (final q in bank.volley(60, QuestionFormat.values,
          floor: QuestionMode.drawn)) {
        switch (q.format) {
          case QuestionFormat.readingToKanji:
            sawDrawn = true;
            expect(q.mode, QuestionMode.drawn);
            expect(q.correct, q.literal, reason: 'you draw the kanji itself');
            expect(q.options, [q.literal], reason: 'drawn has no distractors');
            expect(q.accepted, {q.literal});
          case QuestionFormat.kanjiToReading:
            sawTyped = true;
            expect(q.mode, QuestionMode.typed,
                reason: 'drawn floor outranks typed, so recall is still typed');
          case QuestionFormat.kanjiToMeaning:
          case QuestionFormat.meaningToKanji:
          case QuestionFormat.listenToMeaning:
            sawChoice = true;
            expect(q.mode, QuestionMode.choice,
                reason: 'the meaning formats have no hard form yet');
        }
      }
      expect(sawDrawn && sawTyped && sawChoice, isTrue);
    });

    test('a typed floor never reaches drawing', () {
      final bank = QuestionBank(pool, const {}, rng: Random(7));
      for (final q in bank.volley(60, QuestionFormat.values,
          floor: QuestionMode.typed)) {
        if (q.format == QuestionFormat.readingToKanji) {
          expect(q.mode, QuestionMode.choice,
              reason: 'production needs the drawn floor (or deep mastery)');
        }
      }
    });

    test('draw-mastered kanji are drawn even without an encounter floor', () {
      // 火 is only draw-mastered; its production turns drawn, the others stay
      // tapped, and its *reading* recall is unaffected (drawnMastered ≠ typed).
      final bank =
          QuestionBank(pool, const {}, drawnMastered: {'火'}, rng: Random(2));
      var checkedFire = false;
      for (var i = 0; i < 80; i++) {
        for (final q
            in bank.volley(8, const [QuestionFormat.readingToKanji])) {
          if (q.literal == '火') {
            checkedFire = true;
            expect(q.mode, QuestionMode.drawn, reason: '火 is draw-mastered');
          } else {
            expect(q.mode, QuestionMode.choice,
                reason: 'un-mastered kanji stay multiple choice');
          }
        }
      }
      expect(checkedFire, isTrue);
    });
  });

  group('listen-and-translate (§3.4)', () {
    test('is an enemy-only format, never ATTACK or DEFEND', () {
      expect(enemyFormats, contains(QuestionFormat.listenToMeaning));
      expect(attackFormats, isNot(contains(QuestionFormat.listenToMeaning)));
      expect(defendFormats, isNot(contains(QuestionFormat.listenToMeaning)));
    });

    test('speaks the word-form and answers with its meaning, tapped', () {
      final bank = QuestionBank(pool, const {}, rng: Random(7));
      var checked = false;
      for (var i = 0; i < 40 && !checked; i++) {
        for (final q in bank
            .volley(8, const [QuestionFormat.listenToMeaning])) {
          checked = true;
          // Tapped, never escalated — the audio is the difficulty.
          expect(q.mode, QuestionMode.choice);
          // The prompt is the spoken Japanese word-form (leads with the
          // kanji), not its English meaning.
          expect(q.prompt, startsWith(q.literal));
          // Four meaning options, exactly one correct, accepted == {meaning}.
          expect(q.options, hasLength(4));
          expect(q.options.toSet(), hasLength(4));
          expect(q.options, contains(q.correct));
          expect(q.accepted, {q.correct});
          // The answer is the kanji's meaning, not a reading or a kanji.
          final entry =
              pool.firstWhere((k) => k.literal == q.literal);
          expect(entry.meaningList, contains(q.correct));
        }
      }
      expect(checked, isTrue);
    });

    test('a drawn encounter floor leaves listen questions tapped', () {
      // The floor escalates reading/production formats; listen stays a tap
      // because its challenge is the audio prompt, not the answer modality.
      final bank = QuestionBank(pool, const {}, rng: Random(11));
      for (final q in bank.volley(40, const [QuestionFormat.listenToMeaning],
          floor: QuestionMode.drawn)) {
        expect(q.mode, QuestionMode.choice);
      }
    });
  });
}
