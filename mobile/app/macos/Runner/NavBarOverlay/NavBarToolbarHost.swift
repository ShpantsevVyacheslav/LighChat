import AppKit
import FlutterMacOS

/// Hosts an `NSToolbar` on the main `NSWindow` and forwards user interaction
/// back through `NavBarBridge`. Mirrors the iOS overlay-host contract so the
/// Flutter side keeps a single API surface.
///
/// Design notes:
///
/// - Toolbar items are rebuilt only when the topbar / selection / search
///   *signature* changes — calling `applyTopBar` with the same payload is a
///   no-op (mirrors iOS-side dedupe in `NavBarBridge`).
/// - `searchField` is registered as a fixed toolbar item id but its content
///   view's `isHidden` flag is toggled, so we never have to mutate the items
///   array when the user enters / leaves search mode.
/// - On macOS 26+ a titled NSWindow with `titlebarAppearsTransparent` opts
///   into Liquid Glass automatically; the helper hook is reserved for future
///   explicit tweaks.
final class NavBarToolbarHost: NSObject, NSToolbarDelegate, NSSearchFieldDelegate {
  static let shared = NavBarToolbarHost()

  private weak var window: NSWindow?
  private var toolbar: NSToolbar?

  // Current bar state. Used for both delegate callbacks and signature
  // dedupe.
  private var trailingActions: [NavBarToolbarAction] = []
  private var leadingAction: NavBarToolbarAction?
  private var titleText: String = ""
  private var subtitleText: String?

  // Selection mode overlay. When `active`, title shows the count and
  // trailing items are replaced by `selectionActions` until selection
  // mode is turned off.
  private var selectionActive: Bool = false
  private var selectionCount: Int = 0
  private var selectionActions: [NavBarToolbarAction] = []

  // Search state. The field itself lives in a single toolbar item which
  // is always part of the layout so we don't need to rebuild items when
  // search mode toggles.
  private var searchActive: Bool = false
  private var searchValue: String = ""
  private var searchPlaceholder: String = ""
  private var searchField: NSSearchField?
  private var searchToolbarItem: NSToolbarItem?

  // Dedupe key: when the signature of the current state hasn't changed
  // we skip toolbar rebuilds. Keeps Liquid Glass animations smooth and
  // matches the iOS bridge behaviour.
  private var lastSignature: String?

  var onEvent: ((String, [String: Any]) -> Void)?

  // MARK: - Lifecycle

  func attach(to window: NSWindow) {
    self.window = window
    window.titlebarAppearsTransparent = true
    let toolbar = NSToolbar(identifier: "lighchat.nav_overlay")
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.delegate = self
    window.toolbar = toolbar
    self.toolbar = toolbar
    applyLiquidGlassIfAvailable(on: window)
  }

  // MARK: - Top bar

  func applyTopBar(_ config: [String: Any]) {
    guard let window = window else { return }
    let visible = config["visible"] as? Bool ?? true

    if !visible {
      // Don't nuke the toolbar reference — toggling visibility keeps it
      // around so the next visible state can fade in without a fresh
      // delegate roundtrip.
      window.toolbar?.isVisible = false
      return
    }
    if window.toolbar == nil, let toolbar = toolbar {
      window.toolbar = toolbar
    }
    window.toolbar?.isVisible = true

    if let title = config["title"] as? [String: Any] {
      titleText = title["title"] as? String ?? ""
      subtitleText = title["subtitle"] as? String
    }

    if let leading = config["leading"] as? [String: Any] {
      let type = leading["type"] as? String ?? "back"
      let id = leading["id"] as? String ?? "back"
      if type == "none" {
        leadingAction = nil
      } else {
        let symbol = (leading["icon"] as? [String: Any])?["symbol"] as? String
        leadingAction = NavBarToolbarAction(
          id: id,
          symbol: symbol ?? defaultLeadingSymbol(for: type),
          tooltip: nil)
      }
    }

    if let trailing = config["trailing"] as? [[String: Any]] {
      trailingActions = trailing.map(makeAction(from:))
    }

    refreshChrome()
  }

  // MARK: - Bottom bar

  func applyBottomBar(_ config: [String: Any]) {
    // macOS mobile layout doesn't host a tab bar — no-op. Workspace
    // layout uses its own Flutter-driven sidebar.
    _ = config
  }

  // MARK: - Search

  func applySearch(_ config: [String: Any]) {
    let active = config["active"] as? Bool ?? false
    let value = config["value"] as? String ?? ""
    let placeholder = config["placeholder"] as? String ?? ""

    searchActive = active
    searchValue = value
    searchPlaceholder = placeholder

    if let field = searchField {
      field.isHidden = !active
      field.stringValue = value
      field.placeholderString = placeholder
      if active {
        DispatchQueue.main.async { [weak field] in
          field?.window?.makeFirstResponder(field)
        }
      } else {
        // Resign first responder so cmd+W / esc don't end up in the
        // search field after the user dismisses search.
        if field.currentEditor() != nil {
          field.window?.makeFirstResponder(nil)
        }
      }
    }

    refreshChrome()
  }

  // MARK: - Selection mode

  func applySelection(_ config: [String: Any]) {
    let active = config["active"] as? Bool ?? false
    selectionActive = active
    if active {
      selectionCount = config["count"] as? Int ?? 0
      let actions = config["actions"] as? [[String: Any]] ?? []
      selectionActions = actions.map(makeAction(from:))
    } else {
      selectionCount = 0
      selectionActions = []
    }
    refreshChrome()
  }

  // MARK: - Scroll offset (for scroll-edge effect)

  func applyScrollOffset(_ offset: CGFloat) {
    // NSToolbar already handles scroll-edge effect via its own appearance
    // engine when materialized into a titled window. Reserved hook for
    // future custom tinting.
    _ = offset
  }

  // MARK: - Chrome refresh

  /// Re-applies window title/subtitle and rebuilds toolbar items if the
  /// signature changed since the last call.
  private func refreshChrome() {
    guard let window = window, let toolbar = toolbar else { return }

    if selectionActive {
      window.title = "\(selectionCount)"
      if #available(macOS 11.0, *) {
        window.subtitle = ""
      }
    } else {
      window.title = titleText
      if #available(macOS 11.0, *) {
        window.subtitle = subtitleText ?? ""
      }
    }

    let signature = currentSignature()
    if signature == lastSignature { return }
    lastSignature = signature

    // Force toolbar to rebuild via its delegate.
    while toolbar.items.count > 0 {
      toolbar.removeItem(at: 0)
    }
    let identifiers = toolbarDefaultItemIdentifiers(toolbar)
    for (i, ident) in identifiers.enumerated() {
      toolbar.insertItem(withItemIdentifier: ident, at: i)
    }
  }

  private func currentSignature() -> String {
    var parts: [String] = []
    parts.append("title:\(titleText)|\(subtitleText ?? "")")
    parts.append("leading:\(leadingAction?.id ?? "-")|\(leadingAction?.symbol ?? "-")")
    if selectionActive {
      parts.append("sel:1|c=\(selectionCount)")
      for a in selectionActions {
        parts.append("sa:\(a.id)|\(a.symbol)")
      }
    } else {
      parts.append("sel:0")
      for a in trailingActions {
        parts.append("ta:\(a.id)|\(a.symbol)")
      }
    }
    parts.append("search:\(searchActive ? 1 : 0)")
    return parts.joined(separator: ";")
  }

  // MARK: - NSToolbarDelegate

  private static let searchItemIdentifier = NSToolbarItem.Identifier("lighchat.search")

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    var idents: [NSToolbarItem.Identifier] = []
    if let leading = leadingAction {
      idents.append(NSToolbarItem.Identifier("leading_\(leading.id)"))
    }
    idents.append(.flexibleSpace)
    if searchActive {
      idents.append(Self.searchItemIdentifier)
    }
    let actions = selectionActive ? selectionActions : trailingActions
    for action in actions {
      idents.append(NSToolbarItem.Identifier("trailing_\(action.id)"))
    }
    return idents
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    var ids = toolbarDefaultItemIdentifiers(toolbar)
    if !ids.contains(Self.searchItemIdentifier) {
      ids.append(Self.searchItemIdentifier)
    }
    return ids
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    if itemIdentifier == Self.searchItemIdentifier {
      return makeSearchItem()
    }
    let raw = itemIdentifier.rawValue
    if raw.hasPrefix("leading_") {
      let id = String(raw.dropFirst("leading_".count))
      guard let action = leadingAction else { return nil }
      return makeButtonItem(id: itemIdentifier, action: action, isLeading: true, actionId: id)
    }
    if raw.hasPrefix("trailing_") {
      let id = String(raw.dropFirst("trailing_".count))
      let pool = selectionActive ? selectionActions : trailingActions
      if let action = pool.first(where: { $0.id == id }) {
        return makeButtonItem(
          id: itemIdentifier, action: action, isLeading: false, actionId: id)
      }
    }
    return nil
  }

  // MARK: - Item construction

  private func makeAction(from dict: [String: Any]) -> NavBarToolbarAction {
    NavBarToolbarAction(
      id: dict["id"] as? String ?? "",
      symbol: (dict["icon"] as? [String: Any])?["symbol"] as? String ?? "ellipsis",
      tooltip: dict["title"] as? String
    )
  }

  private func makeButtonItem(
    id: NSToolbarItem.Identifier,
    action: NavBarToolbarAction,
    isLeading: Bool,
    actionId: String
  ) -> NSToolbarItem {
    let item = NSToolbarItem(itemIdentifier: id)
    item.image = systemImage(named: action.symbol)
    item.label = action.tooltip ?? ""
    item.paletteLabel = action.tooltip ?? ""
    item.toolTip = action.tooltip
    item.target = self
    item.action =
      isLeading ? #selector(onLeadingTap(_:)) : #selector(onTrailingTap(_:))
    objc_setAssociatedObject(
      item, &actionIdKey, actionId, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    return item
  }

  private func makeSearchItem() -> NSToolbarItem {
    if let existing = searchToolbarItem { return existing }
    let item = NSToolbarItem(itemIdentifier: Self.searchItemIdentifier)
    let field = NSSearchField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
    field.delegate = self
    field.target = self
    field.action = #selector(onSearchSubmit(_:))
    field.placeholderString = searchPlaceholder
    field.stringValue = searchValue
    field.isHidden = !searchActive
    searchField = field
    item.view = field
    item.minSize = NSSize(width: 160, height: 24)
    item.maxSize = NSSize(width: 320, height: 24)
    searchToolbarItem = item
    return item
  }

  private func systemImage(named symbol: String) -> NSImage? {
    if #available(macOS 11.0, *) {
      if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
        return img
      }
    }
    // Fallback for older macOS or non-SF names — try the bundle.
    return NSImage(named: NSImage.Name(symbol))
  }

  // MARK: - NSSearchFieldDelegate

  func controlTextDidChange(_ obj: Notification) {
    guard let field = obj.object as? NSSearchField, field === searchField else { return }
    let value = field.stringValue
    if value == searchValue { return }
    searchValue = value
    onEvent?("searchChange", ["value": value])
  }

  @objc private func onSearchSubmit(_ sender: NSSearchField) {
    onEvent?("searchSubmit", ["value": sender.stringValue])
  }

  // MARK: - Actions

  private func defaultLeadingSymbol(for type: String) -> String {
    switch type {
    case "close": return "xmark"
    case "menu": return "line.3.horizontal"
    default: return "chevron.backward"
    }
  }

  @objc private func onLeadingTap(_ sender: NSToolbarItem) {
    let id =
      (objc_getAssociatedObject(sender, &actionIdKey) as? String) ?? "back"
    onEvent?("leadingTap", ["id": id])
  }

  @objc private func onTrailingTap(_ sender: NSToolbarItem) {
    if let id = objc_getAssociatedObject(sender, &actionIdKey) as? String {
      onEvent?("actionTap", ["id": id])
    }
  }

  private func applyLiquidGlassIfAvailable(on window: NSWindow) {
    if #available(macOS 26.0, *) {
      // Liquid Glass became the default appearance of titled NSWindow on
      // macOS 26 — `titlebarAppearsTransparent` is enough to opt in. Hook
      // reserved for future explicit toggles when the SDK exposes them.
    }
  }
}

private var actionIdKey: UInt8 = 0

private struct NavBarToolbarAction {
  let id: String
  let symbol: String
  let tooltip: String?
}
