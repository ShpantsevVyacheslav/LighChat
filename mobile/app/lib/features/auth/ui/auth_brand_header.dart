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
    return SizedBox(
      width: fontSize * 0.30,
      height: fontSize * 1.05,
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

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Узкий stem по центру (Inter Heavy "i" — это вертикальная полоска)
    final stemWidth = w * 0.55;
    final stemX = (w - stemWidth) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stemX, h * 0.32, stemWidth, h * 0.55),
        Radius.circular(stemWidth * 0.5),
      ),
      Paint()..color = stemColor,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.14),
      stemWidth * 0.78,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandDottedIPainter old) =>
      old.stemColor != stemColor || old.dotColor != dotColor;
}
