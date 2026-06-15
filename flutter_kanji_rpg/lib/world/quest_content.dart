import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'quest_map.dart';

/// Loads quest content from the bundled JSON (DESIGN.md §8: "build a simple
/// JSON/YAML quest format early so writing quests doesn't mean writing Dart").
/// The parse is split out and pure so it tests on a plain string.
Future<QuestMap> loadQuestMap(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  return parseQuestMap(jsonDecode(raw) as Map<String, dynamic>);
}

QuestMap parseQuestMap(Map<String, dynamic> json) {
  final nodes = (json['nodes'] as List)
      .cast<Map<String, dynamic>>()
      .map(_parseNode)
      .toList();
  return QuestMap(
    id: json['id'] as String,
    title: json['title'] as String,
    nodes: nodes,
  );
}

QuestNode _parseNode(Map<String, dynamic> j) {
  return QuestNode(
    id: j['id'] as String,
    title: j['title'] as String,
    type: _enumByName(QuestNodeType.values, j['type'] as String, 'node type'),
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    subtitle: j['subtitle'] as String? ?? '',
    formationId: j['formationId'] as String?,
    lessonSize: j['lessonSize'] as int? ?? 0,
    dialogue: [
      for (final d in (j['dialogue'] as List? ?? const []))
        _parseLine(d as Map<String, dynamic>),
    ],
    ask: j['ask'] as int? ?? 0,
    askMode: j['askMode'] == null
        ? NpcAskMode.pick
        : _enumByName(NpcAskMode.values, j['askMode'] as String, 'askMode'),
    requires: [for (final r in (j['requires'] as List? ?? const [])) r as String],
  );
}

DialogueLine _parseLine(Map<String, dynamic> j) => DialogueLine(
      speaker: j['speaker'] as String?,
      jp: j['jp'] as String,
      en: j['en'] as String?,
    );

T _enumByName<T extends Enum>(List<T> values, String name, String label) =>
    values.firstWhere(
      (v) => v.name == name,
      orElse: () => throw FormatException('unknown $label: "$name"'),
    );
