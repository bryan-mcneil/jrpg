import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/database.dart';
import 'srs/srs_repository.dart';
import 'world/quest_content.dart';
import 'world/quest_map.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final srsRepositoryProvider =
    Provider<SrsRepository>((ref) => SrsRepository(ref.watch(databaseProvider)));

/// Number of reviews due right now. Invalidate after lessons/reviews.
final dueCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final cards = await db.dueCards(DateTime.now());
  return cards.length;
});

/// Quest 1's node map, loaded from bundled JSON content (DESIGN.md §8).
final quest1Provider = FutureProvider<QuestMap>(
    (ref) => loadQuestMap('assets/data/quests/quest1.json'));
