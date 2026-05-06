import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF1E3A5F);
    const coral = Color(0xFFE9967A);
    const orangeDot = Color(0xFFECA048);
    final lighColor = isDark ? const Color(0xFFC5D9ED) : navy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140, maxHeight: 140),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset('assets/lighchat_mark.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'L',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.4,
                color: lighColor,
              ),
            ),
            // Pixel-perfect "i" со встроенной orange-точкой — рисуем stem
            // и точку одним CustomPaint, чтобы не было задвоения со
            // штатной точкой шрифта.
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 2),
              child: _BrandDottedI(
                stemColor: lighColor,
                dotColor: orangeDot,
                fontSize: 40,
              ),
            ),
            Text(
              'gh',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.4,
                color: lighColor,
              ),
            ),
            const Text(
              'Chat',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.4,
                color: coral,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandDottedI extends StatelessWidget {
  const _BrandDottedI({
    required this.stemColor,
    required this.dotColor,
    required this.fontSize,
  });

  final Color stemColor;
  final Color dotColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // height = fontSize (как у Text с height: 1.0) — благодаря этому stem
    // сядет ровно от x-height ("g") до baseline ("L").
    return SizedBox(
      width: fontSize * 0.30,
      height: fontSize,
      child: CustomPaint(
        painter: _BrandDottedIPainter(stemColor: stemColor, dotColor: dotColor),
      ),
    );
  }
}

class _BrandDottedIPainter extends CustomPainter {
  const _BrandDottedIPainter({required this.stemColor, required this.dotColor});

  final Color stemColor;
  final Color dotColor;

  // Inter Heavy metrics: x-height ≈ 0.518 em, baseline = 1 em, ascender ≈ 0.78 em.
  static const _xHeight = 0.48; // top of stem (≈ top of "g")
  static const _baseline = 0.96; // bottom of stem (≈ bottom of "L")
  static const _dotCenter = 0.22; // центр coral-точки над stem
  static const _stemWidthRatio = 0.55;
  static const _dotRadiusRatio = 0.30;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stemWidth = w * _stemWidthRatio;
    final stemX = (w - stemWidth) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(stemX, h * _xHeight, stemX + stemWidth, h * _baseline),
        Radius.circular(stemWidth * 0.5),
      ),
      Paint()..color = stemColor,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * _dotCenter),
      w * _dotRadiusRatio,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandDottedIPainter old) =>
      old.stemColor != stemColor || old.dotColor != dotColor;
}
