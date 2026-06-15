import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_rpg/util/romaji.dart';

void main() {
  group('romajiToHiragana', () {
    test('basic syllables', () {
      expect(romajiToHiragana('aiueo'), 'あいうえお');
      expect(romajiToHiragana('ka'), 'か');
      expect(romajiToHiragana('taberu'), 'たべる');
      expect(romajiToHiragana('mizu'), 'みず');
      expect(romajiToHiragana('yama'), 'やま');
    });

    test('digraphs and alternate spellings', () {
      expect(romajiToHiragana('shi'), 'し');
      expect(romajiToHiragana('si'), 'し');
      expect(romajiToHiragana('chi'), 'ち');
      expect(romajiToHiragana('tsu'), 'つ');
      expect(romajiToHiragana('ji'), 'じ');
      expect(romajiToHiragana('fu'), 'ふ');
      expect(romajiToHiragana('kya'), 'きゃ');
      expect(romajiToHiragana('sha'), 'しゃ');
      expect(romajiToHiragana('ryo'), 'りょ');
    });

    test('ん: nn, n before a consonant, and final n', () {
      expect(romajiToHiragana('konnichiha'), 'こんにちは');
      expect(romajiToHiragana('shinbun'), 'しんぶん');
      expect(romajiToHiragana('hon'), 'ほん');
      expect(romajiToHiragana('onna'), 'おんな');
      // 'n' + vowel/y still forms its own syllable.
      expect(romajiToHiragana('nihon'), 'にほん');
      expect(romajiToHiragana('hannya'), 'はんにゃ');
    });

    test('sokuon (doubled consonant) → small っ', () {
      expect(romajiToHiragana('kitte'), 'きって');
      expect(romajiToHiragana('gakkou'), 'がっこう');
      expect(romajiToHiragana('matcha'), 'まっちゃ');
      expect(romajiToHiragana('zasshi'), 'ざっし');
    });

    test('kana and other characters pass through untouched', () {
      // A Japanese IME hands us kana directly — must round-trip.
      expect(romajiToHiragana('たべる'), 'たべる');
      expect(romajiToHiragana('みず'), 'みず');
      // Mixed / already-partly-kana input.
      expect(romajiToHiragana('たberu'), 'たべる');
    });

    test('partial trailing input stays visible for the next keystroke', () {
      expect(romajiToHiragana('tab'), 'たb');
      expect(romajiToHiragana('taber'), 'たべr');
      expect(romajiToHiragana('k'), 'k');
      // A lone trailing n is pending, not yet ん.
      expect(romajiToHiragana('ni'), 'に');
    });

    test('uppercase is accepted', () {
      expect(romajiToHiragana('TABERU'), 'たべる');
      expect(romajiToHiragana('Mizu'), 'みず');
    });
  });
}
