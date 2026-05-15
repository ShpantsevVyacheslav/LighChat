import Foundation
import UIKit

/// Помощники работы с group-mention'ами в нативном composer'е.
///
/// Mention в LighChat хранится как **inline-токен**:
/// ```
/// \u{E000}<base64url(json({userId, label}))>\u{E001}
/// ```
/// Это плоский (плейн-текстовый) формат, и его можно безопасно ноcить
/// внутри UITextView. Но визуально мы хотим показывать `@Имя` в виде
/// акцентного «чипа», а не сырых escape-символов.
///
/// Поэтому в native side держим **NSAttributedString**:
///  - При `setText`: парсим токены, заменяем каждый attributed-substring'ом
///    `@<label>` с custom-атрибутом `mentionTokenKey` (значение = весь
///    оригинальный токен, для round-trip обратно в плейн).
///  - При `textChanged`: обходим attributed string и сериализуем обратно:
///    visible-runs возвращаем как есть, mention-runs выдаём как сохранённый
///    токен. Dart side получает идентичный формат тому, что генерит
///    `MentionTokenCodec.buildToken` в pure-Flutter путях.
///  - На backspace через mention-чип удаляем весь runrange атомарно.
enum MentionAttributedString {
  static let tokenStart: Character = "\u{E000}"
  static let tokenEnd: Character = "\u{E001}"
  /// NSAttributedString key — храним полный токен (со escape-символами).
  static let tokenKey = NSAttributedString.Key("lighchat.mentionToken")

  /// Renders flat text-with-tokens into NSAttributedString. Текст без
  /// токенов возвращается без атрибутов, токены — как акцентные «чипы».
  static func render(
    plain: String, baseFont: UIFont, baseColor: UIColor, accentColor: UIColor
  ) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let baseAttrs: [NSAttributedString.Key: Any] = [
      .font: baseFont,
      .foregroundColor: baseColor,
    ]
    var i = plain.startIndex
    while i < plain.endIndex {
      if plain[i] == tokenStart {
        // Ищем закрывающий tokenEnd.
        if let endIdx = plain[i...].firstIndex(of: tokenEnd) {
          let full = String(plain[i...endIdx])
          let inner = String(plain[plain.index(after: i)..<endIdx])
          if let decoded = decodeToken(b64: inner) {
            let display = "@\(decoded.label)"
            let mentionAttrs: [NSAttributedString.Key: Any] = [
              .font: UIFont.systemFont(
                ofSize: baseFont.pointSize, weight: .semibold),
              .foregroundColor: accentColor,
              tokenKey: full,
            ]
            result.append(NSAttributedString(string: display, attributes: mentionAttrs))
            i = plain.index(after: endIdx)
            continue
          }
        }
      }
      // Накапливаем «визуальный run» до следующего токен-маркера.
      let runStart = i
      while i < plain.endIndex && plain[i] != tokenStart {
        i = plain.index(after: i)
      }
      let run = String(plain[runStart..<i])
      if !run.isEmpty {
        result.append(NSAttributedString(string: run, attributes: baseAttrs))
      }
    }
    return result
  }

  /// Serialize NSAttributedString → flat text. Mention-runs выдаются как
  /// исходные токены (значение `tokenKey`), остальное verbatim.
  static func serialize(_ attributed: NSAttributedString) -> String {
    var out = ""
    let full = NSRange(location: 0, length: attributed.length)
    attributed.enumerateAttribute(tokenKey, in: full) { value, range, _ in
      if let token = value as? String {
        out.append(token)
      } else {
        out.append(attributed.attributedSubstring(from: range).string)
      }
    }
    return out
  }

  /// Конвертация offset'а из «плейн-текст с токенами» (как живёт в
  /// Dart `controller.text` / `selection`) в offset attributed-string'а
  /// («видимая» длина, где токен сжат в `@label`). Используется чтобы
  /// корректно ставить курсор в нативном UITextView, когда Dart прислал
  /// новое значение `controller.value`.
  static func plainOffsetToVisible(plain: String, plainOffset: Int) -> Int {
    let ns = plain as NSString
    let clamped = max(0, min(plainOffset, ns.length))
    let startUtf16 = tokenStart.utf16.first!
    let endUtf16 = tokenEnd.utf16.first!
    var visible = 0
    var i = 0
    while i < clamped {
      let c = ns.character(at: i)
      if c == startUtf16 {
        var j = i + 1
        while j < ns.length && ns.character(at: j) != endUtf16 {
          j += 1
        }
        if j >= ns.length {
          visible += 1
          i += 1
          continue
        }
        if clamped <= j {
          return visible
        }
        let inner = ns.substring(
          with: NSRange(location: i + 1, length: j - i - 1))
        if let decoded = decodeToken(b64: inner) {
          visible += ("@\(decoded.label)" as NSString).length
        } else {
          visible += (j - i + 1)
        }
        i = j + 1
      } else {
        visible += 1
        i += 1
      }
    }
    return visible
  }

  /// Парсит inner-часть токена (между `` и ``).
  /// `inner` — base64url-encoded JSON `{userId, label}`. Возвращает nil
  /// на любом мусоре (тогда токен показывается как сырой текст).
  static func decodeToken(b64 inner: String) -> (uid: String, label: String)? {
    guard !inner.isEmpty else { return nil }
    // base64url → стандартный base64: `-` → `+`, `_` → `/`, paddding `=`.
    var standard = inner
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let pad = 4 - (standard.count % 4)
    if pad < 4 { standard.append(String(repeating: "=", count: pad)) }
    guard let data = Data(base64Encoded: standard) else { return nil }
    guard
      let any = try? JSONSerialization.jsonObject(with: data, options: []),
      let map = any as? [String: Any],
      let uid = (map["userId"] as? String)?.trimmingCharacters(in: .whitespaces),
      !uid.isEmpty
    else { return nil }
    let labelRaw =
      ((map["label"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
    return (uid: uid, label: labelRaw.isEmpty ? "User" : labelRaw)
  }
}
