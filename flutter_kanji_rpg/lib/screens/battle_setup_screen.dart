import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../battle/balance.dart';
import '../battle/models.dart';
import '../battle/question_bank.dart';
import '../providers.dart';
import 'battle_screen.dart';

/// Dev battle launcher for the M3 slice: pick the skirmish or the boss,
/// with two dev toggles — god mode (cast any kanji, N5 question pool, for
/// exercising magic before much is learned) and a 1-HP glass-cannon run to
/// see the defeat path.
class BattleSetupScreen extends ConsumerStatefulWidget {
  const BattleSetupScreen({super.key});

  @override
  ConsumerState<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends ConsumerState<BattleSetupScreen> {
  String _formationId = 'skirmish';
  bool _godMode = false;
  bool _glassCannon = false;
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final data = await BattleData.load(db, godMode: _godMode);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!data.bank.usable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Learn at least 8 kanji first — or enable god mode.'),
      ));
      return;
    }
    final formation =
        formations.firstWhere((f) => f.id == _formationId);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BattleScreen(
        formation: formation,
        data: data,
        playerHp: _glassCannon ? 1 : playerMaxHp,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battle (M3)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Formation', style: TextStyle(fontSize: 16)),
          RadioGroup<String>(
            groupValue: _formationId,
            onChanged: (v) => setState(() => _formationId = v!),
            child: const Column(
              children: [
                RadioListTile<String>(
                  key: Key('setup-skirmish'),
                  title: Text('Skirmish — Ink Beasts (×2)'),
                  subtitle: Text('インク小鬼 (木) + インク蝙蝠 (金)'),
                  value: 'skirmish',
                ),
                RadioListTile<String>(
                  key: Key('setup-swarm'),
                  title: Text('Swarm — インクの群れ (×3)'),
                  subtitle: Text('針 (金) ×2 + 蔦 (木) — storm clears, blade finishes'),
                  value: 'swarm',
                ),
                RadioListTile<String>(
                  key: Key('setup-miniboss'),
                  title: Text('Mini-boss — 忘火の番人 (火)'),
                  subtitle:
                      Text('Forces typed readings; weak to 水, immune to 火傷'),
                  value: 'miniboss',
                ),
                RadioListTile<String>(
                  key: Key('setup-boss'),
                  title: Text('Boss — 忘水の精 (水)'),
                  subtitle:
                      Text('Telegraphs 大水流 — DEFEND when it charges'),
                  value: 'boss',
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('setup-godmode'),
            title: const Text('God mode (dev)'),
            subtitle:
                const Text('Cast any dictionary kanji; N5 question pool'),
            value: _godMode,
            onChanged: (v) => setState(() => _godMode = v),
          ),
          SwitchListTile(
            key: const Key('setup-hp1'),
            title: const Text('Glass cannon (dev)'),
            subtitle: const Text('Start with 1 HP — lose to any hit'),
            value: _glassCannon,
            onChanged: (v) => setState(() => _glassCannon = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('setup-start'),
            onPressed: _loading ? null : _start,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.flash_on),
            label: const Text('Begin battle'),
          ),
        ],
      ),
    );
  }
}
