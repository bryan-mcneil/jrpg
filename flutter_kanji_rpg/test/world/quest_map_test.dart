import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/world/quest_map.dart';

/// A tiny linear quest used to exercise the pure progression model without
/// depending on the authored JSON content.
QuestMap _fixture() => const QuestMap(id: 't', title: 'Test', nodes: [
      QuestNode(
          id: 'a', title: 'A', type: QuestNodeType.npc, x: 0.1, y: 0.1),
      QuestNode(
          id: 'b',
          title: 'B',
          type: QuestNodeType.skirmish,
          x: 0.2,
          y: 0.2,
          formationId: 'skirmish',
          requires: ['a']),
      QuestNode(
          id: 'c',
          title: 'C',
          type: QuestNodeType.boss,
          x: 0.3,
          y: 0.3,
          formationId: 'boss',
          requires: ['b']),
    ]);

void main() {
  group('QuestMap', () {
    test('edges() yields one segment per prerequisite link', () {
      expect(_fixture().edges(), hasLength(2));
    });

    test('nodeById finds nodes', () {
      expect(_fixture().nodeById('b').title, 'B');
    });
  });

  group('QuestProgress gates the map', () {
    test('fresh progress unlocks only the root node', () {
      final map = _fixture();
      final p = QuestProgress();
      final available = map.nodes.where(p.isAvailable).map((n) => n.id).toList();
      expect(available, ['a']);
    });

    test('clearing a node unlocks exactly its successor', () {
      final map = _fixture();
      final p = QuestProgress();
      p.clear('a');
      expect(p.isCleared('a'), isTrue);
      expect(p.isAvailable(map.nodeById('a')), isFalse);
      expect(p.isAvailable(map.nodeById('b')), isTrue);
      // The node two steps out stays locked.
      expect(p.isUnlocked(map.nodeById('c')), isFalse);
    });

    test('clearing the whole chain completes the quest', () {
      final map = _fixture();
      final p = QuestProgress();
      for (final node in map.nodes) {
        expect(p.isUnlocked(node), isTrue,
            reason: 'nodes should unlock in order as the chain clears');
        p.clear(node.id);
      }
      expect(p.isComplete(map), isTrue);
    });

    test('a locked node is never available even if a later one is cleared', () {
      final map = _fixture();
      final p = QuestProgress(['c']);
      expect(p.isAvailable(map.nodeById('b')), isFalse);
      expect(p.isUnlocked(map.nodeById('b')), isFalse);
    });
  });
}
