import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/util/kana.dart';

void main() {
  test('katakana converts to hiragana', () {
    expect(toHiragana('ニチ'), 'にち');
    expect(toHiragana('ジン'), 'じん');
    expect(toHiragana('ヴ'), 'ゔ');
  });

  test('hiragana, kanji, and markup pass through untouched', () {
    expect(toHiragana('ひと.つ'), 'ひと.つ');
    expect(toHiragana('-か'), '-か');
    expect(toHiragana('火'), '火');
    expect(toHiragana('abc'), 'abc');
    // Long-vowel mark has no hiragana twin; keep it.
    expect(toHiragana('ページ'), 'ぺーじ');
  });

  test('parseKun splits okurigana at the dot', () {
    final p = parseKun('た.べる');
    expect(p.reading, 'たべる');
    expect(p.okurigana, 'べる');
    expect(p.stem, 'た');
    expect(p.wordForm('食'), '食べる');
  });

  test('parseKun strips affix hyphens and handles plain readings', () {
    expect(parseKun('-か').reading, 'か');
    expect(parseKun('-か').hasOkurigana, isFalse);
    expect(parseKun('ひと.つ').wordForm('一'), '一つ');
    expect(parseKun('みず').reading, 'みず');
    expect(parseKun('みず').wordForm('水'), '水');
  });
}
