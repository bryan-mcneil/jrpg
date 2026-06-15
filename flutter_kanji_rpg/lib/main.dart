import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fx/effects_gallery_screen.dart';
import 'providers.dart';
import 'screens/battle_setup_screen.dart';
import 'screens/browser_screen.dart';
import 'screens/draw_test_screen.dart';
import 'screens/game_screen.dart';
import 'screens/lesson_screen.dart';
import 'screens/review_screen.dart';
import 'screens/testout_screen.dart';
import 'screens/title_screen.dart';
import 'screens/trace_test_screen.dart';
import 'screens/world_map_screen.dart';

void main() {
  runApp(const ProviderScope(child: KanjiRpgApp()));
}

class KanjiRpgApp extends StatelessWidget {
  const KanjiRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanji RPG',
      theme: ThemeData.dark(),
      home: const _TitleRoot(),
    );
  }
}

/// The concept-art title screen (DESIGN.md §3.9, §5) is the app's first
/// screen. NEW GAME / CONTINUE both open the milestone dev hub for now — the
/// real save/new-game flow arrives with the M4 world map.
class _TitleRoot extends StatelessWidget {
  const _TitleRoot();

  @override
  Widget build(BuildContext context) {
    void enter() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HomeMenu()));
    return TitleScreen(onNewGame: enter, onContinue: enter);
  }
}

/// Dev menu while the game is a set of milestone prototypes.
class HomeMenu extends ConsumerWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueCountProvider).value;

    void open(Widget screen) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen))
          .then((_) => ref.invalidate(dueCountProvider));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1423),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '火',
              style: TextStyle(fontSize: 72, color: Color(0xFFE25822)),
            ),
            const SizedBox(height: 4),
            const Text('Kanji RPG', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('menu-lesson'),
              onPressed: () => open(const LessonScreen()),
              child: const Text('Lesson (M2)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('menu-review'),
              onPressed: () => open(const ReviewScreen()),
              child: Text(
                dueCount == null
                    ? 'Reviews (M2)'
                    : 'Reviews (M2) — $dueCount due',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('menu-testout'),
              onPressed: () => open(const TestOutScreen()),
              child: const Text('Test-out N5 (M2)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('menu-battle'),
              onPressed: () => open(const BattleSetupScreen()),
              child: const Text('Battle (M3)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('menu-worldmap'),
              onPressed: () => open(const WorldMapScreen()),
              child: const Text('World Map (M4)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('menu-browser'),
              onPressed: () => open(const BrowserScreen()),
              child: const Text('Kanji Browser (M2)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('menu-draw'),
              onPressed: () => open(const DrawTestScreen()),
              child: const Text('Drawing Test (M1)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('menu-trace'),
              onPressed: () => open(const TraceTestScreen()),
              child: const Text('Tracing Test (M1)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('menu-game'),
              onPressed: () => open(const GameScreen()),
              child: const Text('Flame Scene (M0)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('menu-fx'),
              onPressed: () => open(const EffectsGalleryScreen()),
              child: const Text('FX Gallery (M3)'),
            ),
          ],
        ),
      ),
    );
  }
}
