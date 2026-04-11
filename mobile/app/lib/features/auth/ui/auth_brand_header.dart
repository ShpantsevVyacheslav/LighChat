import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF1E3A5F);
    const coral = Color(0xFFE9967A);
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
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.4,
            ),
            children: [
              TextSpan(
                text: 'Ligh',
                style: TextStyle(color: lighColor),
              ),
              const TextSpan(
                text: 'Chat',
                style: TextStyle(color: coral),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
