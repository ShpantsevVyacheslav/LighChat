import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../brand_colors.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lighColor = isDark ? const Color(0xFFC5D9ED) : kBrandNavy;

    final baseStyle = GoogleFonts.outfit(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -0.4,
    );

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
            children: [
              TextSpan(text: 'Ligh', style: baseStyle.copyWith(color: lighColor)),
              TextSpan(text: 'Chat', style: baseStyle.copyWith(color: kBrandOrange)),
            ],
          ),
        ),
      ],
    );
  }
}
