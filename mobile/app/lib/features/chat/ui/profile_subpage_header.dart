import 'package:flutter/material.dart';

class ChatProfileSubpageHeader extends StatelessWidget {
  const ChatProfileSubpageHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(9),
                minimumSize: const Size(36, 36),
              ),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: scheme.onSurface.withValues(alpha: 0.98),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
