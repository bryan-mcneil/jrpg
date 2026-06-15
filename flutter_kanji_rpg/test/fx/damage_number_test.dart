import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/fx/damage_number.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('shows the text and calls onComplete after its lifetime',
      (tester) async {
    var done = false;
    await tester.pumpWidget(_host(FloatingCombatText(
      text: '42',
      onComplete: () => done = true,
    )));

    expect(find.text('42'), findsOneWidget);
    expect(done, isFalse);

    // Animation runs 850ms; pump past it plus a frame for the callback.
    await tester.pump(const Duration(milliseconds: 900));
    expect(done, isTrue);
  });

  testWidgets('the amount factory adds the heal "+" prefix', (tester) async {
    await tester.pumpWidget(
        _host(FloatingCombatText.amount(12, kind: CombatTextKind.heal)));
    expect(find.text('+12'), findsOneWidget);
  });

  testWidgets('damage amounts carry no prefix', (tester) async {
    await tester.pumpWidget(_host(FloatingCombatText.amount(7)));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('renders mid-flight without overflow or error', (tester) async {
    await tester.pumpWidget(_host(FloatingCombatText.amount(99,
        kind: CombatTextKind.crit)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('99'), findsOneWidget);
  });
}
