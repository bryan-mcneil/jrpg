import 'package:flutter/material.dart';

/// Display metadata for the magic-grammar tags (DESIGN.md §3.7).
class TagInfo {
  const TagInfo(this.glyph, this.label, this.color, {required this.isElement});

  final String glyph;
  final String label;
  final Color color;
  final bool isElement;
}

const tagInfo = <String, TagInfo>{
  'fire': TagInfo('火', 'Fire', Color(0xFFE25822), isElement: true),
  'water': TagInfo('水', 'Water', Color(0xFF3B82C4), isElement: true),
  'wood': TagInfo('木', 'Wood', Color(0xFF4C9A4C), isElement: true),
  'earth': TagInfo('土', 'Earth', Color(0xFFA9743B), isElement: true),
  'metal': TagInfo('金', 'Metal', Color(0xFFB0A654), isElement: true),
  'light': TagInfo('光', 'Light', Color(0xFFEDE48A), isElement: true),
  'dark': TagInfo('闇', 'Dark', Color(0xFF7B5EA7), isElement: true),
  'storm': TagInfo('嵐', 'Storm', Color(0xFF5EA7A7), isElement: false),
  'blade': TagInfo('剣', 'Blade', Color(0xFFC0C0C8), isElement: false),
  'ward': TagInfo('盾', 'Ward', Color(0xFF6A8CAF), isElement: false),
  'amp': TagInfo('大', 'Amp', Color(0xFFCF6679), isElement: false),
  'orb': TagInfo('珠', 'Orb', Color(0xFFB57EDC), isElement: false),
  'mend': TagInfo('癒', 'Mend', Color(0xFF8FBC8F), isElement: false),
  'boon': TagInfo('力', 'Boon', Color(0xFFE0B341), isElement: false),
};

class TagChip extends StatelessWidget {
  const TagChip(this.tag, {super.key});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final info = tagInfo[tag] ?? const TagInfo('?', '?', Colors.grey, isElement: false);
    return Chip(
      avatar: Text(info.glyph,
          style: TextStyle(color: info.color, fontWeight: FontWeight.bold)),
      label: Text(info.label),
      side: BorderSide(color: info.color.withValues(alpha: 0.6)),
    );
  }
}
