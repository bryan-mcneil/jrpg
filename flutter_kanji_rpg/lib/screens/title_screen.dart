import 'dart:math';

import 'package:flutter/material.dart';

import '../backgrounds/menu_background.dart';
import '../widgets/element_medallion.dart';

/// The game's title screen, built to the concept art: an ornate gold heading
/// over a rural-village scene, framed by element medallions, with NEW GAME /
/// CONTINUE beneath (DESIGN.md §3.9 "The Silent Province", §5 art direction).
///
/// Standalone and unwired by design — it is NOT set as the app `home:` yet,
/// because that lives in [main.dart] which the in-flight battle work has
/// open. Hooking it up is a one-liner once that merges. Until the purchased
/// village art is dropped at [backgroundAsset], it falls back to the painted
/// [MenuBackground] (drifting word-spirits), the same errorBuilder trick the
/// battle screen uses for missing sprites.
class TitleScreen extends StatelessWidget {
  const TitleScreen({
    super.key,
    this.title = 'Forgotten\nKanji',
    this.titlePrefix = 'The',
    this.studio = 'Scribe Studios',
    this.copyrightYear = 2024,
    this.backgroundAsset = 'assets/art/title_bg.png',
    this.onNewGame,
    this.onContinue,
    this.canContinue = true,
  });

  final String title;
  final String titlePrefix;
  final String studio;
  final int copyrightYear;
  final String backgroundAsset;
  final VoidCallback? onNewGame;
  final VoidCallback? onContinue;

  /// Greys out CONTINUE when there's no save (the save system is M4+).
  final bool canContinue;

  // Element palette mirrors game/tags.dart's tagInfo; duplicated here so the
  // title subtree imports none of the in-flight battle/tag code.
  static const _fire = Color(0xFFE25822);
  static const _water = Color(0xFF3B82C4);
  static const _wood = Color(0xFF4C9A4C);
  static const _earth = Color(0xFFA9743B);
  static const _metal = Color(0xFFB0A654);
  static const _light = Color(0xFFEDE48A);
  static const _dark = Color(0xFF7B5EA7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1423),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final short = min(constraints.maxWidth, constraints.maxHeight);
          final long = max(constraints.maxWidth, constraints.maxHeight);
          final medSize = (short * 0.13).clamp(46.0, 84.0);
          final titleBig = (short * 0.15).clamp(30.0, 92.0);
          final glyphSize = (short * 0.07).clamp(20.0, 42.0);
          final buttonWidth = (long * 0.5).clamp(220.0, 460.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _background(),
              _scrim(),
              _frame(),
              ..._medallions(medSize),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: medSize * 1.4, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _titleBlock(titleBig),
                        SizedBox(height: titleBig * 0.25),
                        _elementRow(glyphSize),
                        SizedBox(height: titleBig * 0.55),
                        _MenuButton(
                          key: const Key('title-new-game'),
                          label: 'NEW GAME',
                          width: buttonWidth,
                          accent: const Color(0xFF8FE3E6),
                          onPressed: onNewGame,
                        ),
                        const SizedBox(height: 16),
                        _MenuButton(
                          key: const Key('title-continue'),
                          label: 'CONTINUE',
                          width: buttonWidth,
                          icon: Icons.menu_book_rounded,
                          onPressed: canContinue ? onContinue : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _footer(),
            ],
          );
        },
      ),
    );
  }

  Widget _background() => Image.asset(
        backgroundAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) => const MenuBackground(),
      );

  /// Keeps the heading readable over a busy painting: a soft vignette plus a
  /// gentle darkening toward the lower third where the buttons sit.
  Widget _scrim() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [Colors.transparent, Color(0x66120E18)],
            stops: [0.55, 1.0],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x55120E18)],
              stops: [0.5, 1.0],
            ),
          ),
          child: SizedBox.expand(),
        ),
      );

  /// A thin double gold border standing in for the ornate carved frame in
  /// the concept (that frame is purchased pixel art, dropped in later).
  Widget _frame() => Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8A6A2F), width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF6E0A0), width: 1),
              ),
            ),
          ),
        ),
      );

  List<Widget> _medallions(double size) {
    Widget at(Alignment a, String glyph, Color color) => Align(
          alignment: a,
          child: Padding(
            padding: EdgeInsets.all(size * 0.22),
            child: ElementMedallion(glyph: glyph, color: color, size: size),
          ),
        );
    return [
      at(Alignment.topLeft, '水', _water),
      at(Alignment.topRight, '火', _fire),
      at(Alignment.centerLeft, '木', _wood),
      at(Alignment.centerRight, '金', _metal),
      at(Alignment.bottomLeft, '光', _light),
      at(Alignment.bottomRight, '闇', _dark),
    ];
  }

  Widget _titleBlock(double bigSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoldText(titlePrefix, size: bigSize * 0.42),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _GoldText(title, size: bigSize, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _elementRow(double glyphSize) {
    const elements = [
      ('木', _wood),
      ('火', _fire),
      ('土', _earth),
      ('金', _metal),
      ('水', _water),
    ];
    return Wrap(
      spacing: glyphSize * 0.5,
      children: [
        for (final (glyph, color) in elements)
          Text(
            glyph,
            style: TextStyle(
              fontSize: glyphSize,
              color: color,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: glyphSize * 0.4, color: color)],
            ),
          ),
      ],
    );
  }

  Widget _footer() => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '©$copyrightYear $studio   ·   All Rights Reserved.',
            style: const TextStyle(
                color: Color(0xCCEAD9B0), fontSize: 11, letterSpacing: 0.5),
          ),
        ),
      );
}

/// Heading lettering: a dark stroke behind a vertical-gold gradient fill,
/// approximating the carved-gold logo in the concept.
class _GoldText extends StatelessWidget {
  const _GoldText(this.text, {required this.size, this.textAlign});

  final String text;
  final double size;
  final TextAlign? textAlign;

  static const _gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF4C6), Color(0xFFF6D873), Color(0xFFE3A93C), Color(0xFFBC7E2B)],
    stops: [0.0, 0.45, 0.8, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: size * 0.01,
    );
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.08
              ..color = const Color(0xFF3A240C),
            shadows: [
              Shadow(
                  blurRadius: size * 0.12,
                  color: Colors.black54,
                  offset: Offset(0, size * 0.04)),
            ],
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => _gold.createShader(bounds),
          child: Text(text,
              textAlign: textAlign, style: base.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

/// A title-menu entry: a translucent banner with gold text, an optional
/// leading icon, and an optional cyan "brush stroke" underline (the active
/// flourish in the concept). Dims and ignores taps when [onPressed] is null.
class _MenuButton extends StatefulWidget {
  const _MenuButton({
    super.key,
    required this.label,
    required this.width,
    this.icon,
    this.accent,
    this.onPressed,
  });

  final String label;
  final double width;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onPressed;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final gold = enabled ? const Color(0xFFFCE9A8) : const Color(0xFF8A7E64);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        // Without this the detector defers to its child, so only the text
        // glyphs are hittable and taps on the rest of the banner are dead.
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: _pressed
                  ? [const Color(0xCC3A2E4A), const Color(0xCC241B30)]
                  : [const Color(0x99241B30), const Color(0x66120E18)],
            ),
            border: Border.all(color: const Color(0x66C79A45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: gold, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.accent != null && enabled) ...[
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  margin: EdgeInsets.symmetric(horizontal: widget.width * 0.12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      widget.accent!,
                      Colors.white,
                      widget.accent!,
                      Colors.transparent,
                    ]),
                    boxShadow: [
                      BoxShadow(color: widget.accent!.withValues(alpha: 0.7), blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
