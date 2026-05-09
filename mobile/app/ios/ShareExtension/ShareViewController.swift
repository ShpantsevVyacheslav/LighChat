// ShareViewController for LighChat Share Extension.
//
// Контракт `receive_sharing_intent`: наш controller наследуется от
// `RSIShareViewController`. Базовый класс читает выбранные пользователем
// ресурсы (изображения/видео/файлы/URL/текст), копирует их в shared App
// Group container, формирует deep-link `ShareMedia-<bundleId>://...` и
// открывает основное приложение. Flutter listener (`ShareIntentListener`)
// получает payload через `getInitialMedia()` / `getMediaStream()`.
//
// `groupId` должен совпадать с App Group основного app + extension —
// см. *.entitlements обоих таргетов.

import receive_sharing_intent
import UIKit

class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool {
        // Не показывать compose-UI: сразу скопировать payload и открыть LighChat.
        // На iOS это ощущается как «Поделиться → LighChat → готовый композер»,
        // как в Telegram/WhatsApp.
        return true
    }
}
