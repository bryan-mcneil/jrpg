import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_kanji_rpg/backgrounds/menu_background.dart';
import 'package:flutter_kanji_rpg/screens/title_screen.dart';
import 'package:flutter_kanji_rpg/widgets/element_medallion.dart';

void main() {
  testWidgets('shows the heading, element row, and both menu entries',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));
    await tester.pump();

    // _GoldText paints the heading twice (stroke + gold fill).
    expect(find.text('Forgotten\nKanji'), findsWidgets);
    expect(find.text('NEW GAME'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
    // Six framing medallions.
    expect(find.byType(ElementMedallion), findsNWidgets(6));
  });

  testWidgets('NEW GAME and CONTINUE invoke their callbacks', (tester) async {
    var newGame = 0;
    var cont = 0;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(
        onNewGame: () => newGame++,
        onContinue: () => cont++,
      ),
    ));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('title-new-game')));
    await tester.tap(find.byKey(const Key('title-new-game')));
    await tester.ensureVisible(find.byKey(const Key('title-continue')));
    await tester.tap(find.byKey(const Key('title-continue')));
    await tester.pump();

    expect(newGame, 1);
    expect(cont, 1);
  });

  testWidgets('the whole banner is tappable, not just the centered text',
      (tester) async {
    var newGame = 0;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(onNewGame: () => newGame++),
    ));
    await tester.pump();

    // Tap well off-centre, near the left edge of the banner where there is
    // only background — no text glyph. Under HitTestBehavior.deferToChild this
    // point is dead and the tap is missed; with .opaque the banner catches it.
    final rect = tester.getRect(find.byKey(const Key('title-new-game')));
    await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
    await tester.pump();

    expect(newGame, 1);
  });

  testWidgets('CONTINUE is disabled when there is no save', (tester) async {
    var cont = 0;
    await tester.pumpWidget(MaterialApp(
      home: TitleScreen(canContinue: false, onContinue: () => cont++),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const Key('title-continue')),
        warnIfMissed: false);
    await tester.pump();
    expect(cont, 0);
  });

  testWidgets('falls back to the painted backdrop when village art is absent',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));
    // The bundled title_bg.png does not exist yet, so the image errors out
    // and the errorBuilder swaps in MenuBackground.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(MenuBackground), findsOneWidget);
  });
}
