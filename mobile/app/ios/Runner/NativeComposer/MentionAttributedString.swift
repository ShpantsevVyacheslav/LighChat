import Foundation
import UIKit

/// Помощники для conversion'а между «rich text» формата composer'а
/// (inline HTML + mention-токены) и `NSAttributedString` (что показывает
/// нативный UITextView).
///
/// Rich-text формат — это то, что лежит в Dart `controller.text`:
///  - `<strong>`/`<b>` `</strong>`/`</b>` — bold
///  - `<em>`/`<i>` `</em>`/`</i>` — italic
///  - `<u>` `</u>` — underline
///  - `<s>`/`<del>`/`<strike>` `</s>`/`</del>`/`</strike>` — strikethrough
///  - `<code>` `</code>` — monospace
///  - HTML entities: `&amp; &lt; &gt; &quot; &nbsp; &#39;`
///  - Mention-токены `\u{E000}<base64-json>\u{E001}` — рендерятся как `@label`
///
/// Это плоский plain-text формат — никаких атрибутов, всё в строке. UITextView
/// держит это в `attributedText` с font traits / decorations / custom keys,
/// чтобы пользователь видел и редактировал визуальный chip и форматирование.
///
/// Имя `MentionAttributedString` оставлено historical — внутри парсер
/// работает с полным HTML+mention rich-text'ом.
enum MentionAttributedString {
  static let tokenStart: Character = "\u{E000}"
  static let tokenEnd: Character = "\u{E001}"
  /// NSAttributedString key — храним полный mention-токен (со escape-символами).
  static let tokenKey = NSAttributedString.Key("lighchat.mentionToken")
  /// NSAttributedString key — храним имя animated effect'а
  /// (shake / nod / ripple / bloom / jitter / big / small).
  /// Сериализуется как `<span data-anim="X">…</span>`, рендерится на
  /// receiver-side через [AnimatedTextSpan].
  static let effectKey = NSAttributedString.Key("lighchat.textEffect")
  static let knownEffects: Set<String> = [
    "shake", "nod", "ripple", "bloom", "jitter", "big", "small",
  ]

  // MARK: - Render: rich-text → NSAttributedString

  static func render(
    plain: String, baseFont: UIFont, baseColor: UIColor, accentColor: UIColor
  ) -> NSAttributedString {
    let lexer = _Lexer(input: plain)
    let result = NSMutableAttributedString()
    var traits = _Traits()
    var activeEffect: String?
    while let tok = lexer.next() {
      switch tok {
      case .text(let s):
        var attrs = _attributes(
          for: traits, baseFont: baseFont, baseColor: baseColor)
        if let effect = activeEffect {
          attrs[effectKey] = effect
          _applyEffectVisualStyle(
            &attrs, effect: effect, baseFont: baseFont,
            baseColor: baseColor, accentColor: accentColor)
        }
        result.append(NSAttributedString(string: s, attributes: attrs))
      case .mention(let full, let label):
        let attrs: [NSAttributedString.Key: Any] = [
          .font: UIFont.systemFont(
            ofSize: baseFont.pointSize, weight: .semibold),
          .foregroundColor: accentColor,
          tokenKey: full,
        ]
        result.append(
          NSAttributedString(string: "@\(label)", attributes: attrs))
      case .openTag(let tag):
        traits.apply(tag, opening: true)
      case .closeTag(let tag):
        traits.apply(tag, opening: false)
      case .openEffect(let effect):
        activeEffect = effect
      case .closeEffect:
        activeEffect = nil
      }
    }
    return result
  }

  /// Применяет визуальный стиль animated/size effect-а к атрибутам:
  ///  - `big` — реальный масштаб 1.4× + semibold (Receiver-side тоже даёт
  ///    1.4×, см. `AnimatedTextSpan`),
  ///  - `small` — масштаб 0.72× + лёгкое затухание (parity с receiver),
  ///  - shake/nod/ripple/bloom/jitter — semibold + accent (anim
  ///    проигрывается только на receiver-side).
  ///
  /// Используется при render'е (`<span data-anim="X">…`) и при
  /// `toggleEffect`. Без этой нормализации `big`/`small` визуально
  /// идентичны обычному тексту в композере, и юзеру не видно что
  /// эффект применился.
  static func _applyEffectVisualStyle(
    _ attrs: inout [NSAttributedString.Key: Any],
    effect: String,
    baseFont: UIFont,
    baseColor: UIColor,
    accentColor: UIColor
  ) {
    switch effect {
    case "big":
      attrs[.font] = UIFont.systemFont(
        ofSize: baseFont.pointSize * 1.4, weight: .semibold)
      attrs[.foregroundColor] = accentColor
    case "small":
      attrs[.font] = UIFont.systemFont(
        ofSize: baseFont.pointSize * 0.72, weight: .regular)
      attrs[.foregroundColor] = baseColor.withAlphaComponent(0.78)
    default:
      attrs[.font] = UIFont.systemFont(
        ofSize: baseFont.pointSize, weight: .semibold)
      attrs[.foregroundColor] = accentColor
    }
  }

  private static func _attributes(
    for traits: _Traits, baseFont: UIFont, baseColor: UIColor
  ) -> [NSAttributedString.Key: Any] {
    var font = baseFont
    if traits.code {
      // Monospace переопределяет base font целиком (как принято для code-блоков).
      font = UIFont.monospacedSystemFont(
        ofSize: baseFont.pointSize, weight: .regular)
    }
    if traits.bold || traits.italic {
      var symbolic: UIFontDescriptor.SymbolicTraits = []
      if traits.bold { symbolic.insert(.traitBold) }
      if traits.italic { symbolic.insert(.traitItalic) }
      if let desc = font.fontDescriptor.withSymbolicTraits(symbolic) {
        font = UIFont(descriptor: desc, size: font.pointSize)
      }
    }
    var attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: baseColor,
    ]
    if traits.underline {
      attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }
    if traits.strikethrough {
      attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }
    return attrs
  }

  // MARK: - Serialize: NSAttributedString → rich-text

  /// Обход attributed string по runs, эмитим open/close tags при изменении
  /// font traits + animated effect spans, mention-runs выдаём как
  /// сохранённый токен.
  static func serialize(_ attributed: NSAttributedString) -> String {
    var out = ""
    var prev = _Traits()
    var prevEffect: String?
    let full = NSRange(location: 0, length: attributed.length)

    func emitOpenClose(transition newTraits: _Traits, newEffect: String?) {
      // Эффект-span ВНЕШНЕЕ обрамление: bold/italic внутри. Поэтому
      // при смене эффекта закрываем сначала traits, потом сам эффект.
      let effectChange = newEffect != prevEffect
      if effectChange {
        // Закрываем все активные traits (под эффектом нечего держать).
        emitTraitsClose(_Traits())
        if prevEffect != nil { out += "</span>" }
        if let e = newEffect { out += "<span data-anim=\"\(e)\">" }
        prevEffect = newEffect
        prev = _Traits()
      }
      emitTraitsClose(newTraits)
      emitTraitsOpen(newTraits)
      prev = newTraits
    }

    func emitTraitsClose(_ newTraits: _Traits) {
      if prev.code && !newTraits.code { out += "</code>" }
      if prev.strikethrough && !newTraits.strikethrough { out += "</s>" }
      if prev.underline && !newTraits.underline { out += "</u>" }
      if prev.italic && !newTraits.italic { out += "</em>" }
      if prev.bold && !newTraits.bold { out += "</strong>" }
    }
    func emitTraitsOpen(_ newTraits: _Traits) {
      if !prev.bold && newTraits.bold { out += "<strong>" }
      if !prev.italic && newTraits.italic { out += "<em>" }
      if !prev.underline && newTraits.underline { out += "<u>" }
      if !prev.strikethrough && newTraits.strikethrough { out += "<s>" }
      if !prev.code && newTraits.code { out += "<code>" }
    }

    attributed.enumerateAttributes(in: full, options: []) { attrs, range, _ in
      let runStr = attributed.attributedSubstring(from: range).string
      if let token = attrs[tokenKey] as? String {
        // Mention: закрываем traits И effect span (mention не должен быть
        // внутри `<span data-anim>` или `<strong>` — send-pipeline это не
        // ожидает).
        emitOpenClose(transition: _Traits(), newEffect: nil)
        out += token
        return
      }
      let traits = _Traits.fromAttributes(attrs)
      let effect = attrs[effectKey] as? String
      emitOpenClose(transition: traits, newEffect: effect)
      out += _escapeHtml(runStr)
    }
    // Финальное закрытие.
    emitOpenClose(transition: _Traits(), newEffect: nil)
    return out
  }

  // MARK: - Plain offset ↔ visible offset (для курсора)

  static func plainOffsetToVisible(plain: String, plainOffset: Int) -> Int {
    let ns = plain as NSString
    let clamped = max(0, min(plainOffset, ns.length))
    let lexer = _Lexer(input: ns.substring(with: NSRange(location: 0, length: clamped)))
    var visible = 0
    while let tok = lexer.next() {
      switch tok {
      case .text(let s):
        visible += (s as NSString).length
      case .mention(_, let label):
        visible += ("@\(label)" as NSString).length
      case .openTag, .closeTag, .openEffect, .closeEffect:
        break // теги не занимают visible space
      }
    }
    return visible
  }

  /// Обратная функция: по visible-offset в attributed-string-е (там, где
  /// mention отображается как `@label`, а HTML-теги/`<span data-anim>` —
  /// невидимые) возвращает plain-offset в rich-text'е (где mention — это
  /// длинный escape-токен, а теги — реальные символы).
  ///
  /// Нужно для `textChanged`/`selectionChanged` событий: native UITextView
  /// оперирует visible-offset'ами, а Dart `controller.text` и логика типа
  /// `_recomputeMentionState` работают в plain-offset'ах. Без перекодировки
  /// курсор «прыгает» внутрь токена и mention-picker не триггерится после
  /// первой вставленной @-метки в одном сообщении.
  ///
  /// Курсор внутри mention-chip'а клампится к ближайшей границе токена.
  static func visibleOffsetToPlain(plain: String, visibleOffset: Int) -> Int {
    let ns = plain as NSString
    let target = max(0, visibleOffset)
    let lexer = _Lexer(input: plain)
    var visible = 0
    while true {
      let beforeIdx = lexer.i
      guard let tok = lexer.next() else { break }
      let afterIdx = lexer.i
      let plainStartNS = plain.utf16.distance(
        from: plain.startIndex, to: beforeIdx)
      let plainEndNS = plain.utf16.distance(
        from: plain.startIndex, to: afterIdx)
      switch tok {
      case .text(let s):
        let visLen = (s as NSString).length
        if visible + visLen >= target {
          // Курсор внутри text-токена. Маппим visible → plain учитывая
          // HTML-entities (`&amp;` = 1 visible / 5 plain).
          let needInTok = target - visible
          let inner = _innerVisibleToPlainOffsetNs(
            input: plain,
            rangeStart: beforeIdx,
            rangeEnd: afterIdx,
            target: needInTok)
          return plainStartNS + inner
        }
        visible += visLen
      case .mention(_, let label):
        let visLen = ("@\(label)" as NSString).length
        if visible + visLen >= target {
          // Курсор внутри chip-а — клампим к ближайшей границе токена.
          let inside = target - visible
          return inside * 2 <= visLen ? plainStartNS : plainEndNS
        }
        visible += visLen
      case .openTag, .closeTag, .openEffect, .closeEffect:
        // Теги/effect-span'ы visible не двигают. Если target == visible
        // прямо на стыке — отдаём конец последнего пройденного non-tag
        // фрагмента, что и есть `plainEndNS` (тег только что прошёл).
        break
      }
    }
    return ns.length
  }

  /// Внутренний хелпер: по visible-offset внутри одного text-run'а (от
  /// `rangeStart` до `rangeEnd` в `input`) — возвращает plain-NS-offset
  /// (utf16) внутри этого run'а. Учитывает HTML-entities, которые
  /// «сжимаются» в 1 visible char.
  private static func _innerVisibleToPlainOffsetNs(
    input: String,
    rangeStart: String.Index,
    rangeEnd: String.Index,
    target: Int
  ) -> Int {
    var visible = 0
    var i = rangeStart
    var nsOff = 0
    while i < rangeEnd {
      if visible == target { return nsOff }
      let c = input[i]
      if c == "&" {
        // Попытаться раскрыть entity до `;`.
        if let semi = input[i..<rangeEnd].firstIndex(of: ";") {
          let entity = String(input[input.index(after: i)..<semi]).lowercased()
          let known: Set<String> = ["amp", "lt", "gt", "quot", "nbsp", "#39"]
          if known.contains(entity) {
            visible += 1
            let chunk = String(input[i...semi])
            nsOff += (chunk as NSString).length
            i = input.index(after: semi)
            continue
          }
        }
      }
      visible += 1
      nsOff += (String(c) as NSString).length
      i = input.index(after: i)
    }
    return nsOff
  }

  // MARK: - Token decoder (для mention-токенов)

  static func decodeToken(b64 inner: String) -> (uid: String, label: String)? {
    guard !inner.isEmpty else { return nil }
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

// MARK: - Internal lexer / traits

private enum _Tok {
  case text(String)
  case mention(full: String, label: String)
  case openTag(String)
  case closeTag(String)
  case openEffect(String) // span data-anim="X" open
  case closeEffect // </span> after a known data-anim open
}

private final class _Lexer {
  init(input: String) { self.input = input; self.i = input.startIndex }
  let input: String
  var i: String.Index
  /// Stack глубины открытых `<span>` с известным `data-anim` — нужен
  /// чтобы парный `</span>` правильно интерпретировать как
  /// `.closeEffect` (если открывали с эффектом) или как закрытие
  /// обычного span'а (игнорируем).
  var spanEffectStack: [Bool] = []

  func next() -> _Tok? {
    guard i < input.endIndex else { return nil }
    let c = input[i]
    if c == MentionAttributedString.tokenStart {
      return scanMention()
    }
    if c == "<" {
      return scanTag()
    }
    return scanText()
  }

  private func scanMention() -> _Tok? {
    guard let endIdx = input[i...].firstIndex(
      of: MentionAttributedString.tokenEnd)
    else {
      // Незакрытый токен → отдаём как текст.
      let s = String(input[i...])
      i = input.endIndex
      return .text(s)
    }
    let full = String(input[i...endIdx])
    let inner = String(input[input.index(after: i)..<endIdx])
    i = input.index(after: endIdx)
    if let decoded = MentionAttributedString.decodeToken(b64: inner) {
      return .mention(full: full, label: decoded.label)
    }
    // Битый токен → возвращаем как текст.
    return .text(full)
  }

  private func scanTag() -> _Tok? {
    // Поиск закрывающего '>'.
    guard let gt = input[i...].firstIndex(of: ">") else {
      // Битый тег → отдаём как текст до конца.
      let s = String(input[i...])
      i = input.endIndex
      return .text(s)
    }
    let raw = String(input[input.index(after: i)..<gt])
    i = input.index(after: gt)
    let isClose = raw.hasPrefix("/")
    let body = isClose ? String(raw.dropFirst()) : raw
    var name = body
    if let sp = name.firstIndex(of: " ") {
      name = String(name[..<sp])
    }
    name = name.lowercased()
    let known: Set<String> = ["strong", "b", "em", "i", "u", "s", "del", "strike", "code"]
    if known.contains(name) {
      return isClose ? .closeTag(name) : .openTag(name)
    }
    // `<span data-anim="X">…</span>` → animated effect run.
    if name == "span" {
      if isClose {
        // Закрываем span. Если последний открытый был effect — emit closeEffect,
        // иначе игнорируем (обычный span).
        if let last = spanEffectStack.popLast(), last == true {
          return .closeEffect
        }
        return nil // skip silently
      }
      // Open span — парсим атрибуты, ищем data-anim="X".
      if let effect = _parseDataAnim(body),
        MentionAttributedString.knownEffects.contains(effect)
      {
        spanEffectStack.append(true)
        return .openEffect(effect)
      }
      spanEffectStack.append(false)
      return nil // skip silently
    }
    // Неизвестный тег (например `<span data-chat-mention=...>`) — на native
    // путях такого быть не должно, но если влетел — рендерим как текст.
    return .text(isClose ? "</\(name)>" : "<\(raw)>")
  }

  /// Возвращает значение `data-anim` атрибута из строки `span data-anim="X" …`.
  /// Простой regex-free парсер: ищет `data-anim=`, потом значение в
  /// кавычках или без.
  private func _parseDataAnim(_ body: String) -> String? {
    let lower = body.lowercased()
    guard let range = lower.range(of: "data-anim=") else { return nil }
    var rest = lower[range.upperBound...]
    // Опционально кавычки `"` или `'`.
    var quote: Character?
    if let first = rest.first, first == "\"" || first == "'" {
      quote = first
      rest = rest.dropFirst()
    }
    var value = ""
    for c in rest {
      if let q = quote {
        if c == q { break }
      } else if c == " " || c == ">" {
        break
      }
      value.append(c)
    }
    return value.isEmpty ? nil : value
  }

  private func scanText() -> _Tok? {
    var s = ""
    while i < input.endIndex {
      let c = input[i]
      if c == "<" || c == MentionAttributedString.tokenStart { break }
      // HTML entities — раскрываем при rendering, при serialize escape'им обратно.
      if c == "&" {
        if let semi = input[i...].firstIndex(of: ";") {
          let entity = String(input[input.index(after: i)..<semi])
          switch entity.lowercased() {
          case "amp": s.append("&"); i = input.index(after: semi); continue
          case "lt": s.append("<"); i = input.index(after: semi); continue
          case "gt": s.append(">"); i = input.index(after: semi); continue
          case "quot": s.append("\""); i = input.index(after: semi); continue
          case "nbsp": s.append("\u{00A0}"); i = input.index(after: semi); continue
          case "#39": s.append("'"); i = input.index(after: semi); continue
          default: break
          }
        }
      }
      s.append(c)
      i = input.index(after: i)
    }
    return s.isEmpty ? nil : .text(s)
  }
}

private struct _Traits: Equatable {
  var bold: Bool = false
  var italic: Bool = false
  var underline: Bool = false
  var strikethrough: Bool = false
  var code: Bool = false

  mutating func apply(_ tag: String, opening: Bool) {
    switch tag {
    case "strong", "b": bold = opening
    case "em", "i": italic = opening
    case "u": underline = opening
    case "s", "del", "strike": strikethrough = opening
    case "code": code = opening
    default: break
    }
  }

  static func fromAttributes(
    _ attrs: [NSAttributedString.Key: Any]
  ) -> _Traits {
    var t = _Traits()
    if let font = attrs[.font] as? UIFont {
      t.bold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
      t.italic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
      // Monospace detect — fontName содержит "Mono".
      let lower = font.fontName.lowercased()
      if lower.contains("mono") {
        t.code = true
      }
    }
    if let u = attrs[.underlineStyle] as? Int, u != 0 {
      t.underline = true
    }
    if let s = attrs[.strikethroughStyle] as? Int, s != 0 {
      t.strikethrough = true
    }
    return t
  }
}

private func _escapeHtml(_ s: String) -> String {
  var out = ""
  for c in s {
    switch c {
    case "&": out += "&amp;"
    case "<": out += "&lt;"
    case ">": out += "&gt;"
    case "\"": out += "&quot;"
    case "'": out += "&#39;"
    case "\u{00A0}": out += "&nbsp;"
    default: out.append(c)
    }
  }
  return out
}
