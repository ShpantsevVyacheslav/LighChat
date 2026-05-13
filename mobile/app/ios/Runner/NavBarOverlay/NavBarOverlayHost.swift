import Flutter
import UIKit

/// Hosts native `UINavigationBar` + `UITabBar` overlays on top of the root
/// `FlutterViewController.view`. Owns no layout itself — `additionalSafeAreaInsets`
/// on the Flutter VC is updated whenever bar visibility/height changes so
/// Flutter content stays clear of the native bars.
final class NavBarOverlayHost: NSObject, UINavigationBarDelegate,
  UISearchBarDelegate {
  static let shared = NavBarOverlayHost()

  private weak var flutterVC: UIViewController?

  private var topBar: UINavigationBar?
  private var bottomBar: UITabBar?
  private var searchBar: UISearchBar?

  private var topItem: UINavigationItem?
  private var topVisible: Bool = false
  private var bottomVisible: Bool = false
  private var searchActive: Bool = false

  private var trailingActionsById: [Int: String] = [:]
  private var tabItemsById: [ObjectIdentifier: String] = [:]
  private var leadingId: String = "back"
  private var selectionActionsById: [Int: String] = [:]

  private var topBarHeight: CGFloat = 0
  private var bottomBarHeight: CGFloat = 0

  /// Кэш «оригинальной» конфигурации, чтобы корректно восстанавливать avatar +
  /// trailing actions после выхода из режима поиска.
  private var customTitleView: UIView?
  private var lastPlainTitle: String?
  private var storedRightItems: [UIBarButtonItem] = []

  /// Avatar download tasks keyed by URL so the same URL is not fetched twice
  /// while the bar is updated repeatedly.
  private var avatarTasks: [URL: URLSessionDataTask] = [:]
  private var lastAvatarUrl: URL?
  private var avatarImageView: UIImageView?
  private var cachedAvatarImage: UIImage?

  // MARK: - Eventing

  var onEvent: ((String, [String: Any]) -> Void)?

  // MARK: - Setup

  /// Стандартная высота контента UITabBar / UINavigationBar. Apple использует
  /// эти же константы внутри UITabBarController / UINavigationController.
  /// Top bar поднят до 56pt чтобы avatar 36×36 + title + subtitle помещались
  /// без обрезки (iOS 26 Liquid Glass).
  private static let tabBarContentHeight: CGFloat = 49
  private static let navBarContentHeight: CGFloat = 56
  /// Небольшой gap между status bar и nav bar — чтобы шапка не «прилипала»
  /// к Dynamic Island / индикаторам.
  private static let navBarTopGap: CGFloat = 6

  func attach(to vc: UIViewController) {
    flutterVC = vc

    let top = UINavigationBar(frame: .zero)
    top.translatesAutoresizingMaskIntoConstraints = false
    top.delegate = self
    top.isHidden = true
    LiquidGlassAppearance.applyNavigationBar(top, tint: .systemBlue)

    let bottom = UITabBar(frame: .zero)
    bottom.translatesAutoresizingMaskIntoConstraints = false
    bottom.delegate = self
    bottom.isHidden = true
    LiquidGlassAppearance.applyTabBar(bottom, tint: .systemBlue)

    vc.view.addSubview(top)
    vc.view.addSubview(bottom)

    NSLayoutConstraint.activate([
      top.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
      top.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
      // Небольшой gap (6pt) от status bar — bar «дышит», как в дизайне iOS 26.
      top.topAnchor.constraint(
        equalTo: vc.view.safeAreaLayoutGuide.topAnchor,
        constant: Self.navBarTopGap),
      // Явная высота 56pt — выше дефолтных 44pt UINavigationBar, чтобы
      // chat header (avatar 36 + title + subtitle) дышал и не упирался
      // в bar-buttons по вертикали.
      top.heightAnchor.constraint(equalToConstant: Self.navBarContentHeight),

      bottom.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
      bottom.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
      // Фон таб-бара тянется до низа экрана, чтобы покрыть home-indicator,
      // но контент-зона (иконки + лейблы) остаётся над home indicator
      // ровно в 49pt — как у Apple UITabBarController.
      bottom.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
      bottom.topAnchor.constraint(
        equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor,
        constant: -Self.tabBarContentHeight),
    ])

    self.topBar = top
    self.bottomBar = bottom
  }

  // MARK: - Public API (called by NavBarBridge)

  func applyTopBar(_ config: [String: Any]) {
    guard let bar = topBar else { return }
    let visible = config["visible"] as? Bool ?? true
    topVisible = visible
    if !visible {
      bar.isHidden = true
      topBar?.items = []
      topItem = nil
      updateSafeAreaInsets()
      return
    }
    bar.isHidden = false

    let item = UINavigationItem()

    // Leading
    if let leading = config["leading"] as? [String: Any] {
      let type = leading["type"] as? String ?? "back"
      leadingId = leading["id"] as? String ?? "back"
      switch type {
      case "none":
        item.leftBarButtonItem = nil
      case "close":
        let btn = UIBarButtonItem(
          image: SymbolMapper.image(named: "xmark"),
          style: .plain,
          target: self,
          action: #selector(onLeadingTap))
        item.leftBarButtonItem = btn
      case "menu":
        let symbol = (leading["icon"] as? [String: Any])?["symbol"] as? String
          ?? "line.3.horizontal"
        let btn = UIBarButtonItem(
          image: SymbolMapper.image(named: symbol),
          style: .plain,
          target: self,
          action: #selector(onLeadingTap))
        item.leftBarButtonItem = btn
      case "back":
        fallthrough
      default:
        let btn = UIBarButtonItem(
          image: SymbolMapper.image(named: "chevron.backward"),
          style: .plain,
          target: self,
          action: #selector(onLeadingTap))
        item.leftBarButtonItem = btn
      }
    }

    // Title view (avatar + title + subtitle when present, otherwise plain title)
    if let title = config["title"] as? [String: Any] {
      let plain = title["title"] as? String ?? ""
      let subtitle = title["subtitle"] as? String
      let avatarUrl = title["avatarUrl"] as? String
      let fallbackInitial = title["avatarFallbackInitial"] as? String
      let statusDot = title["statusDotColorHex"] as? String

      lastPlainTitle = plain
      if subtitle != nil || avatarUrl != nil {
        customTitleView = makeTitleView(
          title: plain,
          subtitle: subtitle,
          avatarUrl: avatarUrl,
          fallbackInitial: fallbackInitial,
          statusDotHex: statusDot
        )
      } else {
        customTitleView = nil
      }

      // Когда активен режим поиска — UISearchBar держит titleView. Никакой
      // плоский title тоже не показываем (он перекрывает search bar).
      if !searchActive {
        item.titleView = customTitleView
        item.title = customTitleView == nil ? plain : nil
      } else {
        item.titleView = searchBar
        item.title = nil
      }
    }

    // Trailing actions — building list once, заодно кэшируем для restore'а
    // после выхода из поиска.
    trailingActionsById.removeAll(keepingCapacity: true)
    var items: [UIBarButtonItem] = []
    if let trailing = config["trailing"] as? [[String: Any]] {
      for action in trailing.reversed() {
        let id = action["id"] as? String ?? ""
        let symbol = (action["icon"] as? [String: Any])?["symbol"] as? String
          ?? "ellipsis"
        let enabled = action["enabled"] as? Bool ?? true
        let btn = UIBarButtonItem(
          image: SymbolMapper.image(named: symbol),
          style: .plain,
          target: self,
          action: #selector(onTrailingTap(_:)))
        btn.isEnabled = enabled
        if let tintHex = action["tintHex"] as? String,
          let color = UIColor.fromHex(tintHex) {
          btn.tintColor = color
        }
        let key = btn.hash
        trailingActionsById[key] = id
        btn.tag = key
        items.append(btn)
      }
    }
    storedRightItems = items
    // В режиме поиска прячем actions, чтобы UISearchBar получил всё место.
    item.rightBarButtonItems = searchActive ? [] : items

    // Style
    let styleName = config["style"] as? String ?? "inline"
    if styleName == "largeTitle" {
      if #available(iOS 11.0, *) {
        bar.prefersLargeTitles = true
        item.largeTitleDisplayMode = .always
      }
    } else {
      if #available(iOS 11.0, *) {
        bar.prefersLargeTitles = false
        item.largeTitleDisplayMode = .never
      }
    }

    self.topItem = item
    bar.setItems([item], animated: false)

    bar.setNeedsLayout()
    bar.layoutIfNeeded()
    topBarHeight = bar.bounds.height
    updateSafeAreaInsets()
  }

  func applyBottomBar(_ config: [String: Any]) {
    guard let bar = bottomBar else { return }
    let visible = config["visible"] as? Bool ?? true
    bottomVisible = visible
    if !visible {
      bar.isHidden = true
      bar.items = []
      updateSafeAreaInsets()
      return
    }
    bar.isHidden = false

    tabItemsById.removeAll(keepingCapacity: true)
    var items: [UITabBarItem] = []
    let configs = config["items"] as? [[String: Any]] ?? []
    let selectedId = config["selectedId"] as? String ?? ""
    var selected: UITabBarItem?

    for cfg in configs {
      let id = cfg["id"] as? String ?? ""
      let label = cfg["label"] as? String ?? ""
      let iconSymbol = (cfg["icon"] as? [String: Any])?["symbol"] as? String
        ?? "circle"
      let selectedSymbol =
        (cfg["selectedIcon"] as? [String: Any])?["symbol"] as? String
      let badge = cfg["badge"] as? String

      let normalImage = SymbolMapper.image(named: iconSymbol)
      let selectedImage =
        selectedSymbol.map { SymbolMapper.image(named: $0) } ?? normalImage

      let tab = UITabBarItem(title: label, image: normalImage, selectedImage: selectedImage)
      tab.badgeValue = badge
      tabItemsById[ObjectIdentifier(tab)] = id
      if id == selectedId {
        selected = tab
      }
      items.append(tab)
    }

    bar.setItems(items, animated: false)
    bar.selectedItem = selected ?? items.first

    bar.setNeedsLayout()
    bar.layoutIfNeeded()
    bottomBarHeight = bar.bounds.height
    updateSafeAreaInsets()
  }

  func applySearch(_ config: [String: Any]) {
    let active = config["active"] as? Bool ?? false
    let placeholder = config["placeholder"] as? String ?? ""
    let value = config["value"] as? String ?? ""
    let wasActive = searchActive
    searchActive = active

    if !active {
      // Деактивация: убираем search bar, восстанавливаем custom title (avatar +
      // title + subtitle) и trailing actions, спрятанные при включении поиска.
      if let bar = searchBar {
        bar.resignFirstResponder()
        bar.delegate = nil
      }
      searchBar = nil
      topItem?.titleView = customTitleView
      if customTitleView == nil {
        topItem?.title = lastPlainTitle
      }
      topItem?.rightBarButtonItems = storedRightItems
      return
    }

    // Активация / обновление: выставляем UISearchBar в titleView, прячем
    // все trailing actions, чтобы место хватало под текст + cancel.
    let bar = searchBar ?? UISearchBar()
    bar.placeholder = placeholder
    bar.searchBarStyle = .minimal
    bar.showsCancelButton = true
    bar.delegate = self
    if bar.text != value { bar.text = value }
    bar.translatesAutoresizingMaskIntoConstraints = false

    topItem?.titleView = bar
    topItem?.title = nil
    topItem?.rightBarButtonItems = []
    searchBar = bar

    // ОЧЕНЬ ВАЖНО: вызываем becomeFirstResponder только при первом включении.
    // На последующих updates (каждый ребилд Flutter widget'а тригерит push)
    // повторный becomeFirstResponder ловит resign/become и клавиатура «прыгает».
    if !wasActive {
      DispatchQueue.main.async { [weak bar] in bar?.becomeFirstResponder() }
    }
  }

  func applySelection(_ config: [String: Any]) {
    guard let item = topItem else { return }
    let active = config["active"] as? Bool ?? false
    if !active {
      // Caller is expected to re-push topBar to restore normal trailing items.
      return
    }
    let count = config["count"] as? Int ?? 0
    item.title = "\(count)"
    item.titleView = nil

    selectionActionsById.removeAll(keepingCapacity: true)
    let actions = config["actions"] as? [[String: Any]] ?? []
    var bbItems: [UIBarButtonItem] = []
    for action in actions.reversed() {
      let id = action["id"] as? String ?? ""
      let symbol = (action["icon"] as? [String: Any])?["symbol"] as? String
        ?? "ellipsis"
      let enabled = action["enabled"] as? Bool ?? true
      let btn = UIBarButtonItem(
        image: SymbolMapper.image(named: symbol),
        style: .plain,
        target: self,
        action: #selector(onSelectionTap(_:)))
      btn.isEnabled = enabled
      btn.tag = btn.hash
      selectionActionsById[btn.tag] = id
      bbItems.append(btn)
    }
    item.rightBarButtonItems = bbItems
  }

  func applyScrollOffset(_ offset: CGFloat) {
    // Liquid Glass / scroll-edge appearance reacts automatically once we set
    // both `standardAppearance` and `scrollEdgeAppearance`. Hook reserved for
    // additional content-aware tweaks (e.g. dimming, blur intensity).
    _ = offset
  }

  // MARK: - Title view

  private func makeTitleView(
    title: String,
    subtitle: String?,
    avatarUrl: String?,
    fallbackInitial: String?,
    statusDotHex: String?
  ) -> UIView {
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false

    let avatar = UIImageView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.layer.cornerRadius = 18
    avatar.layer.masksToBounds = true
    avatar.contentMode = .scaleAspectFill
    avatar.backgroundColor = .tertiarySystemFill
    // Reuse cached image immediately, чтобы избежать «мигания» при пересоздании
    // custom title view (Flutter пушит config на каждое изменение subtitle).
    if let cached = cachedAvatarImage,
      let raw = avatarUrl,
      let url = URL(string: raw),
      lastAvatarUrl == url {
      avatar.image = cached
    }
    avatarImageView = avatar

    let initialLabel = UILabel()
    initialLabel.translatesAutoresizingMaskIntoConstraints = false
    initialLabel.text = fallbackInitial?.uppercased()
    initialLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    initialLabel.textAlignment = .center
    initialLabel.textColor = .label
    avatar.addSubview(initialLabel)

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = title
    titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.lineBreakMode = .byTruncatingTail

    let subtitleLabel = UILabel()
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.text = subtitle
    subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.lineBreakMode = .byTruncatingTail
    subtitleLabel.isHidden = (subtitle?.isEmpty ?? true)

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.translatesAutoresizingMaskIntoConstraints = false
    textStack.axis = .vertical
    textStack.alignment = .leading
    textStack.spacing = 0

    container.addSubview(avatar)
    container.addSubview(textStack)

    NSLayoutConstraint.activate([
      avatar.widthAnchor.constraint(equalToConstant: 36),
      avatar.heightAnchor.constraint(equalToConstant: 36),
      avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      initialLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      initialLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

      textStack.leadingAnchor.constraint(
        equalTo: avatar.trailingAnchor, constant: 10),
      textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      textStack.trailingAnchor.constraint(
        lessThanOrEqualTo: container.trailingAnchor),
      container.heightAnchor.constraint(equalToConstant: 44),
    ])

    if let statusDotHex = statusDotHex, let color = UIColor.fromHex(statusDotHex) {
      let dot = UIView()
      dot.translatesAutoresizingMaskIntoConstraints = false
      dot.backgroundColor = color
      dot.layer.cornerRadius = 4
      dot.layer.borderColor = UIColor.systemBackground.cgColor
      dot.layer.borderWidth = 1.5
      container.addSubview(dot)
      NSLayoutConstraint.activate([
        dot.widthAnchor.constraint(equalToConstant: 8),
        dot.heightAnchor.constraint(equalToConstant: 8),
        dot.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
        dot.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),
      ])
    }

    if let raw = avatarUrl, let url = URL(string: raw) {
      // Уже загружали этот URL → отдаём из кэша, без сетевого запроса.
      if lastAvatarUrl == url, let cached = cachedAvatarImage {
        avatar.image = cached
      } else {
        lastAvatarUrl = url
        cachedAvatarImage = nil
        loadAvatar(url: url, into: avatar)
      }
    } else {
      // URL не задан → сбрасываем кэш, чтобы при возврате аватара его
      // перезагрузили.
      lastAvatarUrl = nil
      cachedAvatarImage = nil
    }

    return container
  }

  private func loadAvatar(url: URL, into imageView: UIImageView) {
    if avatarTasks[url] != nil { return }
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.avatarTasks[url] = nil
        guard self.lastAvatarUrl == url,
          let data = data,
          let image = UIImage(data: data)
        else { return }
        self.cachedAvatarImage = image
        imageView.image = image
        // Если customTitleView пересоздался за время сетевого запроса —
        // обновляем актуальный imageView, тот, что сейчас в нашем кэше.
        if let live = self.avatarImageView, live !== imageView {
          live.image = image
        }
      }
    }
    avatarTasks[url] = task
    task.resume()
  }

  // MARK: - Safe area sync

  private func updateSafeAreaInsets() {
    guard let vc = flutterVC else { return }
    var insets = UIEdgeInsets.zero
    if topVisible, let bar = topBar, !bar.isHidden {
      // Bar pinned: safeArea.top + navBarTopGap, height = navBarContentHeight.
      // Flutter контент должен оставаться ниже bar.bottomEdge = gap + height.
      let h = bar.bounds.height > 0 ? bar.bounds.height : Self.navBarContentHeight
      insets.top = Self.navBarTopGap + h
    }
    if bottomVisible, let bar = bottomBar, !bar.isHidden {
      // У UITabBar bounds.height = 49 + safeArea.bottom (фон тянется до низа),
      // но Flutter контент должен заходить под home indicator. Поэтому
      // дополнительный inset = только высота контента (49), системный inset
      // home indicator уже учтён в view.safeAreaInsets.
      _ = bar
      insets.bottom = Self.tabBarContentHeight
    }
    vc.additionalSafeAreaInsets = insets
  }

  // MARK: - Targets

  @objc private func onLeadingTap() {
    onEvent?("leadingTap", ["id": leadingId])
  }

  @objc private func onTrailingTap(_ sender: UIBarButtonItem) {
    if let id = trailingActionsById[sender.tag] {
      onEvent?("actionTap", ["id": id])
    }
  }

  @objc private func onSelectionTap(_ sender: UIBarButtonItem) {
    if let id = selectionActionsById[sender.tag] {
      onEvent?("actionTap", ["id": id])
    }
  }

  // MARK: - UINavigationBarDelegate

  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }

  // MARK: - UISearchBarDelegate

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    onEvent?("searchChange", ["value": searchText])
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    onEvent?("searchSubmit", ["value": searchBar.text ?? ""])
  }

  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    onEvent?("searchCancel", [:])
  }
}

// MARK: - UITabBarDelegate

extension NavBarOverlayHost: UITabBarDelegate {
  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    if let id = tabItemsById[ObjectIdentifier(item)] {
      onEvent?("tabChange", ["id": id])
    }
  }
}

// MARK: - Helpers

enum SymbolMapper {
  static func image(named symbol: String) -> UIImage? {
    if #available(iOS 13.0, *) {
      return UIImage(systemName: symbol)
    }
    return nil
  }
}

extension UIColor {
  static func fromHex(_ hex: String) -> UIColor? {
    var raw = hex
    if raw.hasPrefix("#") { raw.removeFirst() }
    guard raw.count == 6 || raw.count == 8 else { return nil }
    var value: UInt64 = 0
    guard Scanner(string: raw).scanHexInt64(&value) else { return nil }
    let r, g, b, a: CGFloat
    if raw.count == 6 {
      r = CGFloat((value >> 16) & 0xff) / 255
      g = CGFloat((value >> 8) & 0xff) / 255
      b = CGFloat(value & 0xff) / 255
      a = 1
    } else {
      a = CGFloat((value >> 24) & 0xff) / 255
      r = CGFloat((value >> 16) & 0xff) / 255
      g = CGFloat((value >> 8) & 0xff) / 255
      b = CGFloat(value & 0xff) / 255
    }
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
}
