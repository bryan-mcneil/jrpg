import 'package:flutter/material.dart';

/// An ornate circular badge: a gold bevelled ring around a dark, element-
/// tinted disc with the element glyph glowing at its center. Used to frame
/// the title screen (DESIGN.md §5 Golden-Sun look) and reusable wherever an
/// element needs a crest (world-map nodes, companion portraits).
///
/// Decoupled on purpose — takes a [glyph] + [color], never the battle/tag
/// code — so it matches the fx/background kit's "pass a Color" convention.
/// A painted placeholder for purchased pixel-art medallions; swap later.
class ElementMedallion extends StatelessWidget {
  const ElementMedallion({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 64,
    this.onTap,
  });

  final String glyph;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  static const _goldRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E0A0), Color(0xFFC79A45), Color(0xFF6E4E1F)],
  );

  @override
  Widget build(BuildContext context) {
    final ring = (size * 0.11).clamp(4.0, 12.0);
    final medallion = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _goldRing,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: size * 0.18),
          const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.all(ring),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color.lerp(color, Colors.black, 0.55)!,
              const Color(0xFF120E18),
            ],
          ),
          border: Border.all(color: const Color(0xFF3A2E22), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: size * 0.46,
            color: color,
            fontWeight: FontWeight.bold,
            height: 1,
            shadows: [Shadow(blurRadius: size * 0.12, color: color)],
          ),
        ),
      ),
    );

    if (onTap == null) return medallion;
    return GestureDetector(onTap: onTap, child: medallion);
  }
}
