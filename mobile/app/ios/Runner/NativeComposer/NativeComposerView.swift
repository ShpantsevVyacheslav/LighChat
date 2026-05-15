import Flutter
import Foundation
import UIKit

/// Subclass `UITextView` с перехватом `paste(_:)` (Phase 2) и
/// `deleteBackward()` (Phase 3 — атомарное удаление mention-чипа).
final class ComposerTextView: UITextView {
  /// Вызывается, когда `paste` детектит файловое содержимое (не только
  /// текст). Возвращает `true` чтобы перехватить и заблокировать
  /// дефолтную вставку, `false` — пускаем `super.paste`.
  var onPasteRequest: (() -> Bool)?

  override func deleteBackward() {
    // Атомарное удаление mention-чипа: если курсор стоит сразу за
    // mention-run'ом, backspace должен удалить ВЕСЬ runrange (как чип),
    // а не один символ из «@Имя».
    let cursor = selectedRange.location
    if selectedRange.length == 0, cursor > 0 {
      let probe = cursor - 1
      var effective = NSRange(location: NSNotFound, length: 0)
      let attr = attributedText.attribute(
        MentionAttributedString.tokenKey, at: probe,
        longestEffectiveRange: &effective,
        in: NSRange(location: 0, length: attributedText.length))
      if attr != nil, effective.location != NSNotFound {
        let mut = NSMutableAttributedString(attributedString: attributedText)
        mut.deleteCharacters(in: effective)
        attributedText = mut
        selectedRange = NSRange(location: effective.location, length: 0)
        delegate?.textViewDidChange?(self)
        return
      }
    }
    super.deleteBackward()
  }

  override func paste(_ sender: Any?) {
    let pb = UIPasteboard.general
    let hasNonText = pb.hasImages || pb.hasURLs ||
      pb.types.contains(where: { type in
        // Любой типизированный pasteboard кроме обычного текста:
        // file-url, image/*, video/*, application/*, public.movie и т.п.
        type == "public.image" || type == "public.movie" ||
          type == "public.url" || type == "public.file-url" ||
          type.hasPrefix("public.image.") ||
          type.contains("png") || type.contains("jpeg") ||
          type.contains("heic") || type.contains("webp")
      })
    if hasNonText, onPasteRequest?() == true {
      // Dart взял control. НЕ зовём super → курсор не дёргается, и
      // текст из pasteboard'а не «протекает» как fallback.
      return
    }
    super.paste(sender)
  }
}

/// Один instance нативного composer-инпута. Внутри — `ComposerTextView`
/// (subclass UITextView), поэтому:
///  - системное меню Cut/Copy/Paste/Replace/AutoFill срабатывает «из коробки»,
///  - Writing Tools (iOS 26+ Apple Intelligence) появляются в long-press меню,
///  - кнопка диктовки в QuickType bar, smart selection — всё бесплатно,
///  - paste файлов из буфера (Phase 2) перехватывается и идёт через Dart
///    `onClipboardToolbarPaste`.
///
/// Двусторонний sync с Dart через `lighchat/native_composer_<viewId>`:
///  - Dart→Swift: `setText(text)`, `focus()`, `unfocus()`, `setStyle(args)`,
///    `setHint(text)`.
///  - Swift→Dart: `textChanged(text)`, `selectionChanged(start,end)`,
///    `focusChanged(focused)`, `contentHeightChanged(height)`,
///    `pasteRequested()` (когда юзер тапнул Paste с файлом в буфере).
final class NativeComposerView: NSObject, FlutterPlatformView, UITextViewDelegate {
  private let container: UIView
  private let textView: ComposerTextView
  private let hintLabel: UILabel
  private let channel: FlutterMethodChannel
  /// «Защита от эха»: когда Dart прислал setText, мы не должны отправлять
  /// textChanged обратно в Dart (иначе бесконечный цикл).
  private var isApplyingRemoteText = false
  /// Запомненный contentSize чтобы не спамить Dart одинаковыми значениями.
  private var lastReportedHeight: CGFloat = 0
  /// Стили mention-чипа — нужны для render-функции, синхронизируются с
  /// `applyArgs` (изменения цвета акцента / шрифта).
  private var baseFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
  private var baseColor: UIColor = .label
  private var accentColor: UIColor = UIColor.systemBlue

  init(
    frame: CGRect, viewId: Int64, args: [String: Any],
    messenger: FlutterBinaryMessenger
  ) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear

    textView = ComposerTextView(frame: .zero)
    textView.backgroundColor = .clear
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
    textView.isScrollEnabled = false
    textView.autocorrectionType = .default
    textView.smartDashesType = .default
    textView.smartQuotesType = .default
    textView.smartInsertDeleteType = .default
    textView.autocapitalizationType = .sentences
    textView.spellCheckingType = .default
    textView.keyboardType = .default
    textView.returnKeyType = .default
    // Phase 4: системное меню форматирования — Bold/Italic/Underline/
    // Strikethrough появляются в long-press menu при выделении текста.
    // Зачем: не нужен кастомный Flutter formatting toolbar, B/I/U
    // прямо там же где Cut/Copy/Paste — стандартный iOS UX.
    textView.allowsEditingTextAttributes = true
    // iOS 18+: Apple Intelligence Writing Tools (Rewrite/Proofread/
    // Summarize) в том же long-press меню. `.complete` запрашивает
    // полный набор инструментов; на старых iOS свойство просто
    // игнорируется.
    if #available(iOS 18.0, *) {
      textView.writingToolsBehavior = .complete
    }

    hintLabel = UILabel(frame: .zero)
    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    hintLabel.numberOfLines = 1
    hintLabel.isUserInteractionEnabled = false
    hintLabel.adjustsFontSizeToFitWidth = false

    channel = FlutterMethodChannel(
      name: "lighchat/native_composer_\(viewId)",
      binaryMessenger: messenger)

    super.init()

    textView.delegate = self
    container.addSubview(textView)
    container.addSubview(hintLabel)
    NSLayoutConstraint.activate([
      textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      textView.topAnchor.constraint(equalTo: container.topAnchor),
      textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      hintLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
      hintLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
      hintLabel.topAnchor.constraint(equalTo: textView.topAnchor),
    ])

    applyArgs(args)

    // Перехват paste: если в буфере есть файл/изображение, спрашиваем
    // Dart. Возвращаем true (перехватить) если Dart-side подключён —
    // тогда дефолтное поведение `super.paste` не сработает и UITextView
    // не вставит мусорный fallback-текст.
    textView.onPasteRequest = { [weak self] in
      guard let self = self else { return false }
      self.channel.invokeMethod("pasteRequested", arguments: nil)
      // Всегда true: Dart-side в любом случае попытается обработать;
      // если не получится — он сам решит что показать пользователю.
      return true
    }

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  func view() -> UIView { container }

  // MARK: - Style / config

  private func applyArgs(_ args: [String: Any]) {
    let fontSize = (args["fontSize"] as? NSNumber)?.doubleValue ?? 16.0
    let weight = (args["fontWeight"] as? NSNumber)?.intValue ?? 500
    let uiWeight: UIFont.Weight = weight >= 700 ? .bold
      : weight >= 600 ? .semibold
      : weight >= 500 ? .medium
      : .regular
    textView.font = .systemFont(ofSize: fontSize, weight: uiWeight)
    baseFont = textView.font ?? baseFont
    hintLabel.font = textView.font

    if let fgHex = args["textColorHex"] as? String,
      let fg = UIColor.fromHex(fgHex)
    {
      textView.textColor = fg
      baseColor = fg
    } else {
      textView.textColor = .label
      baseColor = .label
    }
    if let hintHex = args["hintColorHex"] as? String,
      let hint = UIColor.fromHex(hintHex)
    {
      hintLabel.textColor = hint
    } else {
      hintLabel.textColor = UIColor.placeholderText
    }
    if let cursorHex = args["cursorColorHex"] as? String,
      let cursor = UIColor.fromHex(cursorHex)
    {
      textView.tintColor = cursor
      // Используем cursor-color как accent для mention-чипа: единый
      // стиль (в чате primary == cursor == mention accent).
      accentColor = cursor
    }

    hintLabel.text = (args["hint"] as? String) ?? ""

    if let initial = args["initialText"] as? String, !initial.isEmpty {
      isApplyingRemoteText = true
      applyPlainText(initial)
      isApplyingRemoteText = false
    } else {
      // Style мог измениться — переотрисуем существующий attributedText
      // в новых цветах/шрифте (например смена темы).
      let current = MentionAttributedString.serialize(textView.attributedText)
      if !current.isEmpty {
        isApplyingRemoteText = true
        applyPlainText(current)
        isApplyingRemoteText = false
      }
    }
    updateHintVisibility()
    notifyContentHeightIfChanged()
  }

  /// Заменяет `attributedText` целиком на render плейн-строки с
  /// mention-токенами. Caller отвечает за `isApplyingRemoteText` flag.
  private func applyPlainText(_ plain: String) {
    textView.attributedText = MentionAttributedString.render(
      plain: plain,
      baseFont: baseFont,
      baseColor: baseColor,
      accentColor: accentColor)
  }

  /// Возвращает текущий плейн-текст с mention-токенами (для отправки в
  /// Dart). Identical форматом тому, что `MentionTokenCodec.buildToken`
  /// генерит в pure-Flutter путях.
  private func currentPlainText() -> String {
    MentionAttributedString.serialize(textView.attributedText)
  }

  // MARK: - Method handler

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setText":
      let map = call.arguments as? [String: Any] ?? [:]
      let text = (map["text"] as? String) ?? ""
      // Опциональный курсор в plain-text-offset'ах (так живёт Dart
      // `controller.selection.baseOffset`). Если задан — конвертируем в
      // visible offset attributed-string'а через
      // `plainOffsetToVisible`, иначе сохраняем прежнюю позицию.
      let plainSel = (map["selectionStart"] as? NSNumber)?.intValue
      if currentPlainText() != text {
        let prevRange = textView.selectedRange
        isApplyingRemoteText = true
        applyPlainText(text)
        let cap = textView.attributedText.length
        let target: Int
        if let p = plainSel {
          target = min(
            MentionAttributedString.plainOffsetToVisible(
              plain: text, plainOffset: p), cap)
        } else {
          target = min(prevRange.location, cap)
        }
        textView.selectedRange = NSRange(location: target, length: 0)
        isApplyingRemoteText = false
        updateHintVisibility()
        notifyContentHeightIfChanged()
      } else if let p = plainSel {
        // Текст не изменился, но Dart передал новый cursor → применим.
        let cap = textView.attributedText.length
        let target = min(
          MentionAttributedString.plainOffsetToVisible(
            plain: text, plainOffset: p), cap)
        textView.selectedRange = NSRange(location: target, length: 0)
      }
      result(nil)
    case "focus":
      if !textView.isFirstResponder {
        _ = textView.becomeFirstResponder()
      }
      result(nil)
    case "unfocus":
      if textView.isFirstResponder {
        _ = textView.resignFirstResponder()
      }
      result(nil)
    case "setHint":
      let map = call.arguments as? [String: Any] ?? [:]
      hintLabel.text = (map["text"] as? String) ?? ""
      result(nil)
    case "setStyle":
      applyArgs(call.arguments as? [String: Any] ?? [:])
      result(nil)
    case "toggleFormat":
      let map = call.arguments as? [String: Any] ?? [:]
      let tag = (map["tag"] as? String ?? "").lowercased()
      toggleFormat(tag: tag)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Phase 4-6 Format sheet: переключает inline-формат (B/I/U/S/code) или
  /// animated effect (shake/nod/ripple/bloom/jitter/big/small) на
  /// выделенном фрагменте — или на `typingAttributes` если нет selection.
  ///
  /// Внутри идёт через тот же font-traits/decoration механизм, что и
  /// системное меню iOS (`allowsEditingTextAttributes=true`) — после
  /// текстового изменения `textViewDidChange` сериализует attributed
  /// обратно в HTML и шлёт в Dart, всё совместимо.
  private func toggleFormat(tag: String) {
    // Animated text effects (Phase 6) идут отдельной веткой: они
    // мутируют только `effectKey`, не font traits.
    if MentionAttributedString.knownEffects.contains(tag) {
      toggleEffect(tag: tag)
      return
    }
    let selRange = textView.selectedRange
    let baseFont = self.baseFont
    let baseColor = self.baseColor

    func mutateAttrs(
      _ attrs: inout [NSAttributedString.Key: Any], shouldActivate: Bool
    ) {
      // Сохраняем текущие traits, переключаем нужный.
      var font = (attrs[.font] as? UIFont) ?? baseFont
      var symbolic = font.fontDescriptor.symbolicTraits
      let isMono = font.fontName.lowercased().contains("mono")
      var underline = (attrs[.underlineStyle] as? Int ?? 0) != 0
      var strike = (attrs[.strikethroughStyle] as? Int ?? 0) != 0
      var monoOn = isMono
      switch tag {
      case "bold":
        if shouldActivate {
          symbolic.insert(.traitBold)
        } else {
          symbolic.remove(.traitBold)
        }
      case "italic":
        if shouldActivate {
          symbolic.insert(.traitItalic)
        } else {
          symbolic.remove(.traitItalic)
        }
      case "underline":
        underline = shouldActivate
      case "strikethrough", "strike":
        strike = shouldActivate
      case "code":
        monoOn = shouldActivate
      default:
        return
      }
      // Пересобираем font: code → monospace, иначе system+traits.
      if monoOn {
        font = UIFont.monospacedSystemFont(
          ofSize: baseFont.pointSize, weight: .regular)
      } else {
        var newFont = UIFont.systemFont(
          ofSize: baseFont.pointSize, weight: .regular)
        if let d = newFont.fontDescriptor.withSymbolicTraits(symbolic) {
          newFont = UIFont(descriptor: d, size: baseFont.pointSize)
        }
        font = newFont
      }
      attrs[.font] = font
      attrs[.foregroundColor] = attrs[.foregroundColor] ?? baseColor
      if underline {
        attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
      } else {
        attrs.removeValue(forKey: .underlineStyle)
      }
      if strike {
        attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
      } else {
        attrs.removeValue(forKey: .strikethroughStyle)
      }
    }

    // Определяем — выключать или включать? Берём traits в начале selection
    // (или у курсора), если уже активен → выключаем, иначе включаем.
    let probeLoc = selRange.length > 0 ? selRange.location : max(0, selRange.location - 1)
    let probeRange = NSRange(location: probeLoc, length: 0)
    let probeAttrs: [NSAttributedString.Key: Any] =
      (probeLoc < textView.attributedText.length && probeLoc >= 0)
      ? textView.attributedText.attributes(at: probeLoc, effectiveRange: nil)
      : textView.typingAttributes
    let isActive = _isTagActive(tag: tag, attrs: probeAttrs)
    let shouldActivate = !isActive

    if selRange.length > 0 {
      // Применяем к выделенному фрагменту.
      let mut = NSMutableAttributedString(attributedString: textView.attributedText)
      mut.enumerateAttributes(in: selRange, options: []) { attrs, range, _ in
        var copy = attrs
        mutateAttrs(&copy, shouldActivate: shouldActivate)
        mut.setAttributes(copy, range: range)
      }
      isApplyingRemoteText = true
      textView.attributedText = mut
      textView.selectedRange = selRange
      isApplyingRemoteText = false
      // Notify Dart — текст по семантике HTML изменился (хотя length тот же).
      do {
        let plain = currentPlainText()
        let sel = plainSelection(plain)
        channel.invokeMethod(
          "textChanged",
          arguments: [
            "text": plain,
            "selectionStart": sel.start,
            "selectionEnd": sel.end,
          ])
      }
    } else {
      // Курсор без selection — модифицируем typingAttributes на следующий
      // ввод. UITextView сам применит их на новые символы.
      var ta = textView.typingAttributes
      mutateAttrs(&ta, shouldActivate: shouldActivate)
      textView.typingAttributes = ta
    }
  }

  /// Phase 6: animated effects (shake/nod/ripple/bloom/jitter/big/small).
  /// Кладёт/убирает custom-атрибут `effectKey` на выделенном фрагменте
  /// (или typingAttributes). Сериализация → `<span data-anim="X">…</span>`,
  /// рендеринг на receiver-side через `AnimatedTextSpan` (Flutter).
  ///
  /// Toggle-семантика: если probe-runs уже имеют этот же эффект →
  /// выключаем (NSRange нулится). Если другой эффект → заменяем. Если
  /// нет эффекта → ставим.
  private func toggleEffect(tag: String) {
    let selRange = textView.selectedRange
    let probeLoc = selRange.length > 0 ? selRange.location : max(0, selRange.location - 1)
    let probeAttrs: [NSAttributedString.Key: Any] =
      (probeLoc < textView.attributedText.length && probeLoc >= 0)
      ? textView.attributedText.attributes(at: probeLoc, effectiveRange: nil)
      : textView.typingAttributes
    let activeEffect = probeAttrs[MentionAttributedString.effectKey] as? String
    let nextEffect: String? = (activeEffect == tag) ? nil : tag

    func patchAttrs(_ attrs: inout [NSAttributedString.Key: Any]) {
      if let e = nextEffect {
        attrs[MentionAttributedString.effectKey] = e
        // Визуально подкрашиваем — semibold + accent, чтобы юзер видел
        // что блок особый.
        attrs[.font] = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .semibold)
        attrs[.foregroundColor] = accentColor
      } else {
        attrs.removeValue(forKey: MentionAttributedString.effectKey)
        attrs[.font] = baseFont
        attrs[.foregroundColor] = baseColor
      }
    }

    if selRange.length > 0 {
      let mut = NSMutableAttributedString(attributedString: textView.attributedText)
      mut.enumerateAttributes(in: selRange, options: []) { attrs, range, _ in
        var copy = attrs
        patchAttrs(&copy)
        mut.setAttributes(copy, range: range)
      }
      isApplyingRemoteText = true
      textView.attributedText = mut
      textView.selectedRange = selRange
      isApplyingRemoteText = false
      do {
        let plain = currentPlainText()
        let sel = plainSelection(plain)
        channel.invokeMethod(
          "textChanged",
          arguments: [
            "text": plain,
            "selectionStart": sel.start,
            "selectionEnd": sel.end,
          ])
      }
    } else {
      var ta = textView.typingAttributes
      patchAttrs(&ta)
      textView.typingAttributes = ta
    }
  }

  private func _isTagActive(
    tag: String, attrs: [NSAttributedString.Key: Any]
  ) -> Bool {
    let font = (attrs[.font] as? UIFont) ?? baseFont
    switch tag {
    case "bold":
      return font.fontDescriptor.symbolicTraits.contains(.traitBold)
    case "italic":
      return font.fontDescriptor.symbolicTraits.contains(.traitItalic)
    case "underline":
      return (attrs[.underlineStyle] as? Int ?? 0) != 0
    case "strikethrough", "strike":
      return (attrs[.strikethroughStyle] as? Int ?? 0) != 0
    case "code":
      return font.fontName.lowercased().contains("mono")
    default:
      return false
    }
  }

  // MARK: - UITextViewDelegate

  /// Конвертирует visible-offset UITextView'а в plain-offset rich-text'а
  /// для отправки в Dart. Все события `textChanged`/`selectionChanged`/
  /// `toggleFormat`/`toggleEffect` обязаны конвертировать selection через
  /// эту функцию — иначе после первой mention'и (или внутри HTML-формата)
  /// курсор «попадает в середину токена» в Dart-`controller.text`.
  private func plainSelection(_ plain: String) -> (start: Int, end: Int) {
    let sel = textView.selectedRange
    let s = MentionAttributedString.visibleOffsetToPlain(
      plain: plain, visibleOffset: sel.location)
    let e =
      sel.length == 0
      ? s
      : MentionAttributedString.visibleOffsetToPlain(
        plain: plain, visibleOffset: sel.location + sel.length)
    return (s, e)
  }

  func textViewDidChange(_ textView: UITextView) {
    updateHintVisibility()
    notifyContentHeightIfChanged()
    if isApplyingRemoteText { return }
    // Phase 8: системная emoji-клавиатура (вкладка Stickers/Memoji/Genmoji)
    // вставляет картинку в UITextView как `NSTextAttachment`. Наш
    // `serialize()` не знает про attachment-runs — нужно их вытащить,
    // сохранить в tmp PNG, удалить из attributedText и отдать Dart как
    // обычные image-attachment'ы (через pendingAttachments pipeline).
    let extracted = extractAndRemoveInlineImageAttachments()
    if !extracted.isEmpty {
      channel.invokeMethod(
        "attachmentInserted", arguments: ["paths": extracted])
    }
    let plain = currentPlainText()
    let sel = plainSelection(plain)
    channel.invokeMethod(
      "textChanged",
      arguments: [
        "text": plain,
        "selectionStart": sel.start,
        "selectionEnd": sel.end,
      ])
  }

  /// Ищет в `attributedText` все `NSTextAttachment`-run'ы с реальной
  /// картинкой (Stickers/Memoji/Genmoji со стандартной iOS-клавиатуры).
  /// Каждый сохраняет в tmp PNG, удаляет run из attributedText, возвращает
  /// абсолютные пути сохранённых файлов.
  ///
  /// Если у attachment'а нет `image` напрямую, пробуем resolve через
  /// `image(forBounds:textContainer:characterIndex:)` (тут iOS возвращает
  /// растрированный bitmap для memoji/genmoji), а в крайнем случае —
  /// инициализируем UIImage из `attachment.contents` (raw NSData).
  private func extractAndRemoveInlineImageAttachments() -> [String] {
    let attr = textView.attributedText
    guard let attr = attr, attr.length > 0 else { return [] }
    let full = NSRange(location: 0, length: attr.length)
    var hits: [(range: NSRange, image: UIImage)] = []
    attr.enumerateAttribute(.attachment, in: full, options: []) {
      val, range, _ in
      guard let attach = val as? NSTextAttachment else { return }
      var img: UIImage? = attach.image
      if img == nil {
        img = attach.image(
          forBounds: attach.bounds, textContainer: nil,
          characterIndex: range.location)
      }
      if img == nil, let data = attach.contents {
        img = UIImage(data: data)
      }
      if let i = img { hits.append((range, i)) }
    }
    if hits.isEmpty { return [] }

    var paths: [String] = []
    for (_, image) in hits {
      // PNG сохраняет прозрачность memoji/sticker'а — JPEG бы её схлопнул
      // в чёрный.
      guard let data = image.pngData() else { continue }
      let name = "composer_sticker_\(UUID().uuidString).png"
      let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(name)
      do {
        try data.write(to: url, options: .atomic)
        paths.append(url.path)
      } catch {
        // tmp недоступен — просто пропускаем стикер. Не мешаем юзеру
        // дальше печатать.
      }
    }

    // Удаляем attachment-run'ы из attributedText (в обратном порядке,
    // чтобы NSRange'ы не сдвигались).
    let mut = NSMutableAttributedString(attributedString: attr)
    for (range, _) in hits.reversed() {
      mut.deleteCharacters(in: range)
    }
    let prevSel = textView.selectedRange
    isApplyingRemoteText = true
    textView.attributedText = mut
    // Курсор клампим в новые границы (стикеры обычно вставляются в
    // позицию курсора, после удаления — курсор сдвинется на тот же offset
    // в attachment.range.location).
    let cap = mut.length
    let newLoc = min(prevSel.location, cap)
    textView.selectedRange = NSRange(location: newLoc, length: 0)
    isApplyingRemoteText = false
    updateHintVisibility()
    return paths
  }

  func textViewDidChangeSelection(_ textView: UITextView) {
    if isApplyingRemoteText { return }
    let plain = currentPlainText()
    let sel = plainSelection(plain)
    channel.invokeMethod(
      "selectionChanged",
      arguments: [
        "start": sel.start,
        "end": sel.end,
      ])
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    channel.invokeMethod("focusChanged", arguments: ["focused": true])
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    channel.invokeMethod("focusChanged", arguments: ["focused": false])
  }

  // MARK: - Hint label

  private func updateHintVisibility() {
    let empty = textView.attributedText.length == 0
    hintLabel.isHidden = !empty
  }

  // MARK: - Content height (для autoresize, минимум 1 строка → maxLines×lineH)

  private func notifyContentHeightIfChanged() {
    let target = max(textView.contentSize.height, lineHeight())
    if abs(target - lastReportedHeight) < 0.5 { return }
    lastReportedHeight = target
    channel.invokeMethod(
      "contentHeightChanged", arguments: ["height": target])
  }

  private func lineHeight() -> CGFloat {
    return textView.font?.lineHeight ?? 20
  }
}

// Note: `UIColor.fromHex(...)` определён в `NavBarOverlayHost.swift` — там
// же `#AARRGGBB`/`#RRGGBB` парсер. Шарим один extension по target'у Runner.
