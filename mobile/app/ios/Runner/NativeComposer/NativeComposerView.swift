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

  /// iOS 16+ override callout-меню при выделении текста. Скрываем
  /// системный Format submenu (Apple Notes-style большой popover c
  /// B/I/U/S + color wheel + Default Font + alignment), потому что Apple
  /// показывает его на месте клавиатуры — а не поверх композера, как
  /// просит UX. Юзер использует нашу кнопку «Aa» которая вызывает наш
  /// собственный popover (overlay над композером, не закрывает поле
  /// ввода).
  ///
  /// Cut/Copy/Paste/Lookup/Replace/Translate/Writing Tools оставляем —
  /// это обычное системное контекстное меню, ничего лишнего не
  /// перекрывает.
  ///
  /// Хоткеи Cmd+B/I/U продолжат работать (это `allowsEditingTextAttributes`
  /// + UIKeyCommand, не зависит от callout).
  override func editMenu(
    for textRange: UITextRange,
    suggestedActions: [UIMenuElement]
  ) -> UIMenu? {
    let filtered = suggestedActions.compactMap { element -> UIMenuElement? in
      if let menu = element as? UIMenu {
        let id = menu.identifier.rawValue.lowercased()
        // `com.apple.menu.format` — основной Format submenu.
        // `com.apple.menu.text-style` / `text-styles` — варианты под iOS 18+.
        if id.contains("format") || id.contains("text-style") {
          return nil
        }
      }
      return element
    }
    return UIMenu(children: filtered)
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
final class NativeComposerView: NSObject, FlutterPlatformView, UITextViewDelegate,
  NSTextStorageDelegate
{
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
    // Format accessory: «Aa»-кнопка в правом верхнем углу клавиатуры
    // (UIKit `inputAccessoryView`). Тап → MethodChannel
    // `formatRequested` → Dart показывает Format popover поверх
    // композера. UX как в Apple Messages: накладка над клавиатурой.
    // Сам toolbar собирается ниже после init'а channel'а.
    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    hintLabel.numberOfLines = 1
    hintLabel.isUserInteractionEnabled = false
    hintLabel.adjustsFontSizeToFitWidth = false

    channel = FlutterMethodChannel(
      name: "lighchat/native_composer_\(viewId)",
      binaryMessenger: messenger)

    super.init()

    textView.delegate = self
    // Sticker диагностика (Phase 8): textViewDidChange может не сработать
    // когда iOS Sticker keyboard вставляет UISticker через UITextInteraction
    // / private API. textStorage.delegate ловит ВСЁ — это backup-канал.
    textView.textStorage.delegate = self
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
      NSLog(
        "[panel-toggle] swift method `focus` called, "
          + "isFirstResponder=\(textView.isFirstResponder)")
      // Async на main: iOS не поднимает клавиатуру если
      // becomeFirstResponder вызвается во время Flutter rebuild
      // animation pass'а. Перенос на следующий run-loop tick
      // даёт UIKit'у завершить layout и тогда keyboard-show
      // отрабатывает штатно (Bug 5/6).
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if !self.textView.isFirstResponder {
          NSLog("[panel-toggle] swift becomeFirstResponder (async)")
          _ = self.textView.becomeFirstResponder()
        }
      }
      result(nil)
    case "unfocus":
      NSLog(
        "[panel-toggle] swift method `unfocus` called, "
          + "isFirstResponder=\(textView.isFirstResponder)")
      // Async на main, как и `focus` — `resignFirstResponder` во время
      // Flutter rebuild-tick'а иногда тихо игнорируется (UIKit считает
      // что responder-цепочка ещё не стабильна), и клавиатура остаётся
      // висеть. Перенос на следующий run-loop tick гарантирует, что
      // UITextView действительно отпустит first-responder.
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if self.textView.isFirstResponder {
          NSLog("[panel-toggle] swift resignFirstResponder (async)")
          _ = self.textView.resignFirstResponder()
        }
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
    case "setReturnKeyType":
      // Bug A: в режиме location-share Dart переключает return-key на
      // `search` (лупа), чтобы клавиатура подсказывала «ищу адрес», а
      // не «новая строка». Поддерживаем `default`, `search`, `done`,
      // `go`, `send`. Если клавиатура сейчас видима — перерисуем её
      // через reloadInputViews(), иначе iOS не подтянет новый тип
      // ключа до следующего becomeFirstResponder.
      let map = call.arguments as? [String: Any] ?? [:]
      let typeName = (map["type"] as? String ?? "default").lowercased()
      switch typeName {
      case "search": textView.returnKeyType = .search
      case "done": textView.returnKeyType = .done
      case "go": textView.returnKeyType = .go
      case "send": textView.returnKeyType = .send
      default: textView.returnKeyType = .default
      }
      if textView.isFirstResponder {
        textView.reloadInputViews()
      }
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
    // Format sheet (modal над клавиатурой) может временно отнять
    // firstResponder у UITextView — тогда `typingAttributes`, которые мы
    // выставим ниже, не применятся к следующему вводу. Гарантируем что
    // UITextView активен перед мутацией.
    if !textView.isFirstResponder {
      _ = textView.becomeFirstResponder()
    }
    // Animated text effects (Phase 6) идут отдельной веткой: они
    // мутируют только `effectKey`, не font traits.
    if MentionAttributedString.knownEffects.contains(tag) {
      toggleEffect(tag: tag)
      return
    }
    // Phase 13: spoiler / quote / link — отдельные кастомные attribute
    // ключи. Передаются через тот же `toggleFormat` channel-метод; для
    // link Dart-сторона дополнительно прокидывает href в payload.
    if tag == "spoiler" {
      toggleSpoiler()
      return
    }
    if tag == "quote" {
      toggleQuote()
      return
    }
    if tag == "link" || tag.hasPrefix("link:") {
      let href = tag.hasPrefix("link:")
        ? String(tag.dropFirst("link:".count))
        : ""
      toggleLink(href: href)
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
        // Big/Small меняют реальный pointSize, чтобы юзер видел
        // изменение в композере (bug 5). На receiver-side
        // `AnimatedTextSpan` рендерит тот же масштаб (bug 4 закрывается
        // автоматически — HTML уже корректно сохраняет `data-anim`).
        // Animated effects (shake/nod/…) — только semibold + accent;
        // саму анимацию проигрывает receiver.
        MentionAttributedString._applyEffectVisualStyle(
          &attrs, effect: e, baseFont: baseFont,
          baseColor: baseColor, accentColor: accentColor)
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

  // MARK: - Phase 13: spoiler / quote / link

  /// Переключает spoiler attribute (`<span class="spoiler-text">`) на
  /// selection или typingAttributes. Visually в композере: серый фон
  /// + dim текст. Анимированная dust-mask живёт только на receiver-side
  /// (`_SpoilerInline`).
  private func toggleSpoiler() {
    let probeAttrs = _probeAttrs()
    let nextActive = (probeAttrs[MentionAttributedString.spoilerKey]
      as? Bool) != true
    func patch(_ attrs: inout [NSAttributedString.Key: Any]) {
      if nextActive {
        attrs[MentionAttributedString.spoilerKey] = true
        attrs[.backgroundColor] = baseColor.withAlphaComponent(0.18)
        attrs[.foregroundColor] = baseColor.withAlphaComponent(0.32)
      } else {
        attrs.removeValue(forKey: MentionAttributedString.spoilerKey)
        attrs.removeValue(forKey: .backgroundColor)
        attrs[.foregroundColor] = baseColor
      }
    }
    _applyCustomToggle(patch: patch)
  }

  /// Переключает quote attribute (`<blockquote>`). Composer style:
  /// italic + accent foreground. Полноценный quote-bar — receiver-side.
  private func toggleQuote() {
    let probeAttrs = _probeAttrs()
    let nextActive = (probeAttrs[MentionAttributedString.quoteKey]
      as? Bool) != true
    func patch(_ attrs: inout [NSAttributedString.Key: Any]) {
      if nextActive {
        attrs[MentionAttributedString.quoteKey] = true
        var symbolic = (attrs[.font] as? UIFont)?.fontDescriptor
          .symbolicTraits ?? []
        symbolic.insert(.traitItalic)
        if let d = baseFont.fontDescriptor.withSymbolicTraits(symbolic) {
          attrs[.font] = UIFont(descriptor: d, size: baseFont.pointSize)
        }
        attrs[.foregroundColor] = accentColor.withAlphaComponent(0.86)
      } else {
        attrs.removeValue(forKey: MentionAttributedString.quoteKey)
        attrs[.font] = baseFont
        attrs[.foregroundColor] = baseColor
      }
    }
    _applyCustomToggle(patch: patch)
  }

  /// Wrap selection в `<a href="...">…</a>`. Если href пустой —
  /// убираем link attribute.
  private func toggleLink(href: String) {
    let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
    func patch(_ attrs: inout [NSAttributedString.Key: Any]) {
      if trimmed.isEmpty {
        attrs.removeValue(forKey: MentionAttributedString.linkHrefKey)
        attrs.removeValue(forKey: .underlineStyle)
        attrs.removeValue(forKey: .underlineColor)
        attrs[.foregroundColor] = baseColor
      } else {
        attrs[MentionAttributedString.linkHrefKey] = trimmed
        attrs[.foregroundColor] = accentColor
        attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        attrs[.underlineColor] = accentColor
      }
    }
    _applyCustomToggle(patch: patch)
  }

  /// Общий паттерн для toggle-атрибутов: снимок selection/typing,
  /// применить patch к каждому run (или typingAttributes), уведомить
  /// Dart через textChanged. Использует то же anti-echo-flag
  /// `isApplyingRemoteText`.
  private func _applyCustomToggle(
    patch: (inout [NSAttributedString.Key: Any]) -> Void
  ) {
    let selRange = textView.selectedRange
    if selRange.length > 0 {
      let mut = NSMutableAttributedString(attributedString: textView.attributedText)
      mut.enumerateAttributes(in: selRange, options: []) { attrs, range, _ in
        var copy = attrs
        patch(&copy)
        mut.setAttributes(copy, range: range)
      }
      isApplyingRemoteText = true
      textView.attributedText = mut
      textView.selectedRange = selRange
      isApplyingRemoteText = false
      let plain = currentPlainText()
      let sel = plainSelection(plain)
      channel.invokeMethod(
        "textChanged",
        arguments: [
          "text": plain,
          "selectionStart": sel.start,
          "selectionEnd": sel.end,
        ])
    } else {
      var ta = textView.typingAttributes
      patch(&ta)
      textView.typingAttributes = ta
    }
  }

  /// Возвращает атрибуты курсора (или начала selection) — нужно для
  /// определения, надо ли activate or deactivate.
  private func _probeAttrs() -> [NSAttributedString.Key: Any] {
    let selRange = textView.selectedRange
    let probeLoc = selRange.length > 0
      ? selRange.location
      : max(0, selRange.location - 1)
    if probeLoc < textView.attributedText.length && probeLoc >= 0 {
      return textView.attributedText.attributes(at: probeLoc, effectiveRange: nil)
    }
    return textView.typingAttributes
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

  /// Bug A: если returnKeyType установлен в `.search` (режим location-
  /// share для ввода адреса), перехватываем нажатие Enter: вместо
  /// вставки `\n` шлём `submitRequested` в Dart и блокируем
  /// дефолтную обработку. Для других returnKeyType-ов поведение
  /// прежнее.
  func textView(
    _ textView: UITextView,
    shouldChangeTextIn range: NSRange,
    replacementText text: String
  ) -> Bool {
    if text == "\n" && textView.returnKeyType == .search {
      channel.invokeMethod("submitRequested", arguments: nil)
      return false
    }
    return true
  }

  func textViewDidChange(_ textView: UITextView) {
    updateHintVisibility()
    notifyContentHeightIfChanged()
    if isApplyingRemoteText { return }
    // Diagnostic dump (Phase 8 sticker bug): перед extract'ом перечислим
    // все runs/attribute keys в attributedText. Если стикер вставился
    // через Apple-private API без NSTextAttachment / NSAdaptiveImageGlyph,
    // это поможет увидеть какой именно key/class он использует.
    debugDumpAttributedText(tag: "textViewDidChange")
    // Phase 8: системная emoji-клавиатура (вкладка Stickers/Memoji/Genmoji)
    // вставляет картинку в UITextView как `NSTextAttachment` или (iOS 18+)
    // как `NSAdaptiveImageGlyph`. Наш `serialize()` не знает про
    // attachment-runs — нужно их вытащить, сохранить в tmp PNG, удалить
    // из attributedText и отдать Dart как обычные image-attachment'ы.
    let extracted = extractAndRemoveInlineImageAttachments()
    NSLog(
      "[sticker-debug] extractAndRemoveInlineImageAttachments → \(extracted.count) paths"
    )
    if !extracted.isEmpty {
      channel.invokeMethod(
        "attachmentInserted", arguments: ["paths": extracted])
    }
    // Bug 6: системное iOS Format menu (iOS 18+) умеет менять цвет
    // шрифта, но наш HTML-протокол его не передаёт. Сбрасываем кастомные
    // foregroundColor'ы обратно в baseColor, чтобы UX был honest: цвет
    // в композере не «застревает» после того как юзер ткнул на palette.
    normalizeForegroundColorsToBase()
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

  /// Определяет расширение файла для raw-бытов sticker'а. Сначала
  /// пытаемся UTType.preferredFilenameExtension, затем — magic bytes.
  /// Поддерживаем gif / webp / heic / png; неизвестное → png (он же
  /// fallback на receiver-side).
  private func inferStickerExtension(data: Data, contentType: Any?) -> String {
    if let utObj = contentType as? NSObject {
      if let ext = utObj.value(forKey: "preferredFilenameExtension") as? String,
        !ext.isEmpty
      {
        return ext.lowercased()
      }
    }
    guard data.count >= 12 else { return "png" }
    let bytes = [UInt8](data.prefix(12))
    // GIF87a / GIF89a
    if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) { return "gif" }
    // PNG
    if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
    // WebP — RIFF????WEBP
    if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]),
      bytes[8] == 0x57, bytes[9] == 0x45, bytes[10] == 0x42, bytes[11] == 0x50
    {
      return "webp"
    }
    // HEIC / HEIF — ftyp box at offset 4, brand at offset 8
    if bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
      let brand = String(
        bytes: Array(bytes[8..<12]), encoding: .ascii) ?? ""
      if brand.hasPrefix("heic") || brand.hasPrefix("heix")
        || brand.hasPrefix("mif1") || brand.hasPrefix("hevc")
      {
        return "heic"
      }
    }
    return "png"
  }

  /// Diagnostic: перечисляет все runs в `attributedText` и для каждого
  /// печатает все attribute keys + class имя value (если объект). Помогает
  /// найти Apple-private attribute key через который iOS Sticker keyboard
  /// вставляет UISticker / Genmoji / Memoji. После того как мы найдём key
  /// — добавим его в `extractAndRemoveInlineImageAttachments` и удалим
  /// этот дамп.
  private func debugDumpAttributedText(tag: String) {
    let attr = textView.attributedText
    guard let attr = attr else {
      NSLog("[sticker-debug] [\(tag)] attributedText=nil")
      return
    }
    NSLog(
      "[sticker-debug] [\(tag)] attributedText.length=\(attr.length) "
        + "string=\"\(attr.string.replacingOccurrences(of: "\n", with: "\\n"))\""
    )
    let full = NSRange(location: 0, length: attr.length)
    var runIdx = 0
    attr.enumerateAttributes(in: full, options: []) { attrs, range, _ in
      var keysDesc = ""
      for (k, v) in attrs {
        let cls = type(of: v as AnyObject)
        keysDesc += "  • \(k.rawValue) → \(cls)\n"
      }
      NSLog(
        "[sticker-debug] [\(tag)] run #\(runIdx) range=\(NSStringFromRange(range)) "
          + "attrs=\n\(keysDesc.isEmpty ? "  (none)" : keysDesc)"
      )
      runIdx += 1
    }
  }

  /// Обходит все runs `attributedText`, для не-mention и не-effect runs
  /// сбрасывает `foregroundColor` обратно в `baseColor`. Mention-чипы и
  /// animated/size effect-run'ы оставляем — у них кастомный цвет
  /// (accent / faded) задан осознанно.
  private func normalizeForegroundColorsToBase() {
    let attr = textView.attributedText
    guard let attr = attr, attr.length > 0 else { return }
    let mut = NSMutableAttributedString(attributedString: attr)
    let full = NSRange(location: 0, length: attr.length)
    var changed = false
    mut.enumerateAttributes(in: full, options: []) { attrs, range, _ in
      if attrs[MentionAttributedString.tokenKey] != nil { return }
      if attrs[MentionAttributedString.effectKey] != nil { return }
      // Phase 13: spoiler/quote/link тоже имеют кастомный foreground —
      // не трогаем их.
      if attrs[MentionAttributedString.spoilerKey] != nil { return }
      if attrs[MentionAttributedString.quoteKey] != nil { return }
      if attrs[MentionAttributedString.linkHrefKey] != nil { return }
      if let c = attrs[.foregroundColor] as? UIColor, c != baseColor {
        mut.removeAttribute(.foregroundColor, range: range)
        mut.addAttribute(.foregroundColor, value: baseColor, range: range)
        changed = true
      }
    }
    if changed {
      let sel = textView.selectedRange
      isApplyingRemoteText = true
      textView.attributedText = mut
      textView.selectedRange = NSRange(
        location: min(sel.location, mut.length), length: sel.length)
      isApplyingRemoteText = false
    }
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
  /// Каждый найденный inline-attachment представлен либо UIImage'ем
  /// (legacy NSTextAttachment — нет raw data, нужен encode в PNG),
  /// либо raw `Data` + extension (NSAdaptiveImageGlyph — это могут быть
  /// **GIF / WebP / HEIC анимации**, и encode через UIImage сожрёт
  /// frame'ы. Сохраняем bytes как есть.)
  private enum StickerPayload {
    case image(UIImage)
    case raw(Data, String)
  }

  private func extractAndRemoveInlineImageAttachments() -> [String] {
    let attr = textView.attributedText
    guard let attr = attr, attr.length > 0 else { return [] }
    let full = NSRange(location: 0, length: attr.length)
    var hits: [(range: NSRange, payload: StickerPayload)] = []
    // Classic stickers / memoji legacy: вставляются как NSTextAttachment
    // с image либо dynamic `image(forBounds:textContainer:...)`. Передаём
    // настоящий textContainer — без него iOS возвращает nil для рендеров,
    // которые зависят от layout (часть memoji-вариантов).
    attr.enumerateAttribute(.attachment, in: full, options: []) {
      val, range, _ in
      guard let attach = val as? NSTextAttachment else { return }
      var img: UIImage? = attach.image
      if img == nil {
        img = attach.image(
          forBounds: attach.bounds,
          textContainer: textView.textContainer,
          characterIndex: range.location)
      }
      if img == nil, let data = attach.contents {
        img = UIImage(data: data)
      }
      if let i = img { hits.append((range, .image(i))) }
    }
    // Phase 8 sticker fix: iOS Sticker / Memoji / Genmoji (iOS 18+)
    // вставляются как OBJECT-REPLACEMENT-CHARACTER (U+FFFC) с custom
    // attribute. Реальный key — `CTAdaptiveImageProvider` (выяснено по
    // дампу attributedText на устройстве). Value — `NSAdaptiveImageGlyph`
    // Obj-C класс с `imageContent: Data` raw bytes + `contentType` UTType.
    // Сохраняем raw bytes БЕЗ конвертации — анимированные стикеры (GIF/
    // WebP/HEIC) теряют frames если прогнать через UIImage→pngData.
    if #available(iOS 18.0, *) {
      let candidateKeys = [
        "CTAdaptiveImageProvider",
        "NSAdaptiveImageGlyph",
      ]
      for keyName in candidateKeys {
        let key = NSAttributedString.Key(keyName)
        attr.enumerateAttribute(key, in: full, options: []) { val, range, _ in
          guard let any = val as? NSObject else { return }
          // KVC: `imageContent` есть у NSAdaptiveImageGlyph (public API
          // iOS 18+). А `contentType` НЕТ — раньше мы ошибочно дёргали
          // его через KVC и получали NSUnknownKeyException → краш.
          // Расширение определяем только через magic-byte sniff в
          // `inferStickerExtension`.
          guard let data = any.value(forKey: "imageContent") as? Data else {
            return
          }
          let ext = self.inferStickerExtension(data: data, contentType: nil)
          hits.append((range, .raw(data, ext)))
        }
      }
    }
    if hits.isEmpty { return [] }

    var paths: [String] = []
    for (_, payload) in hits {
      let bytes: Data
      let ext: String
      switch payload {
      case .image(let img):
        // PNG сохраняет прозрачность memoji/sticker'а — JPEG бы её
        // схлопнул в чёрный.
        guard let png = img.pngData() else { continue }
        bytes = png
        ext = "png"
      case .raw(let raw, let e):
        bytes = raw
        ext = e
      }
      let name = "composer_sticker_\(UUID().uuidString).\(ext)"
      let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(name)
      do {
        try bytes.write(to: url, options: .atomic)
        paths.append(url.path)
      } catch {
        // tmp недоступен — просто пропускаем стикер.
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
    NSLog("[panel-toggle] swift textViewDidBeginEditing")
    channel.invokeMethod("focusChanged", arguments: ["focused": true])
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    NSLog("[panel-toggle] swift textViewDidEndEditing")
    channel.invokeMethod("focusChanged", arguments: ["focused": false])
  }

  // MARK: - NSTextStorageDelegate (sticker diagnostic)

  /// Backup-канал для sticker insert'ов: triggers даже когда
  /// `textViewDidChange` не вызывается (sticker keyboard вставляет через
  /// UITextInteraction). Если видим `editedAttributes` без
  /// `editedCharacters` — значит изменился только attribute (например
  /// добавился UISticker через NSTextAttachment в существующий character).
  func textStorage(
    _ textStorage: NSTextStorage,
    didProcessEditing editedMask: NSTextStorage.EditActions,
    range editedRange: NSRange,
    changeInLength delta: Int
  ) {
    if isApplyingRemoteText { return }
    let chars = editedMask.contains(.editedCharacters)
    let attrs = editedMask.contains(.editedAttributes)
    NSLog(
      "[sticker-debug] textStorage didProcessEditing "
        + "chars=\(chars) attrs=\(attrs) range=\(NSStringFromRange(editedRange)) delta=\(delta)"
    )
    // Если textViewDidChange по какой-то причине не вызовется (Apple's
    // private path для UISticker), сделаем extract здесь же. defer чтобы
    // dump шёл после возврата UITextView из processing.
    DispatchQueue.main.async { [weak self] in
      guard let self = self, !self.isApplyingRemoteText else { return }
      self.debugDumpAttributedText(tag: "textStorage.didProcessEditing")
    }
  }

  // MARK: - Hint label

  private func updateHintVisibility() {
    let empty = textView.attributedText.length == 0
    hintLabel.isHidden = !empty
  }

  // MARK: - Content height (для autoresize, минимум 1 строка → maxLines×lineH)

  private func notifyContentHeightIfChanged() {
    // `textViewDidChange` срабатывает ДО того как UIKit успевает
    // переразложить layout — `contentSize` тут возвращает старое
    // значение, и при добавлении новой строки composer не растёт.
    // `sizeThatFits` форсирует синхронный layout-pass и возвращает
    // актуальную высоту. Ширину берём текущую, высоту — unbounded.
    let width =
      textView.frame.width > 0 ? textView.frame.width : container.bounds.width
    let fits = textView.sizeThatFits(
      CGSize(width: width, height: .greatestFiniteMagnitude))
    let target = max(fits.height, lineHeight())
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
