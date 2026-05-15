import Flutter
import Foundation
import UIKit

/// Один instance нативного composer-инпута. Внутри — обычный `UITextView`,
/// поэтому:
///  - системное меню Cut/Copy/Paste/Replace/AutoFill срабатывает «из коробки»,
///  - Writing Tools (iOS 26+ Apple Intelligence) появляются в long-press меню,
///  - кнопка диктовки в QuickType bar, smart selection — всё бесплатно.
///
/// Двусторонний sync с Dart через `lighchat/native_composer_<viewId>`:
///  - Dart→Swift: `setText(text)`, `focus()`, `unfocus()`, `setStyle(args)`,
///    `setHint(text)`.
///  - Swift→Dart: `textChanged(text)`, `selectionChanged(start,end)`,
///    `focusChanged(focused)`, `contentHeightChanged(height)`.
final class NativeComposerView: NSObject, FlutterPlatformView, UITextViewDelegate {
  private let container: UIView
  private let textView: UITextView
  private let hintLabel: UILabel
  private let channel: FlutterMethodChannel
  /// «Защита от эха»: когда Dart прислал setText, мы не должны отправлять
  /// textChanged обратно в Dart (иначе бесконечный цикл).
  private var isApplyingRemoteText = false
  /// Запомненный contentSize чтобы не спамить Dart одинаковыми значениями.
  private var lastReportedHeight: CGFloat = 0

  init(
    frame: CGRect, viewId: Int64, args: [String: Any],
    messenger: FlutterBinaryMessenger
  ) {
    container = UIView(frame: frame)
    container.backgroundColor = .clear

    textView = UITextView(frame: .zero)
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
    hintLabel.font = textView.font

    if let fgHex = args["textColorHex"] as? String,
      let fg = UIColor.fromHex(fgHex)
    {
      textView.textColor = fg
    } else {
      textView.textColor = .label
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
    }

    hintLabel.text = (args["hint"] as? String) ?? ""

    if let initial = args["initialText"] as? String, !initial.isEmpty {
      isApplyingRemoteText = true
      textView.text = initial
      isApplyingRemoteText = false
    }
    updateHintVisibility()
    notifyContentHeightIfChanged()
  }

  // MARK: - Method handler

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setText":
      let map = call.arguments as? [String: Any] ?? [:]
      let text = (map["text"] as? String) ?? ""
      if textView.text != text {
        let prevRange = textView.selectedRange
        isApplyingRemoteText = true
        textView.text = text
        // Стараемся сохранить курсор, но не выходим за конец нового текста.
        let cap = (text as NSString).length
        let newLoc = min(prevRange.location, cap)
        textView.selectedRange = NSRange(location: newLoc, length: 0)
        isApplyingRemoteText = false
        updateHintVisibility()
        notifyContentHeightIfChanged()
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - UITextViewDelegate

  func textViewDidChange(_ textView: UITextView) {
    updateHintVisibility()
    notifyContentHeightIfChanged()
    if isApplyingRemoteText { return }
    channel.invokeMethod(
      "textChanged",
      arguments: [
        "text": textView.text ?? "",
        "selectionStart": textView.selectedRange.location,
        "selectionEnd": textView.selectedRange.location
          + textView.selectedRange.length,
      ])
  }

  func textViewDidChangeSelection(_ textView: UITextView) {
    if isApplyingRemoteText { return }
    channel.invokeMethod(
      "selectionChanged",
      arguments: [
        "start": textView.selectedRange.location,
        "end": textView.selectedRange.location + textView.selectedRange.length,
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
    let empty = (textView.text ?? "").isEmpty
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
