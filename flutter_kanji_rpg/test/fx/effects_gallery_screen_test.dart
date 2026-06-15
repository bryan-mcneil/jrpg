import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/backgrounds/battle_background.dart';
import 'package:flutter_kanji_rpg/backgrounds/menu_background.dart';
import 'package:flutter_kanji_rpg/fx/damage_number.dart';
import 'package:flutter_kanji_rpg/fx/effects_gallery_screen.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('spawns a floating number that clears itself', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EffectsGalleryScreen()));

    expect(find.byType(FloatingCombatText), findsNothing);

    await _tap(tester, 'fx-heal');
    expect(find.byType(FloatingCombatText), findsOneWidget);

    // The number lives ~850ms, then removes itself via onComplete.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    expect(find.byType(FloatingCombatText), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles between the battle and menu backdrops', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EffectsGalleryScreen()));

    expect(find.byType(BattleBackground), findsOneWidget);
    expect(find.byType(MenuBackground), findsNothing);

    await _tap(tester, 'toggle-menu-bg');

    expect(find.byType(MenuBackground), findsOneWidget);
    expect(find.byType(BattleBackground), findsNothing);
  });

  testWidgets('cast burst and screen shake fire without error',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EffectsGalleryScreen()));

    await _tap(tester, 'fx-burst');
    await _tap(tester, 'fx-screenshake');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
