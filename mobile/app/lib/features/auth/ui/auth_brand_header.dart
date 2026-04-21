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
            SizedBox(
              width: 16,
              height: 42,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Text(
                    'i',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.4,
                      color: lighColor,
                    ),
                  ),
                  Positioned(
                    top: 3,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: orangeDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
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
