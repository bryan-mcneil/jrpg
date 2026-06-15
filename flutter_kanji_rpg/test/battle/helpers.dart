import 'dart:convert';

import 'package:flutter_kanji_rpg/db/database.dart';

/// Builds a dictionary row without a database.
KanjiEntry kanji(
  String literal, {
  int strokes = 4,
  String tag = 'fire',
  List<String> meanings = const ['meaning'],
  List<String> on = const ['オン'],
  List<String> kun = const [],
}) =>
    KanjiEntry(
      literal: literal,
      strokeCount: strokes,
      level: 5,
      meanings: jsonEncode(meanings),
      onReadings: jsonEncode(on),
      kunReadings: jsonEncode(kun),
      components: '[]',
      tag: tag,
      strokes: '[]',
    );
