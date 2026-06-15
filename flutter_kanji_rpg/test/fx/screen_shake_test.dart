import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/fx/screen_shake.dart';

void main() {
  testWidgets('renders its child and shakes without error', (tester) async {
    final key = GlobalKey<ScreenShakeState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScreenShake(key: key, child: const Text('scene')),
      ),
    ));

    expect(find.text('scene'), findsOneWidget);

    key.currentState!.shake(intensity: 14);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500)); // settle
    expect(tester.takeException(), isNull);
    expect(find.text('scene'), findsOneWidget);
  });
}
