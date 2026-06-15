import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/world/quest_content.dart';
import 'package:flutter_kanji_rpg/world/quest_map.dart';

void main() {
  group('parseQuestMap', () {
    test('parses node fields, dialogue, lessons and npc responses', () {
      final map = parseQuestMap(jsonDecode('''
      {
        "id": "demo",
        "title": "Demo",
        "nodes": [
          {"id":"l","type":"lesson","title":"L","x":0.1,"y":0.9,
           "lessonSize":6,"requires":[]},
          {"id":"n","type":"npc","title":"N","x":0.3,"y":0.6,
           "ask":2,"askMode":"type",
           "dialogue":[{"speaker":"翁","jp":"こんにちは","en":"Hello"},
                       {"jp":"さらば"}],
           "requires":["l"]},
          {"id":"b","type":"boss","title":"B","x":0.8,"y":0.2,
           "formationId":"boss","requires":["n"]}
        ]
      }''') as Map<String, dynamic>);

      expect(map.id, 'demo');
      expect(map.nodes, hasLength(3));

      final lesson = map.nodeById('l');
      expect(lesson.type, QuestNodeType.lesson);
      expect(lesson.lessonSize, 6);

      final npc = map.nodeById('n');
      expect(npc.type, QuestNodeType.npc);
      expect(npc.ask, 2);
      expect(npc.askMode, NpcAskMode.type);
      expect(npc.dialogue, hasLength(2));
      expect(npc.dialogue.first.speaker, '翁');
      expect(npc.dialogue.first.en, 'Hello');
      expect(npc.dialogue[1].en, isNull);

      final boss = map.nodeById('b');
      expect(boss.formation, isNotNull);
      expect(boss.formation!.id, 'boss');
    });

    test('an unknown node type is a FormatException', () {
      expect(
        () => parseQuestMap(jsonDecode(
            '{"id":"x","title":"X","nodes":[{"id":"a","type":"shop",'
            '"title":"A","x":0,"y":0}]}') as Map<String, dynamic>),
        throwsFormatException,
      );
    });
  });

  group('bundled quest1.json', () {
    setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

    Future<QuestMap> load() =>
        loadQuestMap('assets/data/quests/quest1.json');

    test('loads and node ids are unique', () async {
      final map = await load();
      final ids = map.nodes.map((n) => n.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(map.id, 'quest1');
    });

    test('only the first node is a root; prerequisites point backward',
        () async {
      final map = await load();
      final roots = map.nodes.where((n) => n.requires.isEmpty).toList();
      expect(roots, hasLength(1));
      expect(roots.single.id, map.nodes.first.id);

      final seen = <String>{};
      for (final node in map.nodes) {
        for (final req in node.requires) {
          expect(seen, contains(req),
              reason: '${node.id} requires $req, which must come earlier');
        }
        seen.add(node.id);
      }
    });

    test('coordinates are fractions in the playfield', () async {
      final map = await load();
      for (final node in map.nodes) {
        expect(node.x, inInclusiveRange(0.0, 1.0));
        expect(node.y, inInclusiveRange(0.0, 1.0));
      }
    });

    test('every battle node resolves to a real formation', () async {
      final map = await load();
      for (final node in map.nodes.where((n) => n.isBattle)) {
        expect(node.formation, isNotNull, reason: node.id);
        expect(formations, contains(node.formation));
      }
    });

    test('the chain opens with a lesson that fills the battle pool', () async {
      final map = await load();
      final lesson = map.nodes.first;
      expect(lesson.type, QuestNodeType.lesson);
      expect(lesson.lessonSize, greaterThanOrEqualTo(8),
          reason: 'the opening lesson must teach enough kanji to fight');
    });

    test('npc nodes carry dialogue and pose pick/type review', () async {
      final map = await load();
      final npcs = map.nodes.where((n) => n.type == QuestNodeType.npc).toList();
      expect(npcs, isNotEmpty);
      for (final npc in npcs) {
        expect(npc.dialogue, isNotEmpty, reason: npc.id);
        expect(npc.ask, greaterThan(0), reason: npc.id);
      }
      expect(npcs.map((n) => n.askMode).toSet(),
          containsAll([NpcAskMode.pick, NpcAskMode.type]),
          reason: 'quest 1 should practice both tapping and typing');
    });
  });
}
