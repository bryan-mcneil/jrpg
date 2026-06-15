import 'dart:math';

import '../db/database.dart';
import '../util/kana.dart';
import 'balance.dart';
import 'models.dart';

/// Battle question formats (DESIGN.md §3.4): ATTACK asks kanji→answer,
/// DEFEND reverses (answer→kanji), enemy volleys mix everything — including
/// [listenToMeaning], where the prompt is *heard*, not seen.
enum QuestionFormat {
  kanjiToMeaning,
  kanjiToReading,
  meaningToKanji,
  readingToKanji,

  /// Listen-and-translate: the word is spoken (Japanese TTS) and the player
  /// picks its meaning. The answer is the same meaning multiple choice as
  /// [kanjiToMeaning]; only the prompt's modality differs (audio, not glyph).
  /// An enemy/boss-turn format only — the player never *casts* by ear.
  listenToMeaning,
}

const attackFormats = [
  QuestionFormat.kanjiToMeaning,
  QuestionFormat.kanjiToReading,
];
const defendFormats = [
  QuestionFormat.meaningToKanji,
  QuestionFormat.readingToKanji,
];
const enemyFormats = QuestionFormat.values;

class BattleQuestion {
  BattleQuestion({
    required this.literal,
    required this.format,
    required this.prompt,
    required this.options,
    required this.correct,
    this.mode = QuestionMode.choice,
    Set<String>? accepted,
  }) : accepted = accepted ?? {correct};

  final String literal;
  final QuestionFormat format;
  final String prompt;

  /// Multiple-choice options. For a [QuestionMode.typed] question there is no
  /// option list to tap — only [correct] (and the broader [accepted] set).
  final List<String> options;
  final String correct;

  /// How the player answers (DESIGN.md §3.4): tap an option, or spell it out.
  final QuestionMode mode;

  /// Every answer counted right. For typed readings of an ambiguous prompt
  /// (bare 火 reads か *or* ひ) this is more than just [correct]; for choice
  /// questions it's exactly {correct}.
  final Set<String> accepted;
}

/// Builds volleys from the player's learned pool, weighted toward items
/// FSRS says are due — battles are disguised review sessions (§3.2).
/// Pure (injectable rng, plain data in) so it tests without a database.
class QuestionBank {
  QuestionBank(
    List<KanjiEntry> pool,
    this.dueLiterals, {
    this.typedMastered = const {},
    this.drawnMastered = const {},
    Random? rng,
  })  : rng = rng ?? Random(),
        // Only kanji with at least one meaning and reading can appear in
        // every format.
        pool = [
          for (final k in pool)
            if (k.meaningList.isNotEmpty &&
                (k.onList.isNotEmpty || k.kunList.isNotEmpty))
              k
        ];

  static const dueWeight = 3;
  static const optionCount = 4;

  /// Enough material for 4 distinct options in any format.
  static const minPoolSize = 8;

  final List<KanjiEntry> pool;
  final Set<String> dueLiterals;

  /// Kanji matured past [masteryStabilityDays] of FSRS stability: their
  /// reading recall is quizzed the hard way — typed, not tapped (§3.4).
  final Set<String> typedMastered;

  /// Kanji matured even further (past [drawMasteryStabilityDays]): their kanji
  /// production (reading→kanji) is *drawn*, not tapped. A subset of
  /// [typedMastered].
  final Set<String> drawnMastered;

  final Random rng;

  bool get usable => pool.length >= minPoolSize;

  String _reading(KanjiEntry k) =>
      k.onList.isNotEmpty ? k.onList.first : k.kunList.first;

  /// A random reading to quiz — on-readings and kun-readings both count, so
  /// 食 sometimes asks for しょく (shown 食) and sometimes たべる (shown 食べる).
  KunReading _readingForm(KanjiEntry k) {
    final forms = k.readingForms;
    return forms[rng.nextInt(forms.length)];
  }

  /// Weighted sample without replacement.
  List<KanjiEntry> _sample(int n) {
    final candidates = [...pool];
    final picked = <KanjiEntry>[];
    while (picked.length < n && candidates.isNotEmpty) {
      final total = candidates.fold<int>(
          0, (sum, k) => sum + (dueLiterals.contains(k.literal) ? dueWeight : 1));
      var roll = rng.nextInt(total);
      for (var i = 0; i < candidates.length; i++) {
        roll -= dueLiterals.contains(candidates[i].literal) ? dueWeight : 1;
        if (roll < 0) {
          picked.add(candidates.removeAt(i));
          break;
        }
      }
    }
    return picked;
  }

  BattleQuestion _build(KanjiEntry k, QuestionFormat format,
      [QuestionMode mode = QuestionMode.choice]) {
    // A typed reading question needs no distractors — the player spells the
    // answer out. Accept any reading whose written word-form matches the
    // prompt (bare 火 → か or ひ; 食べる → only たべる).
    if (mode == QuestionMode.typed && format == QuestionFormat.kanjiToReading) {
      final form = _readingForm(k);
      final prompt = form.wordForm(k.literal);
      final accepted = {
        for (final f in k.readingForms)
          if (f.wordForm(k.literal) == prompt) f.reading
      };
      return BattleQuestion(
        literal: k.literal,
        format: format,
        prompt: prompt,
        options: [form.reading],
        correct: form.reading,
        mode: QuestionMode.typed,
        accepted: accepted,
      );
    }

    // A drawn production question needs no distractors either — the player
    // draws the kanji that reads the shown prompt, and only that kanji counts.
    if (mode == QuestionMode.drawn &&
        format == QuestionFormat.readingToKanji) {
      final prompt = _readingForm(k).reading;
      return BattleQuestion(
        literal: k.literal,
        format: format,
        prompt: prompt,
        options: [k.literal],
        correct: k.literal,
        mode: QuestionMode.drawn,
        accepted: {k.literal},
      );
    }

    final distractors = <String>[];
    final others = [...pool]..shuffle(rng);
    String correct;
    String prompt;
    switch (format) {
      case QuestionFormat.kanjiToMeaning:
      case QuestionFormat.listenToMeaning:
        // Same meaning multiple choice; the listen variant *speaks* the word
        // (its reading word-form, e.g. 食べる/火) instead of showing the kanji.
        prompt = format == QuestionFormat.listenToMeaning
            ? _readingForm(k).wordForm(k.literal)
            : k.literal;
        correct = k.meaningList.first;
        for (final o in others) {
          final v = o.meaningList.first;
          // No distractor may be an alternate correct answer for k.
          if (o.literal != k.literal &&
              !k.meaningList.contains(v) &&
              !distractors.contains(v)) {
            distractors.add(v);
          }
          if (distractors.length == optionCount - 1) break;
        }
      case QuestionFormat.kanjiToReading:
        // Kun readings quiz as the word the player will actually meet:
        // prompt 食べる, answer たべる (not しょく).
        final form = _readingForm(k);
        prompt = form.wordForm(k.literal);
        correct = form.reading;
        final valid = {...k.onList, ...k.kunList};
        if (form.hasOkurigana) {
          // Every option shares the visible okurigana (other kanji's kun
          // stems + べる), so the ending gives nothing away.
          for (final o in others) {
            if (o.literal == k.literal) continue;
            for (final p in o.kunForms) {
              final v = p.stem + form.okurigana;
              if (p.stem.isNotEmpty &&
                  !valid.contains(v) &&
                  !distractors.contains(v)) {
                distractors.add(v);
                break; // one stem per source kanji, varied material
              }
            }
            if (distractors.length == optionCount - 1) break;
          }
        }
        // Fill from other kanji's primary readings (the on-reading case, or
        // when the pool runs out of kun stems).
        for (final o in others) {
          if (distractors.length == optionCount - 1) break;
          final v = _reading(o);
          if (o.literal != k.literal &&
              !valid.contains(v) &&
              !distractors.contains(v)) {
            distractors.add(v);
          }
        }
      case QuestionFormat.meaningToKanji:
        prompt = k.meaningList.first;
        correct = k.literal;
        for (final o in others) {
          // A distractor kanji must not also answer the prompt.
          if (o.literal != k.literal &&
              !o.meaningList.contains(prompt) &&
              !distractors.contains(o.literal)) {
            distractors.add(o.literal);
          }
          if (distractors.length == optionCount - 1) break;
        }
      case QuestionFormat.readingToKanji:
        prompt = _readingForm(k).reading;
        correct = k.literal;
        for (final o in others) {
          // A distractor kanji must not also read the prompt.
          if (o.literal != k.literal &&
              !o.onList.contains(prompt) &&
              !o.kunList.contains(prompt) &&
              !distractors.contains(o.literal)) {
            distractors.add(o.literal);
          }
          if (distractors.length == optionCount - 1) break;
        }
    }
    return BattleQuestion(
      literal: k.literal,
      format: format,
      prompt: prompt,
      options: [correct, ...distractors]..shuffle(rng),
      correct: correct,
    );
  }

  /// [n] questions in randomly mixed [formats]. Reading recall (kanji→reading)
  /// becomes [QuestionMode.typed] and kanji production (reading→kanji) becomes
  /// [QuestionMode.drawn] when the encounter [floor] demands it (tougher foes)
  /// or the kanji is mastered enough (progression) — whichever is harder
  /// (DESIGN.md §3.4). The meaning formats have no hard form yet, so they stay
  /// multiple choice.
  List<BattleQuestion> volley(
    int n,
    List<QuestionFormat> formats, {
    QuestionMode floor = QuestionMode.choice,
  }) =>
      [
        for (final k in _sample(n)) _buildWithDifficulty(k, formats, floor),
      ];

  BattleQuestion _buildWithDifficulty(
      KanjiEntry k, List<QuestionFormat> formats, QuestionMode floor) {
    final format = formats[rng.nextInt(formats.length)];
    return _build(k, format, _modeFor(k, format, floor));
  }

  /// The hardest answer mode this format will take for kanji [k] under [floor],
  /// combining the encounter floor with the kanji's mastery (§3.4).
  QuestionMode _modeFor(KanjiEntry k, QuestionFormat format, QuestionMode floor) {
    switch (format) {
      case QuestionFormat.kanjiToReading:
        return floor.index >= QuestionMode.typed.index ||
                typedMastered.contains(k.literal)
            ? QuestionMode.typed
            : QuestionMode.choice;
      case QuestionFormat.readingToKanji:
        return floor.index >= QuestionMode.drawn.index ||
                drawnMastered.contains(k.literal)
            ? QuestionMode.drawn
            : QuestionMode.choice;
      case QuestionFormat.kanjiToMeaning:
      case QuestionFormat.meaningToKanji:
      case QuestionFormat.listenToMeaning:
        // Listen-and-translate is always a tap (you pick the meaning); its
        // difficulty is the audio prompt, handled by the ListenQuestion card.
        return QuestionMode.choice;
    }
  }
}

/// Loads the question pool and castable-kanji checker for a battle.
/// God mode (dev) widens questions to the whole N5 set and casting to the
/// entire dictionary — for testing magic before much is learned.
class BattleData {
  BattleData(this.bank, this._castable);

  final QuestionBank bank;
  final Future<KanjiEntry?> Function(String literal) _castable;

  /// The kanji entry for [literal] if the player may cast it, else null.
  Future<KanjiEntry?> castable(String literal) => _castable(literal);

  static Future<BattleData> load(AppDatabase db, {bool godMode = false}) async {
    final learned = await db.learnedLiterals();
    final due = {
      for (final c in await db.dueCards(DateTime.now())) c.literal,
    };
    // Mastery climbs the difficulty ladder (DESIGN.md §3.4): reading recall
    // turns typed once a card matures, kanji production turns drawn further on.
    final typedMastered =
        await db.masteredLiterals(minStability: masteryStabilityDays);
    final drawnMastered =
        await db.masteredLiterals(minStability: drawMasteryStabilityDays);
    final List<KanjiEntry> pool;
    if (godMode) {
      pool = await db.kanjiForLevel(5);
    } else {
      pool = [for (final l in learned) await db.kanjiByLiteral(l)];
    }
    return BattleData(
      QuestionBank(pool, due,
          typedMastered: typedMastered, drawnMastered: drawnMastered),
      (literal) async {
        if (!godMode && !learned.contains(literal)) return null;
        return db.kanjiByLiteralOrNull(literal);
      },
    );
  }
}
