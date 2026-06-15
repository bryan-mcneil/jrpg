import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/database.dart';

/// Bridges the fsrs scheduler and the Drift srs_cards table.
class SrsRepository {
  SrsRepository(this.db) : scheduler = fsrs.Scheduler();

  final AppDatabase db;
  final fsrs.Scheduler scheduler;

  /// Stability (in days) given to cards seeded by a passed test-out exam.
  static const int testOutStabilityDays = 60;

  fsrs.Card _cardFromRow(SrsCard row) => fsrs.Card(
        cardId: row.cardId,
        state: fsrs.State.fromValue(row.state),
        step: row.step,
        stability: row.stability,
        difficulty: row.difficulty,
        due: row.due.toUtc(),
        lastReview: row.lastReview?.toUtc(),
      );

  SrsCardsCompanion _rowFromCard(String literal, fsrs.Card card) =>
      SrsCardsCompanion.insert(
        literal: literal,
        cardId: card.cardId,
        state: card.state.value,
        step: Value(card.step),
        stability: Value(card.stability),
        difficulty: Value(card.difficulty),
        due: card.due,
        lastReview: Value(card.lastReview),
      );

  /// Creates a fresh card for a just-learned kanji, due immediately.
  Future<void> learn(String literal) async {
    final card = await fsrs.Card.create();
    await db.upsertCard(_rowFromCard(literal, card));
  }

  /// Applies an FSRS review to [literal]'s card and logs it.
  Future<DateTime> review(
    String literal,
    fsrs.Rating rating, {
    int? durationMs,
  }) async {
    final row = await (db.select(db.srsCards)
          ..where((c) => c.literal.equals(literal)))
        .getSingle();
    final result = scheduler.reviewCard(_cardFromRow(row), rating);
    await db.upsertCard(_rowFromCard(literal, result.card));
    await db.logReview(ReviewLogsCompanion.insert(
      literal: literal,
      rating: rating.value,
      reviewedAt: result.reviewLog.reviewDateTime,
      durationMs: Value(durationMs),
    ));
    return result.card.due;
  }

  /// Test-out: marks [literal] as well-known by seeding a high-stability
  /// review-state card so it enters the normal FSRS cycle far in the future.
  Future<void> seedKnown(String literal) async {
    final now = DateTime.now().toUtc();
    final card = await fsrs.Card.create(
      state: fsrs.State.review,
      stability: testOutStabilityDays.toDouble(),
      difficulty: 4,
      lastReview: now,
      due: now.add(const Duration(days: testOutStabilityDays)),
    );
    await db.upsertCard(_rowFromCard(literal, card));
  }
}
