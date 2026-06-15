import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../util/kana.dart';

part 'database.g.dart';

/// Dictionary entries seeded from assets/data/kanji.json (built by
/// tool/import.dart from KANJIDIC2 + KanjiVG + KRADFILE).
class KanjiEntries extends Table {
  TextColumn get literal => text()();
  IntColumn get strokeCount => integer()();
  IntColumn get grade => integer().nullable()();
  IntColumn get freq => integer().nullable()();

  /// JLPT level: 5 = N5 … 1 = N1.
  IntColumn get level => integer()();

  // JSON-encoded string lists.
  TextColumn get meanings => text()();
  TextColumn get onReadings => text()();
  TextColumn get kunReadings => text()();
  TextColumn get components => text()();

  /// Element (fire/water/wood/earth/metal/light/dark) or modifier class
  /// (storm/blade/ward/amp/orb/mend) — the magic-grammar tag.
  TextColumn get tag => text()();

  /// JSON list of KanjiVG SVG path strings in stroke order (109×109 space).
  TextColumn get strokes => text()();

  @override
  Set<Column> get primaryKey => {literal};
}

/// Common words seeded from assets/data/vocab.json (built by
/// tool/import.dart from JMdict). Every kanji in [word] exists in
/// [KanjiEntries]; [level] is the hardest constituent kanji's level.
class VocabEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get reading => text()();

  /// JSON-encoded string list.
  TextColumn get glosses => text()();
  TextColumn get pos => text().nullable()();
  IntColumn get level => integer()();

  /// JMdict priority rank; lower = more common.
  IntColumn get rank => integer()();
}

/// One FSRS card per learned kanji; columns mirror the fsrs package's Card.
class SrsCards extends Table {
  TextColumn get literal => text().references(KanjiEntries, #literal)();
  IntColumn get cardId => integer()();
  IntColumn get state => integer()(); // fsrs State.value
  IntColumn get step => integer().nullable()();
  RealColumn get stability => real().nullable()();
  RealColumn get difficulty => real().nullable()();
  DateTimeColumn get due => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {literal};
}

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get literal => text()();
  IntColumn get rating => integer()(); // fsrs Rating.value
  DateTimeColumn get reviewedAt => dateTime()();
  IntColumn get durationMs => integer().nullable()();
}

@DriftDatabase(tables: [KanjiEntries, VocabEntries, SrsCards, ReviewLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kanji_rpg'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedKanji();
          await _seedVocab();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 installs predate the JMdict vocab import.
            await m.createTable(vocabEntries);
            await _seedVocab();
          }
          if (from < 3) {
            // v3 added the 力/強-type boon (buff) modifier: re-tag kanji from
            // the refreshed asset so existing installs can cast buffs too.
            await _retagKanji();
          }
        },
      );

  Future<void> _seedKanji() async {
    final raw = await rootBundle.loadString('assets/data/kanji.json');
    final list = (jsonDecode(raw) as Map<String, dynamic>)['kanji'] as List;
    await batch((b) {
      for (final e in list.cast<Map<String, dynamic>>()) {
        b.insert(
          kanjiEntries,
          KanjiEntriesCompanion.insert(
            literal: e['literal'] as String,
            strokeCount: e['stroke_count'] as int,
            grade: Value(e['grade'] as int?),
            freq: Value(e['freq'] as int?),
            level: e['level'] as int,
            meanings: jsonEncode(e['meanings']),
            onReadings: jsonEncode(e['on']),
            kunReadings: jsonEncode(e['kun']),
            components: jsonEncode(e['components']),
            tag: e['tag'] as String,
            strokes: jsonEncode(e['strokes']),
          ),
        );
      }
    });
  }

  /// Re-applies element/modifier tags from the bundled asset onto existing
  /// rows (a migration helper — tags evolve faster than the rest of a row).
  Future<void> _retagKanji() async {
    final raw = await rootBundle.loadString('assets/data/kanji.json');
    final list = (jsonDecode(raw) as Map<String, dynamic>)['kanji'] as List;
    await batch((b) {
      for (final e in list.cast<Map<String, dynamic>>()) {
        b.update(
          kanjiEntries,
          KanjiEntriesCompanion(tag: Value(e['tag'] as String)),
          where: ($KanjiEntriesTable t) =>
              t.literal.equals(e['literal'] as String),
        );
      }
    });
  }

  Future<void> _seedVocab() async {
    final raw = await rootBundle.loadString('assets/data/vocab.json');
    final list = (jsonDecode(raw) as Map<String, dynamic>)['words'] as List;
    await batch((b) {
      for (final e in list.cast<Map<String, dynamic>>()) {
        b.insert(
          vocabEntries,
          VocabEntriesCompanion.insert(
            word: e['word'] as String,
            reading: e['reading'] as String,
            glosses: jsonEncode(e['glosses']),
            pos: Value(e['pos'] as String?),
            level: e['level'] as int,
            rank: e['rank'] as int,
          ),
        );
      }
    });
  }

  /// Common words containing [literal], most common first (rank ties
  /// break on rowid = the asset's easiest-level-first order).
  Future<List<VocabEntry>> wordsWithKanji(String literal, {int limit = 5}) =>
      (select(vocabEntries)
            ..where((v) => v.word.contains(literal))
            ..orderBy([
              (v) => OrderingTerm.asc(v.rank),
              (v) => OrderingTerm.asc(v.id),
            ])
            ..limit(limit))
          .get();

  /// Kanji of [level] in lesson order (the order import.dart wrote them:
  /// grade, then frequency — preserved by rowid).
  Future<List<KanjiEntry>> kanjiForLevel(int level) =>
      (select(kanjiEntries)..where((k) => k.level.equals(level))).get();

  Future<KanjiEntry> kanjiByLiteral(String literal) =>
      (select(kanjiEntries)..where((k) => k.literal.equals(literal)))
          .getSingle();

  Future<KanjiEntry?> kanjiByLiteralOrNull(String literal) =>
      (select(kanjiEntries)..where((k) => k.literal.equals(literal)))
          .getSingleOrNull();

  /// Cards due at or before [now], oldest due first.
  Future<List<SrsCard>> dueCards(DateTime now) => (select(srsCards)
        ..where((c) => c.due.isSmallerOrEqualValue(now))
        ..orderBy([(c) => OrderingTerm.asc(c.due)]))
      .get();

  Stream<int> watchDueCount(DateTime now) {
    final count = srsCards.literal.count();
    final q = selectOnly(srsCards)
      ..addColumns([count])
      ..where(srsCards.due.isSmallerOrEqualValue(now));
    return q.map((row) => row.read(count)!).watchSingle();
  }

  /// Literals that already have an FSRS card (i.e. learned items).
  Future<Set<String>> learnedLiterals() async {
    final q = selectOnly(srsCards)..addColumns([srsCards.literal]);
    final rows = await q.get();
    return rows.map((r) => r.read(srsCards.literal)!).toSet();
  }

  /// Literals whose card has matured past [minStability] days of FSRS
  /// stability — "nearly mastered" items, which battles quiz the hard way
  /// (typed answers, DESIGN.md §3.4). Never-reviewed cards have null
  /// stability and are excluded.
  Future<Set<String>> masteredLiterals({required double minStability}) async {
    final q = selectOnly(srsCards)
      ..addColumns([srsCards.literal])
      ..where(srsCards.stability.isNotNull() &
          srsCards.stability.isBiggerOrEqualValue(minStability));
    final rows = await q.get();
    return rows.map((r) => r.read(srsCards.literal)!).toSet();
  }

  Future<void> upsertCard(SrsCardsCompanion card) =>
      into(srsCards).insertOnConflictUpdate(card);

  Future<void> logReview(ReviewLogsCompanion log) =>
      into(reviewLogs).insert(log);
}

extension VocabEntryLists on VocabEntry {
  List<String> get glossList => List<String>.from(jsonDecode(glosses));
}

/// Decoded views of the JSON-encoded list columns.
extension KanjiEntryLists on KanjiEntry {
  List<String> get meaningList => List<String>.from(jsonDecode(meanings));

  /// On-readings, converted from kanjidic's katakana convention to hiragana —
  /// the game shows all readings in hiragana (katakana is for loanwords).
  List<String> get onList => [
        for (final r in List<String>.from(jsonDecode(onReadings))) toHiragana(r)
      ];

  /// Kun-readings with kanjidic markup stripped: た.べる → たべる, -か → か.
  List<String> get kunList =>
      [for (final p in kunForms) p.reading];

  /// Kun-readings split into stem + okurigana, for word-form display (食べる).
  List<KunReading> get kunForms => [
        for (final r in List<String>.from(jsonDecode(kunReadings))) parseKun(r)
      ];

  /// Kun-readings for info cards: the word as the player will meet it plus
  /// its reading — 食べる（たべる） — or just the kana when no okurigana.
  List<String> get kunDisplayList => [
        for (final p in kunForms)
          p.hasOkurigana ? '${p.wordForm(literal)}（${p.reading}）' : p.reading
      ];

  /// Every quizzable reading. Shown form is `form.wordForm(literal)` (bare
  /// kanji for on-readings, 食べる for okurigana kun) and the expected answer
  /// is `form.reading`.
  List<KunReading> get readingForms => [
        for (final r in onList) KunReading(r, ''),
        ...kunForms,
      ];

  List<String> get strokeList => List<String>.from(jsonDecode(strokes));
}
