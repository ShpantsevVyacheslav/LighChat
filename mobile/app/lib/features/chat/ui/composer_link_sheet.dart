import 'dart:ui';

import 'package:flutter/material.dart';

/// Ввод URL ссылки в стиле стеклянной шапки чата (без белого AlertDialog).
Future<String?> showComposerLinkSheet(BuildContext context) async {
  final urlCtrl = TextEditingController();
  final r = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
      final fg = Colors.white.withValues(alpha: 0.92);
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ссылка',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlCtrl,
                        style: TextStyle(color: fg, fontSize: 16),
                        cursorColor: fg,
                        keyboardType: TextInputType.url,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'https://…',
                          hintStyle: TextStyle(
                            color: fg.withValues(alpha: 0.45),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Отмена',
                              style: TextStyle(color: fg.withValues(alpha: 0.75)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              foregroundColor: fg,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(ctx, urlCtrl.text.trim()),
                            child: const Text('Применить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return r;
}
