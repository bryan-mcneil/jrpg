import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/widgets/element_medallion.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders its element glyph', (tester) async {
    await tester.pumpWidget(_host(
        const ElementMedallion(glyph: '火', color: Color(0xFFE25822))));
    expect(find.text('火'), findsOneWidget);
  });

  testWidgets('fires onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_host(ElementMedallion(
      glyph: '水',
      color: const Color(0xFF3B82C4),
      onTap: () => tapped = true,
    )));
    await tester.tap(find.text('水'));
    expect(tapped, isTrue);
  });

  testWidgets('is inert without an onTap', (tester) async {
    await tester.pumpWidget(_host(
        const ElementMedallion(glyph: '木', color: Color(0xFF4C9A4C))));
    // No GestureDetector wrapper when non-interactive.
    expect(find.byType(GestureDetector), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
