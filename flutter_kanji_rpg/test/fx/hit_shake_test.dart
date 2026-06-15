import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/fx/hit_shake.dart';

void main() {
  testWidgets('renders its child and survives a hit() jolt', (tester) async {
    final key = GlobalKey<HitShakeState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: HitShake(key: key, child: const Text('鬼')),
        ),
      ),
    ));

    expect(find.text('鬼'), findsOneWidget);

    key.currentState!.hit();
    await tester.pump(); // start
    await tester.pump(const Duration(milliseconds: 80)); // mid-flash
    // The flash overlay is painted while the jolt plays.
    expect(find.byType(ColoredBox), findsWidgets);

    await tester.pump(const Duration(milliseconds: 400)); // settle
    expect(tester.takeException(), isNull);
    expect(find.text('鬼'), findsOneWidget);
  });

  testWidgets('hit() is safe to call repeatedly', (tester) async {
    final key = GlobalKey<HitShakeState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HitShake(key: key, child: const SizedBox())),
    ));
    key.currentState!.hit();
    await tester.pump(const Duration(milliseconds: 50));
    key.currentState!.hit(flash: Colors.white, intensity: 12);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
