/// One-time import script:
///   KANJIDIC2 + KanjiVG + KRADFILE → assets/data/kanji.json
///   JMdict_e                       → assets/data/vocab.json
///
/// Run from the project root after downloading sources into tool/cache/
/// (see tool/cache/README or DESIGN.md §2):
///
///     dart run tool/import.dart
///
/// Includes every kanji KANJIDIC2 marks with a (pre-2010) JLPT level —
/// old level 4 ≈ N5, 3 ≈ N4, 2 ≈ N2–N3, 1 ≈ N1 — which covers the v1
/// N5→N4 scope with headroom. Each kanji gets an element/modifier tag:
/// override file first, then ordered component rules, then the amp
/// fallback. Stroke paths come from KanjiVG.
///
/// Vocabulary keeps JMdict entries that carry a priority marker (the
/// "common words") and whose kanji form uses only kanji from the set
/// above; a word's level is its hardest kanji's level, so N5 words are
/// learnable with N5 kanji alone.
///
/// Data licenses: KANJIDIC2, KRADFILE, and JMdict © EDRDG (CC BY-SA),
/// KanjiVG © Ulrich Apel (CC BY-SA 3.0). Attribution ships in the app's
/// licenses screen (M6).
library;

// ignore_for_file: avoid_print -- dev-time CLI script, not app code.

import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

const cacheDir = 'tool/cache';
const outPath = 'assets/data/kanji.json';
const vocabOutPath = 'assets/data/vocab.json';
const overridesPath = 'assets/data/tag_overrides.json';

/// Ordered component → tag rules; first match wins. KRADFILE represents
/// some radicals with stand-in glyphs: 汁=氵, 刈=刂, 杰=灬, 艾=艹.
const componentRules = <(String, String)>[
  // Elements — strong components.
  ('火', 'fire'), ('杰', 'fire'),
  ('水', 'water'), ('汁', 'water'), ('冫', 'water'), ('川', 'water'),
  ('金', 'metal'),
  ('木', 'wood'), ('艾', 'wood'), ('竹', 'wood'), ('禾', 'wood'),
  ('土', 'earth'), ('山', 'earth'), ('石', 'earth'), ('田', 'earth'),
  // Modifier classes.
  ('雨', 'storm'), ('風', 'storm'), ('气', 'storm'),
  ('刀', 'blade'), ('刈', 'blade'), ('矢', 'blade'), ('弓', 'blade'),
  ('斤', 'blade'), ('戈', 'blade'),
  ('宀', 'ward'), ('囗', 'ward'), ('門', 'ward'),
  ('王', 'orb'), ('丸', 'orb'),
  ('疒', 'mend'),
  // Weak associations, checked last.
  ('日', 'fire'),
  ('大', 'amp'), ('力', 'amp'),
];

/// Old-JLPT (KANJIDIC2) → new N-level. Old 2 spanned today's N2+N3;
/// we file it under N2 — only N5/N4 must be exact for v1.
const jlptToN = {4: 5, 3: 4, 2: 2, 1: 1};

Future<void> main() async {
  final krad = readKradfile();
  final strokes = readKanjiVg();
  final overrides = (jsonDecode(File(overridesPath).readAsStringSync())
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as String))
    ..remove('_comment');

  final kanji = readKanjidic2();
  print('KANJIDIC2: ${kanji.length} JLPT-tagged kanji; '
      'KanjiVG: ${strokes.length} glyphs; KRADFILE: ${krad.length} kanji');

  final tagCounts = <String, int>{};
  var fallbacks = 0;
  var missingStrokes = 0;
  final out = <Map<String, dynamic>>[];
  for (final k in kanji) {
    final literal = k['literal'] as String;
    final components = krad[literal] ?? const <String>[];

    String tag;
    String tagSource;
    if (overrides.containsKey(literal)) {
      tag = overrides[literal]!;
      tagSource = 'override';
    } else {
      final rule = componentRules
          .where((r) => components.contains(r.$1))
          .firstOrNull;
      if (rule != null) {
        tag = rule.$2;
        tagSource = 'component:${rule.$1}';
      } else {
        tag = 'amp';
        tagSource = 'fallback';
        fallbacks++;
      }
    }
    tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;

    final paths = strokes[literal.runes.first] ?? const <String>[];
    if (paths.isEmpty) missingStrokes++;

    out.add({
      ...k,
      'components': components,
      'tag': tag,
      'tag_source': tagSource,
      'strokes': paths,
    });
  }

  // N5 first, then by school grade and frequency — this is lesson order.
  out.sort((a, b) {
    final byLevel = (b['level'] as int).compareTo(a['level'] as int);
    if (byLevel != 0) return byLevel;
    final byGrade = ((a['grade'] ?? 99) as int).compareTo((b['grade'] ?? 99) as int);
    if (byGrade != 0) return byGrade;
    return ((a['freq'] ?? 99999) as int).compareTo((b['freq'] ?? 99999) as int);
  });

  File(outPath).writeAsStringSync(jsonEncode({
    'attribution':
        'KANJIDIC2/KRADFILE © EDRDG (CC BY-SA); KanjiVG © Ulrich Apel '
            '(CC BY-SA 3.0, http://kanjivg.tagaini.net)',
    'kanji': out,
  }));

  final perLevel = <int, int>{};
  for (final k in out) {
    perLevel[k['level'] as int] = (perLevel[k['level'] as int] ?? 0) + 1;
  }
  print('Wrote ${out.length} kanji to $outPath '
      '(${File(outPath).lengthSync() ~/ 1024} KB)');
  print('Per level: ${perLevel.entries.map((e) => 'N${e.key}: ${e.value}').join(', ')}');
  print('Tags: $tagCounts');
  print('Fallback-tagged: $fallbacks; missing strokes: $missingStrokes');

  final kanjiLevels = {
    for (final k in out) (k['literal'] as String): k['level'] as int,
  };
  final words = await readJmdict(kanjiLevels);
  // Easiest level first (N5=5 sorts before N1=1), most common first within
  // a level — this is both lesson order and the LIKE-scan tiebreak order.
  words.sort((a, b) {
    final byLevel = (b['level'] as int).compareTo(a['level'] as int);
    if (byLevel != 0) return byLevel;
    final byRank = (a['rank'] as int).compareTo(b['rank'] as int);
    if (byRank != 0) return byRank;
    return (a['word'] as String).compareTo(b['word'] as String);
  });
  File(vocabOutPath).writeAsStringSync(jsonEncode({
    'attribution': 'JMdict © EDRDG (CC BY-SA)',
    'words': words,
  }));

  final wordsPerLevel = <int, int>{};
  for (final w in words) {
    wordsPerLevel[w['level'] as int] =
        (wordsPerLevel[w['level'] as int] ?? 0) + 1;
  }
  print('Wrote ${words.length} words to $vocabOutPath '
      '(${File(vocabOutPath).lengthSync() ~/ 1024} KB)');
  print('Words per level: '
      '${wordsPerLevel.entries.map((e) => 'N${e.key}: ${e.value}').join(', ')}');
}

Map<String, List<String>> readKradfile() {
  final map = <String, List<String>>{};
  for (final line in File('$cacheDir/kradfile.utf8').readAsLinesSync()) {
    if (line.startsWith('#') || line.trim().isEmpty) continue;
    final parts = line.split(' : ');
    if (parts.length != 2) continue;
    map[parts[0].trim()] =
        parts[1].trim().split(' ').where((c) => c.isNotEmpty).toList();
  }
  return map;
}

/// codepoint → SVG path data strings in stroke order.
Map<int, List<String>> readKanjiVg() {
  final kanjiRe = RegExp(r'<kanji id="kvg:kanji_([0-9a-f]{5})(-[^"]+)?">');
  final pathRe = RegExp(r'<path [^>]*\bd="([^"]+)"');
  final map = <int, List<String>>{};
  List<String>? current;
  for (final line in File('$cacheDir/kanjivg.xml').readAsLinesSync()) {
    final k = kanjiRe.firstMatch(line);
    if (k != null) {
      // Skip variant glyphs (-Kaisho etc.); keep only the standard form.
      current = k.group(2) == null ? (map[int.parse(k.group(1)!, radix: 16)] = []) : null;
      continue;
    }
    if (current == null) continue;
    final p = pathRe.firstMatch(line);
    if (p != null) current.add(unescapeXml(p.group(1)!));
  }
  return map;
}

/// Parses the line-structured KANJIDIC2 XML; keeps JLPT-tagged kanji only.
List<Map<String, dynamic>> readKanjidic2() {
  final tagRe = RegExp(r'<(\w+)([^>]*)>([^<]*)</\1>');
  final result = <Map<String, dynamic>>[];

  String? literal;
  int? grade, strokeCount, freq, jlpt;
  var meanings = <String>[];
  var on = <String>[];
  var kun = <String>[];

  void flush() {
    if (literal != null && jlpt != null) {
      result.add({
        'literal': literal,
        'stroke_count': strokeCount,
        'grade': grade,
        'freq': freq,
        'level': jlptToN[jlpt]!,
        'meanings': meanings,
        'on': on,
        'kun': kun,
      });
    }
    literal = null;
    grade = strokeCount = freq = jlpt = null;
    meanings = [];
    on = [];
    kun = [];
  }

  for (final line in File('$cacheDir/kanjidic2.xml').readAsLinesSync()) {
    if (line.startsWith('<character>')) flush();
    final m = tagRe.firstMatch(line);
    if (m == null) continue;
    final attrs = m.group(2)!;
    final text = unescapeXml(m.group(3)!);
    switch (m.group(1)) {
      case 'literal':
        literal = text;
      case 'grade':
        grade = int.parse(text);
      case 'stroke_count':
        strokeCount ??= int.parse(text); // first count is the accepted one
      case 'freq':
        freq = int.parse(text);
      case 'jlpt':
        jlpt = int.parse(text);
      case 'reading':
        if (attrs.contains('r_type="ja_on"')) on.add(text);
        if (attrs.contains('r_type="ja_kun"')) kun.add(text);
      case 'meaning':
        if (!attrs.contains('m_lang')) meanings.add(text);
    }
  }
  flush();
  return result;
}

/// Streams JMdict_e (62 MB), keeping common words covered by our kanji set.
Future<List<Map<String, dynamic>>> readJmdict(
    Map<String, int> kanjiLevels) async {
  final words = <Map<String, dynamic>>[];
  var entry = <String>[];
  var inEntry = false;
  final lines = File('$cacheDir/jmdict_e.xml')
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    if (line == '<entry>') {
      inEntry = true;
      entry = [];
    } else if (line == '</entry>') {
      inEntry = false;
      final w = parseVocabEntry(entry, kanjiLevels);
      if (w != null) words.add(w);
    } else if (inEntry) {
      entry.add(line);
    }
  }
  return words;
}

/// Lower = more common. nfXX buckets are 500-word frequency bands; the
/// named markers are interleaved among them.
int _markerRank(String marker) {
  if (marker.startsWith('nf')) return int.parse(marker.substring(2));
  return switch (marker) {
    'ichi1' => 10,
    'news1' || 'spec1' => 12,
    'ichi2' || 'news2' || 'spec2' || 'gai1' => 24,
    _ => 48,
  };
}

/// Kana, the long-vowel mark, and the kanji-repeat mark don't need to be
/// in the kanji set for a word to count as covered.
bool _isKanaOrMark(int rune) =>
    (rune >= 0x3040 && rune <= 0x30FF) || rune == 0x3005 /* 々 */;

/// One JMdict `<entry>`; returns null for entries we don't keep (kana-only,
/// no priority marker, or kanji outside our set).
Map<String, dynamic>? parseVocabEntry(
    List<String> lines, Map<String, int> kanjiLevels) {
  final tagRe = RegExp(r'<(\w+)([^>]*)>([^<]*)</\1>');

  String? keb; // first kanji form = the headword
  final kebPri = <String>[];
  var kEleIndex = -1;

  // r_ele fields accumulate, then flush on the next section boundary.
  final readings = <({String text, bool nokanji, List<String> restr})>[];
  String? curReb;
  var curNokanji = false;
  var curRestr = <String>[];
  void flushReading() {
    if (curReb != null) {
      readings.add((text: curReb!, nokanji: curNokanji, restr: curRestr));
    }
    curReb = null;
    curNokanji = false;
    curRestr = [];
  }

  final glosses = <String>[];
  String? pos;
  var senseStagks = <String>[];

  // A sense restricted by <stagk> only applies if our headword is listed.
  bool senseApplies() =>
      senseStagks.isEmpty || senseStagks.contains(keb);

  for (final line in lines) {
    switch (line) {
      case '<k_ele>':
        kEleIndex++;
        continue;
      case '<r_ele>':
        flushReading();
        continue;
      case '<sense>':
        flushReading();
        senseStagks = [];
        continue;
      case '<re_nokanji/>':
        curNokanji = true;
        continue;
    }
    final m = tagRe.firstMatch(line);
    if (m == null) continue;
    final text = unescapeXml(m.group(3)!);
    switch (m.group(1)) {
      case 'keb':
        if (kEleIndex == 0) keb = text;
      case 'ke_pri':
        if (kEleIndex == 0) kebPri.add(text);
      case 'reb':
        curReb = text;
      case 're_restr':
        curRestr.add(text);
      case 'stagk':
        senseStagks.add(text);
      case 'pos':
        // Entity refs like &n; survive line parsing as literal text.
        if (senseApplies()) pos ??= text.replaceAll(RegExp('[&;]'), '');
      case 'gloss':
        if (senseApplies() && glosses.length < 5) glosses.add(text);
    }
  }
  flushReading();

  if (keb == null || kebPri.isEmpty || glosses.isEmpty) return null;

  // Every kanji in the headword must be in our set; the hardest one
  // (lowest N number) sets the word's level.
  int? level;
  var hasKanji = false;
  for (final rune in keb.runes) {
    if (_isKanaOrMark(rune)) continue;
    final kanjiLevel = kanjiLevels[String.fromCharCode(rune)];
    if (kanjiLevel == null) return null;
    hasKanji = true;
    level = level == null ? kanjiLevel : min(level, kanjiLevel);
  }
  if (!hasKanji) return null;

  final reading = readings
      .where((r) =>
          !r.nokanji && (r.restr.isEmpty || r.restr.contains(keb)))
      .firstOrNull;
  if (reading == null) return null;

  return {
    'word': keb,
    'reading': reading.text,
    'glosses': glosses,
    'pos': pos,
    'level': level,
    'rank': kebPri.map(_markerRank).reduce(min),
  };
}

String unescapeXml(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
