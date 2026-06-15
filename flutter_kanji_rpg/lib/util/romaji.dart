/// Live romaji → hiragana transliteration for typed answers (DESIGN.md §3.4).
///
/// The harder reading questions drop multiple choice and ask the player to
/// spell the reading out. On a Japanese IME they type kana directly; on a
/// plain keyboard they type romaji and we convert as they go. So this runs on
/// every keystroke and must be forgiving about a trailing, not-yet-finished
/// syllable: "tabe" → たべ, then "taber" → たべr, then "taberu" → たべる.
///
/// Kana (and anything that isn't an ASCII letter) passes through untouched, so
/// IME input and already-converted text round-trip cleanly.
library;

/// Wāpuro-style romaji table. Longest keys are matched first, so 3-letter
/// digraphs (kya, sha, tsu) win over their 2-letter prefixes.
const Map<String, String> _table = {
  // bare vowels
  'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',
  // k / g
  'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
  'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
  'kya': 'きゃ', 'kyu': 'きゅ', 'kyo': 'きょ',
  'gya': 'ぎゃ', 'gyu': 'ぎゅ', 'gyo': 'ぎょ',
  // s / z
  'sa': 'さ', 'si': 'し', 'shi': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
  'za': 'ざ', 'zi': 'じ', 'ji': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
  'sha': 'しゃ', 'shu': 'しゅ', 'sho': 'しょ',
  'sya': 'しゃ', 'syu': 'しゅ', 'syo': 'しょ',
  'ja': 'じゃ', 'ju': 'じゅ', 'jo': 'じょ',
  'jya': 'じゃ', 'jyu': 'じゅ', 'jyo': 'じょ',
  'zya': 'じゃ', 'zyu': 'じゅ', 'zyo': 'じょ',
  // t / d
  'ta': 'た', 'ti': 'ち', 'chi': 'ち', 'tu': 'つ', 'tsu': 'つ',
  'te': 'て', 'to': 'と',
  'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど',
  'cha': 'ちゃ', 'chu': 'ちゅ', 'cho': 'ちょ',
  'tya': 'ちゃ', 'tyu': 'ちゅ', 'tyo': 'ちょ',
  // n
  'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
  'nya': 'にゃ', 'nyu': 'にゅ', 'nyo': 'にょ',
  // h / b / p
  'ha': 'は', 'hi': 'ひ', 'hu': 'ふ', 'fu': 'ふ', 'he': 'へ', 'ho': 'ほ',
  'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
  'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
  'hya': 'ひゃ', 'hyu': 'ひゅ', 'hyo': 'ひょ',
  'bya': 'びゃ', 'byu': 'びゅ', 'byo': 'びょ',
  'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pyo': 'ぴょ',
  'fa': 'ふぁ', 'fi': 'ふぃ', 'fe': 'ふぇ', 'fo': 'ふぉ',
  // m
  'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
  'mya': 'みゃ', 'myu': 'みゅ', 'myo': 'みょ',
  // y / r / w
  'ya': 'や', 'yu': 'ゆ', 'yo': 'よ',
  'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
  'rya': 'りゃ', 'ryu': 'りゅ', 'ryo': 'りょ',
  'wa': 'わ', 'wo': 'を', 'wi': 'うぃ', 'we': 'うぇ',
};

bool _isVowel(String c) => 'aiueo'.contains(c);

bool _isRomajiConsonant(String c) =>
    c.length == 1 &&
    c.codeUnitAt(0) >= 0x61 &&
    c.codeUnitAt(0) <= 0x7A &&
    !_isVowel(c);

/// Converts [input] from romaji to hiragana, leaving any non-romaji runes
/// (kana, kanji, spaces, punctuation) in place. Safe to call on partial input.
String romajiToHiragana(String input) {
  final src = input.toLowerCase();
  final out = StringBuffer();
  var i = 0;
  while (i < src.length) {
    final c = src[i];

    // Pass through anything that isn't a romaji letter (kana from an IME,
    // kanji, spaces, punctuation).
    if (c.codeUnitAt(0) < 0x61 || c.codeUnitAt(0) > 0x7A) {
      out.write(input[i]); // preserve original casing of non-letters
      i++;
      continue;
    }

    // ん: a syllabic n — when it ends the input, when written explicitly as
    // n', when doubled (nn → consume just the first; the second n starts the
    // next kana, so onna → おんな), or before any consonant but y. An n before
    // a vowel or y still forms な/に/にゃ… through the table below.
    if (c == 'n') {
      final next = i + 1 < src.length ? src[i + 1] : '';
      if (next.isEmpty) {
        out.write('ん');
        i += 1;
        continue;
      }
      if (next == "'") {
        out.write('ん');
        i += 2;
        continue;
      }
      if (next == 'n' || (_isRomajiConsonant(next) && next != 'y')) {
        out.write('ん');
        i += 1;
        continue;
      }
    }

    // Sokuon: a doubled consonant (kk, tt, ss, …) writes a small っ, then the
    // second letter starts its syllable. "tch" (matcha) counts too.
    if (i + 1 < src.length &&
        _isRomajiConsonant(c) &&
        c != 'n' &&
        (src[i + 1] == c || (c == 't' && src[i + 1] == 'c'))) {
      out.write('っ');
      i += 1;
      continue;
    }

    // Greedy longest-match against the table (3 letters, then 2, then 1).
    var matched = false;
    for (var len = 3; len >= 1; len--) {
      if (i + len > src.length) continue;
      final kana = _table[src.substring(i, i + len)];
      if (kana != null) {
        out.write(kana);
        i += len;
        matched = true;
        break;
      }
    }
    if (matched) continue;

    // A letter that doesn't (yet) complete a syllable — a half-typed romaji
    // tail. Leave it visible so the next keystroke can finish it.
    out.write(input[i]);
    i++;
  }
  return out.toString();
}
