import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/apple_intelligence.dart';
import 'ai_text_action_sheet.dart';

/// Открывает sheet с AI-digest по уже отформатированному списку сообщений.
/// Использует универсальный [AiTextActionSheet] — поэтому получается готовый
/// premium-UX (spinner → результат → Скопировать/Закрыть) без дублирования
/// кода. Передаёт [messagesPreview] в шапку sheet'а для контекста (компактно,
/// чтобы юзер видел источник digest'а).
///
/// [messagesAsPrompt] — то же содержимое, но без обрезки, что уходит в
/// модель (`AppleIntelligence.summarizeMessages`). Разделено намеренно:
/// preview в шапке — короче для UI, prompt — полный для AI.
Future<void> openAiChatDigestSheet({
  required BuildContext context,
  required String messagesPreview,
  required String messagesAsPrompt,
}) {
  final l10n = AppLocalizations.of(context)!;
  return AiTextActionSheet.show(
    context: context,
    title: l10n.ai_catch_me_up_title,
    original: messagesPreview,
    run: (_) async {
      final result =
          await AppleIntelligence.instance.summarizeMessages(messagesAsPrompt);
      return result;
    },
  );
}
