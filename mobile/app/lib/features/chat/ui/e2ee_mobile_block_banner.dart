import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Phase 0 safety helpers: мобайл пока read‑only для E2EE‑чатов, пока не
/// появится мобильная шифрующая ветка (Phase 4). Эти утилиты используются
/// chat_screen / thread_screen для единообразного поведения UI.
///
/// Почему не в chat_repository: репозиторий говорит «нет, plaintext в E2EE‑чат
/// писать нельзя» (через `E2eeNotSupportedOnMobileException`). UI должен
/// заранее спрятать composer, чтобы не показывать юзеру ошибку задним числом.

/// Возвращает true, если чат активно зашифрован:
/// 1) включён флаг `e2eeEnabled`
/// 2) создана как минимум одна эпоха ключа (`e2eeKeyEpoch > 0`) — значит,
///    на вебе уже лежат обёртки ключа и собеседник ждёт ciphertext.
///
/// Возвращает false при `data == null`, чтобы не мешать первичному рендеру
/// до прихода данных из Firestore.
bool isConversationE2eeActive(Conversation? data) {
  if (data == null) return false;
  if (data.e2eeEnabled != true) return false;
  final epoch = data.e2eeKeyEpoch ?? 0;
  return epoch > 0;
}

/// Заменяет обычный input‑row в [ChatComposer] на понятный баннер, когда чат
/// активно зашифрован. Вся input‑строка полностью скрывается, чтобы ни
/// sticker‑suggestion, ни микрофон, ни attach‑кнопка не могли триггернуть
/// запись plaintext.
class E2eeMobileBlockBanner extends StatelessWidget {
  const E2eeMobileBlockBanner({super.key, this.contextLabel});

  /// Опциональный уточняющий префикс («Ответ в обсуждение» / «Сообщение» и т.п.).
  /// По умолчанию используется нейтральный вариант про «Сообщение».
  final String? contextLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final prefix = contextLabel ?? 'Сообщение';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: dark ? 0.08 : 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.16 : 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$prefix в зашифрованный чат пока можно отправить только с '
              'веб‑клиента.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
