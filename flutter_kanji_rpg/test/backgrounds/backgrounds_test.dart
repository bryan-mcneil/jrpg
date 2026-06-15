import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/backgrounds/battle_background.dart';
import 'package:flutter_kanji_rpg/backgrounds/menu_background.dart';

void main() {
  testWidgets('BattleBackground paints behind its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BattleBackground(
          color: Color(0xFFE25822),
          animate: false,
          child: Text('content'),
        ),
      ),
    ));
    // animate:false leaves the controller idle, so the tree can settle.
    await tester.pumpAndSettle();
    expect(find.text('content'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MenuBackground paints behind its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MenuBackground(
          animate: false,
          child: Text('title'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('title'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an animating BattleBackground keeps ticking without error',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BattleBackground(color: Color(0xFF3B82C4)),
      ),
    ));
    // Repeating controller: advance time in steps rather than settling.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
