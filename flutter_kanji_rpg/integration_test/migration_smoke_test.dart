// Schema-upgrade smoke test: run WITHOUT `pm clear` over an install that
// already has data, so AppDatabase.onUpgrade (not onCreate) runs. Passing
// means the migration applied and the new vocab table is queryable.
//
//   flutter test integration_test/migration_smoke_test.dart -d <device>
@Timeout(Duration(minutes: 10))
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_kanji_rpg/main.dart' as app;

/// Pumps until [finder] matches, failing after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('migrated DB keeps working, gains vocab and the boon tag',
      (tester) async {
    app.main();

    // The app opens on the title screen; NEW GAME enters the milestone hub.
    await waitFor(tester, find.byKey(const Key('title-new-game')));
    await tester.tap(find.byKey(const Key('title-new-game')));

    // Menu renders its due count only once the (possibly migrating) DB
    // opened successfully.
    await waitFor(tester, find.textContaining('due'),
        timeout: const Duration(minutes: 2));

    await tester.tap(find.byKey(const Key('menu-browser')));
    await waitFor(tester, find.byType(ListTile));

    // v3 retag: 力/強 (N4) moved from amp to the new boon class, so the
    // migration must have rewritten their tag column — their chips read
    // "Boon". (Fresh installs get this from onCreate; this proves onUpgrade.)
    await tester.tap(find.text('N4'));
    await waitFor(tester, find.byType(ListTile));
    await tester.scrollUntilVisible(find.text('Boon').first, 200,
        scrollable: find.byType(Scrollable).last, maxScrolls: 60);
    expect(find.text('Boon'), findsWidgets);

    // The browser detail sheet still queries the (migrated) vocab table.
    await tester.tap(find.text('N5'));
    await waitFor(tester, find.byType(ListTile));
    await tester.tap(find.byType(ListTile).first);
    await waitFor(tester, find.byKey(const Key('vocab-words')));
  });
}
