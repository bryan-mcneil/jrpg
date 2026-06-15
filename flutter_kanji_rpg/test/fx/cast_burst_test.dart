import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/fx/cast_burst.dart';

void main() {
  testWidgets('plays once, shows the glyph, and reports completion',
      (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: CastBurst(
            color: const Color(0xFFE25822),
            glyph: '火',
            onComplete: () => done = true,
          ),
        ),
      ),
    ));

    expect(find.text('火'), findsOneWidget);
    expect(done, isFalse);

    await tester.pump(const Duration(milliseconds: 650)); // past the 600ms life
    expect(done, isTrue);
  });

  testWidgets('runs without a center glyph', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: CastBurst(color: Color(0xFF3B82C4))),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
