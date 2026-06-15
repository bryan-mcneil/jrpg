/// Kana script helpers.
///
/// Kanjidic stores on-readings in katakana by dictionary convention, but the
/// game shows every reading in hiragana: learners meet hiragana first, and
/// katakana stays reserved for what Japanese actually uses it for — loanwords
/// and foreign names (e.g. the インク enemies).
String toHiragana(String s) {
  final out = StringBuffer();
  for (final rune in s.runes) {
    // Katakana ァ..ヶ sits exactly 0x60 above its hiragana twin ぁ..ゖ.
    out.writeCharCode(rune >= 0x30A1 && rune <= 0x30F6 ? rune - 0x60 : rune);
  }
  return out.toString();
}

/// One kun-reading split at kanjidic's okurigana dot: た.べる means the kanji
/// covers た and べる is written after it — the word looks like 食べる and is
/// read たべる.
class KunReading {
  const KunReading(this.reading, this.okurigana);

  /// The full kana answer the player gives: たべる.
  final String reading;

  /// The kana written after the kanji: べる (empty when none).
  final String okurigana;

  bool get hasOkurigana => okurigana.isNotEmpty;

  /// The part the kanji itself covers: た.
  String get stem => reading.substring(0, reading.length - okurigana.length);

  /// How the word appears in text: 食 + べる → 食べる.
  String wordForm(String literal) => '$literal$okurigana';
}

/// Parses kanjidic kun markup. The dot splits stem from okurigana; a hyphen
/// flags prefix/suffix use (-か in 三日). Neither is shown to players.
KunReading parseKun(String raw) {
  final s = raw.replaceAll('-', '');
  final dot = s.indexOf('.');
  if (dot < 0) return KunReading(s, '');
  return KunReading(
      s.replaceAll('.', ''), s.substring(dot + 1).replaceAll('.', ''));
}
