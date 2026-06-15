import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/screens/npc_dialogue_screen.dart';
import 'package:flutter_kanji_rpg/world/quest_map.dart';

void main() {
  const node = QuestNode(
    id: 'n',
    title: 'Talk',
    type: QuestNodeType.npc,
    x: 0.5,
    y: 0.5,
    dialogue: [
      DialogueLine(speaker: '翁', jp: 'こんにちは', en: 'Hello'),
      DialogueLine(jp: 'さらば'),
    ],
  );

  testWidgets('a pure-dialogue NPC reads bilingual and pops true at the end',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const NpcDialogueScreen(node: node),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));

    // Fixed pumps (not pumpAndSettle): the parchment MenuBackground drifts
    // forever, so there is nothing to "settle".
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the push transition

    // First line, shown with its English gloss.
    expect(find.byKey(const Key('npc-jp')), findsOneWidget);
    expect(find.text('こんにちは'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('翁'), findsOneWidget);

    // Advance to the second (no-questions) line, then off the end.
    await tester.tap(find.byKey(const Key('npc-next')));
    await tester.pump();
    expect(find.text('さらば'), findsOneWidget);

    await tester.tap(find.byKey(const Key('npc-next')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the pop transition

    // With no questions to ask, finishing the talk clears the node.
    expect(result, isTrue);
    expect(find.byKey(const Key('npc-jp')), findsNothing);
  });
}
