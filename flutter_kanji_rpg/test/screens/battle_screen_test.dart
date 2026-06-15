import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/backgrounds/battle_background.dart';
import 'package:flutter_kanji_rpg/battle/models.dart';
import 'package:flutter_kanji_rpg/battle/question_bank.dart';
import 'package:flutter_kanji_rpg/fx/hit_shake.dart';
import 'package:flutter_kanji_rpg/fx/screen_shake.dart';
import 'package:flutter_kanji_rpg/game/tags.dart';
import 'package:flutter_kanji_rpg/screens/battle_screen.dart';

import '../battle/helpers.dart';

/// Eight distinct learnable kanji — enough for the bank to build options, and
/// a stub castable checker (no DB). The fight dynamics are proven on-device in
/// integration_test/m3_battle_test.dart; this guards that the decoupled fx kit
/// (lib/fx, lib/backgrounds) is actually wired into the live battle screen.
BattleData _data() {
  const literals = '火水木金土光闇大';
  final pool = [
    for (var i = 0; i < literals.length; i++)
      kanji(literals[i], meanings: ['meaning$i'], on: ['よみ$i']),
  ];
  return BattleData(QuestionBank(pool, const {}), (_) async => null);
}

Future<void> _pumpBattle(WidgetTester tester, Formation formation) async {
  await tester.pumpWidget(MaterialApp(
    home: BattleScreen(formation: formation, data: _data()),
  ));
  await tester.pump();
}

void main() {
  testWidgets('wraps the scene in the backdrop, screen shake, and per-card '
      'hit shakes', (tester) async {
    await _pumpBattle(tester, skirmishFormation);

    expect(find.byType(BattleBackground), findsOneWidget);
    expect(find.byType(ScreenShake), findsOneWidget);
    // One HitShake per enemy card (×2) plus the player HUD.
    expect(find.byType(HitShake), findsNWidgets(3));
  });

  testWidgets('tints the backdrop with the encounter element', (tester) async {
    await _pumpBattle(tester, bossFormation);

    final bg = tester.widget<BattleBackground>(find.byType(BattleBackground));
    expect(bg.color, tagInfo['water']!.color,
        reason: 'the 水 boss seeds a water-tinted backdrop');
  });
}
