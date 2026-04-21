import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../ui/app_backdrop.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(child: child);
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.14 : 0.55),
            ),
            color: (dark ? Colors.white : Colors.white).withValues(alpha: dark ? 0.07 : 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.55 : 0.15),
                blurRadius: dark ? 48 : 40,
                offset: const Offset(0, 16),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Inner highlight.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: dark ? 0.08 : 0.40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

