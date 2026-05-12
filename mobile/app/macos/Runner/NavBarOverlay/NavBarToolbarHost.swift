import AppKit
import FlutterMacOS

/// Hosts an `NSToolbar` on the main `NSWindow` and forwards user interaction
/// back through `NavBarBridge`. Mirrors the iOS overlay-host contract so the
/// Flutter side keeps a single API surface.
final class NavBarToolbarHost: NSObject, NSToolbarDelegate, NSSearchFieldDelegate {
  static let shared = NavBarToolbarHost()

  private weak var window: NSWindow?
  private var toolbar: NSToolbar?
  private var trailingActions: [NavBarToolbarAction] = []
  private var leadingAction: NavBarToolbarAction?
  private var titleText: String = ""
  private var subtitleText: String?
  private var searchField: NSSearchField?

  var onEvent: ((String, [String: Any]) -> Void)?

  func attach(to window: NSWindow) {
    self.window = window
    window.titlebarAppearsTransparent = true
    let toolbar = NSToolbar(identifier: "lighchat.nav_overlay")
    toolbar.displayMode = .iconAndLabel
    toolbar.allowsUserCustomization = false
    toolbar.delegate = self
    window.toolbar = toolbar
    self.toolbar = toolbar
    applyLiquidGlassIfAvailable(on: window)
  }

  func applyTopBar(_ config: [String: Any]) {
    let visible = config["visible"] as? Bool ?? true
    guard let window = window else { return }
    if !visible {
      window.toolbar = nil
      return
    }
    if window.toolbar == nil, let toolbar = toolbar {
      window.toolbar = toolbar
    }

    if let title = config["title"] as? [String: Any] {
      titleText = title["title"] as? String ?? ""
      subtitleText = title["subtitle"] as? String
      window.title = titleText
      if #available(macOS 11.0, *) {
        window.subtitle = subtitleText ?? ""
      }
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
      trailingActions = trailing.map { dict in
        NavBarToolbarAction(
          id: dict["id"] as? String ?? "",
          symbol: (dict["icon"] as? [String: Any])?["symbol"] as? String
            ?? "ellipsis",
          tooltip: dict["title"] as? String
        )
      }
    }

    toolbar?.items.forEach { _ in }
    // Force toolbar to rebuild its items
    let identifiers = toolbarDefaultItemIdentifiers(toolbar!)
    while let toolbar = toolbar, toolbar.items.count > 0 {
      toolbar.removeItem(at: 0)
    }
    for (i, ident) in identifiers.enumerated() {
      toolbar?.insertItem(withItemIdentifier: ident, at: i)
    }
  }

  func applyBottomBar(_ config: [String: Any]) {
    // macOS mobile layout doesn't host a tab bar — no-op. Workspace layout
    // uses its own Flutter-driven sidebar.
    _ = config
  }

  func applySearch(_ config: [String: Any]) {
    // Search appears inline in the toolbar via the `searchField` item which
    // toggles its `searchField.isHidden` state.
    let active = config["active"] as? Bool ?? false
    if let searchField = searchField {
      searchField.isHidden = !active
      if active {
        searchField.stringValue = config["value"] as? String ?? ""
        searchField.placeholderString = config["placeholder"] as? String
        searchField.window?.makeFirstResponder(searchField)
      }
    }
  }

  func applySelection(_ config: [String: Any]) {
    let active = config["active"] as? Bool ?? false
    if !active { return }
    let count = config["count"] as? Int ?? 0
    window?.title = "\(count)"
  }

  func applyScrollOffset(_ offset: CGFloat) {
    _ = offset
  }

  // MARK: - NSToolbarDelegate

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    var idents: [NSToolbarItem.Identifier] = []
    if let leading = leadingAction {
      idents.append(NSToolbarItem.Identifier("leading_\(leading.id)"))
    }
    idents.append(.flexibleSpace)
    for action in trailingActions {
      idents.append(NSToolbarItem.Identifier("trailing_\(action.id)"))
    }
    return idents
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    let raw = itemIdentifier.rawValue
    if raw.hasPrefix("leading_") {
      let id = String(raw.dropFirst("leading_".count))
      guard let action = leadingAction else { return nil }
      return makeItem(id: itemIdentifier, action: action, isLeading: true, actionId: id)
    }
    if raw.hasPrefix("trailing_") {
      let id = String(raw.dropFirst("trailing_".count))
      if let action = trailingActions.first(where: { $0.id == id }) {
        return makeItem(id: itemIdentifier, action: action, isLeading: false, actionId: id)
      }
    }
    return nil
  }

  private func makeItem(
    id: NSToolbarItem.Identifier,
    action: NavBarToolbarAction,
    isLeading: Bool,
    actionId: String
  ) -> NSToolbarItem {
    let item = NSToolbarItem(itemIdentifier: id)
    let image: NSImage?
    if #available(macOS 11.0, *) {
      image = NSImage(systemSymbolName: action.symbol, accessibilityDescription: nil)
    } else {
      image = nil
    }
    item.image = image
    item.label = action.tooltip ?? ""
    item.toolTip = action.tooltip
    item.target = self
    item.action = isLeading
      ? #selector(onLeadingTap(_:))
      : #selector(onTrailingTap(_:))
    objc_setAssociatedObject(
      item, &actionIdKey, actionId, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    return item
  }

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
