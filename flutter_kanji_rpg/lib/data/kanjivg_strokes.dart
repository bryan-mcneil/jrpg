/// Kanji stroke-order path data from the KanjiVG project.
///
/// KanjiVG is copyright (C) 2009-2011 Ulrich Apel and released under the
/// Creative Commons Attribution-Share Alike 3.0 license
/// (https://creativecommons.org/licenses/by-sa/3.0/).
/// Website: http://kanjivg.tagaini.net
///
/// Paths are SVG path data in KanjiVG's 109x109 coordinate space, listed in
/// stroke order. For M1 this is a single hardcoded kanji; M2 builds a real
/// asset pipeline for the full set.
library;

/// Side length of the KanjiVG coordinate space.
const double kanjiVgSize = 109;

/// 水 (U+6C34), 4 strokes, from kanjivg file 06c34.svg.
const List<String> mizuStrokePaths = [
  // Stroke 1 ㇚ — center vertical with hook.
  'M52.77,15.08c1.08,1.08,1.67,2.49,1.76,5.52c0.4,14.55-0.26,62.16-0.26,67.12'
      'c0,9.78-7.52,0.03-9.02-1.22',
  // Stroke 2 ㇇ — left side: short horizontal bending into a long left sweep.
  'M17.5,45.75c1.75,0.62,3.73,0.43,5.25,0C25.88,44.88,36.09,41,38.59,40'
      's4.47,1.24,3.75,3.5C39,54,28.25,69,19,74.75',
  // Stroke 3 ㇒ — upper-right falling stroke toward center.
  'M81.22,27.5c-0.22,1.25-0.72,2.25-1.52,2.97'
      'c-5.64,5.1-12.45,9.78-22.45,13.78',
  // Stroke 4 ㇏ — lower-right extended sweep.
  'M57,46c8.82,10.73,19.23,21.46,28.42,27.42c2.16,1.4,4.52,3,7.08,3.58',
];
