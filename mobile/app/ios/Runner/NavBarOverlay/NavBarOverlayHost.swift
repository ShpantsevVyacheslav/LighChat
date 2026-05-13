import Flutter
import UIKit

// CompactTabBar убран: override `safeAreaInsets` не работает —
// UITabBar читает inset из superview.safeAreaInsets, а не из self.
// Вернулись к Apple-стандартной геометрии (bar.height = 49 + safeArea,
// items в верхних 49pt над home indicator).

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
  private var avatarInitialLabel: UILabel?
  private var cachedAvatarImage: UIImage?

  /// Идемпотентность bottom bar: одинаковый набор items (по id+label) не
  /// перестраивается заново — только обновляется `selectedItem`. Это
  /// убирает «прыгающий пузырь» selected-state на iOS 26 при tab-switch'е,
  /// когда observer hide/show циклит между табами-экранами.
  private var lastBottomBarItemsSignature: String = ""

  /// Ref на top constraint top bar'а — динамически обновляется в
  /// updateSafeAreaInsets() для компенсации circular feedback:
  /// `additionalSafeAreaInsets.top` РАСШИРЯЕТ safeAreaLayoutGuide.topAnchor,
  /// а bar.top к нему привязан → bar толкается вниз вместе с safeArea.
  /// Без компенсации шапка оказывается ~30pt ниже expected'а.
  private var topBarTopConstraint: NSLayoutConstraint?

  // bottom bar: НЕ привязываем к safeAreaLayoutGuide.bottomAnchor.
  // Pin'им жёстко к view.bottomAnchor с фиксированной высотой 49pt —
  // items сядут впритык над home indicator (Telegram/Instagram style),
  // home indicator gesture zone частично перекрывается, но Apple это
  // не запрещает (только discourages).

  // MARK: - Eventing

  var onEvent: ((String, [String: Any]) -> Void)?

  /// NSLog wrapper с префиксом для удобной фильтрации в Console.app:
  ///   `[NavBarOverlay] ...`
  /// Включается флагом `debugLog`. В production можно выключить.
  static func log(_ message: String) {
    guard debugLog else { return }
    NSLog("[NavBarOverlay] %@", message)
  }

  // MARK: - Setup

  /// Стандартная высота контента UITabBar / UINavigationBar. Apple использует
  /// эти же константы внутри UITabBarController / UINavigationController.
  /// Top bar поднят до 56pt чтобы avatar 36×36 + title + subtitle помещались
  /// без обрезки (iOS 26 Liquid Glass).
  private static let tabBarContentHeight: CGFloat = 49
  /// Высота nav bar'а. 48pt — title pill 44pt + 2pt margin сверху/снизу.
  /// Apple's barButtonItem pills (back, search-video-phone group) на
  /// iOS 26 рендерятся ~44pt — title pill подгоняем под этот размер.
  private static let navBarContentHeight: CGFloat = 48
  /// Насколько сместить ВЕСЬ tab bar вниз относительно view.bottom.
  /// Apple Photos / iOS 26 apps кладут items в safe-area zone (gap
  /// ~15-20pt от низа экрана). UITabBar по-стандарту сидит над safe
  /// area (gap 34pt — большой). Положительный overlap двигает
  /// bar.frame ниже screen edge.
  /// 16pt overlap → gap items-bottom до screen-bottom = 18pt.
  private static let tabBarBottomOverlap: CGFloat = 16
  /// Отступ bar.top от safeArea.top. ОТРИЦАТЕЛЬНЫЙ — поднимаем bar в
  /// system-reserved area под Dynamic Island. Apple оставляет ~22pt
  /// clearance под DI; -8pt пробивает половину этого «воздуха», items
  /// визуально ближе к DI как у Telegram. Items при этом не клипятся
  /// (DI overlays, не cuts).
  private static let navBarTopGap: CGFloat = -8
  /// Структурное логирование для отладки overlay'я. Включается через
  /// `defaults write … NavBarOverlayDebug 1` или хардкодом ниже.
  private static let debugLog: Bool = true

  func attach(to vc: UIViewController) {
    flutterVC = vc

    let top = UINavigationBar(frame: .zero)
    top.translatesAutoresizingMaskIntoConstraints = false
    top.delegate = self
    top.isHidden = true
    // Минимальные боковые отступы — back прижат к левому краю, actions
    // к правому. Освобождает центр для title pill (avatar+name+subtitle).
    top.directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: 0, leading: 4, bottom: 0, trailing: 4)
    top.preservesSuperviewLayoutMargins = false
    LiquidGlassAppearance.applyNavigationBar(top, tint: .systemBlue)

    let bottom = UITabBar(frame: .zero)
    bottom.translatesAutoresizingMaskIntoConstraints = false
    bottom.delegate = self
    bottom.isHidden = true
    LiquidGlassAppearance.applyTabBar(bottom, tint: .systemBlue)

    vc.view.addSubview(top)
    vc.view.addSubview(bottom)

    // Top constraint храним по ref'у — будем обновлять constant в
    // updateSafeAreaInsets() для компенсации circular feedback с
    // additionalSafeAreaInsets.top.
    let topC = top.topAnchor.constraint(
      equalTo: vc.view.safeAreaLayoutGuide.topAnchor,
      constant: Self.navBarTopGap)
    topBarTopConstraint = topC

    NSLayoutConstraint.activate([
      top.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
      top.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
      topC,
      top.heightAnchor.constraint(equalToConstant: Self.navBarContentHeight),

      bottom.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
      bottom.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
      // Bar смещён вниз на `tabBarBottomOverlap` — часть его frame'а
      // уезжает ниже view.bottom (за пределы экрана). Items рендерятся
      // в верхних 49pt frame'а, и вместе с bar'ом спускаются ближе к
      // home indicator. Apple Photos / iOS 26 native pattern.
      bottom.bottomAnchor.constraint(
        equalTo: vc.view.bottomAnchor,
        constant: Self.tabBarBottomOverlap),
      bottom.topAnchor.constraint(
        equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor,
        constant: -Self.tabBarContentHeight + Self.tabBarBottomOverlap),
    ])

    Self.log(
      "attach: topBar/bottomBar добавлены к flutterVC.view, height: top=\(Self.navBarContentHeight) bottom=\(Self.tabBarContentHeight)"
    )

    self.topBar = top
    self.bottomBar = bottom
  }

  // MARK: - Public API (called by NavBarBridge)

  func applyTopBar(_ config: [String: Any]) {
    guard let bar = topBar else {
      Self.log("applyTopBar: topBar==nil (attach не вызван?)")
      return
    }
    let visible = config["visible"] as? Bool ?? true
    topVisible = visible
    Self.log("applyTopBar visible=\(visible) searchActive=\(searchActive)")
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
    guard let bar = bottomBar else {
      Self.log("applyBottomBar: bottomBar==nil")
      return
    }
    let visible = config["visible"] as? Bool ?? true
    bottomVisible = visible
    let configs = config["items"] as? [[String: Any]] ?? []
    let selectedId = config["selectedId"] as? String ?? ""

    // Сигнатура items: id+label+icon. Если совпадает с прошлой —
    // переключаем только `selectedItem` (Apple анимирует pill smoothly),
    // НЕ пересоздаём UITabBarItem'ы. Решает «прыгающий пузырь» при
    // переходе между табами /chats↔/contacts↔/calls↔/meetings, где
    // items идентичны.
    let signature = configs.map { cfg -> String in
      let id = cfg["id"] as? String ?? ""
      let label = cfg["label"] as? String ?? ""
      let symbol = (cfg["icon"] as? [String: Any])?["symbol"] as? String ?? ""
      return "\(id)/\(label)/\(symbol)"
    }.joined(separator: "|")

    Self.log("applyBottomBar visible=\(visible) itemsCount=\(configs.count) selectedId=\(selectedId) signatureEq=\(signature == lastBottomBarItemsSignature)")

    if !visible {
      // ВАЖНО: НЕ очищаем bar.items при hide — это рвало бы pill-анимацию,
      // когда сразу следом приходит show с тем же набором (наш typical
      // tab-switch flow: observer hide → новый экран show).
      bar.isHidden = true
      updateSafeAreaInsets()
      return
    }

    bar.isHidden = false

    if signature == lastBottomBarItemsSignature,
      let existingItems = bar.items, !existingItems.isEmpty {
      // Same set — только переключаем selectedItem с animation.
      let newSelected = existingItems.first(where: { item in
        tabItemsById[ObjectIdentifier(item)] == selectedId
      })
      if let sel = newSelected, bar.selectedItem !== sel {
        bar.selectedItem = sel
      }
      updateSafeAreaInsets()
      return
    }

    lastBottomBarItemsSignature = signature
    tabItemsById.removeAll(keepingCapacity: true)

    var items: [UITabBarItem] = []
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
    Self.log("applySearch active=\(active) wasActive=\(wasActive) value.len=\(value.count) topItem!=nil:\(topItem != nil)")

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

    // Активация / обновление: выставляем UISearchBar в titleView. Built-in
    // Cancel button на iOS 26 рендерится неконсистентно и иногда не
    // приходит в делегат — вместо него ставим явный UIBarButtonItem
    // справа с X-иконкой, и шлём searchCancel оттуда.
    let bar = searchBar ?? UISearchBar()
    bar.placeholder = placeholder
    bar.searchBarStyle = .minimal
    bar.showsCancelButton = false
    bar.delegate = self
    if bar.text != value { bar.text = value }
    bar.translatesAutoresizingMaskIntoConstraints = false

    // Cancel-X. По user-feedback'у: убираем заливку circle ('xmark.circle.fill'
    // выглядел «белым кругом») — берём чистый `xmark` cross без круга,
    // белый, с увеличенным point-size для тачабельности.
    let cancelImage: UIImage? = {
      if #available(iOS 13.0, *) {
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        return UIImage(systemName: "xmark", withConfiguration: cfg)
      }
      return SymbolMapper.image(named: "xmark")
    }()
    let cancelView = UIButton(type: .system)
    cancelView.setImage(cancelImage, for: .normal)
    cancelView.tintColor = .white
    cancelView.backgroundColor = .clear
    if #available(iOS 15.0, *) {
      // UIButton.Configuration.plain — без background pill / Liquid Glass.
      cancelView.configuration = .plain()
      cancelView.configuration?.contentInsets = NSDirectionalEdgeInsets(
        top: 0, leading: 0, bottom: 0, trailing: 0)
      // baseForegroundColor нужен начиная с iOS 15 — без него .plain()
      // может перекрыть tintColor.
      cancelView.configuration?.baseForegroundColor = .white
    }
    cancelView.addTarget(
      self,
      action: #selector(onExplicitSearchCancel),
      for: .touchUpInside)
    cancelView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
    let cancelBtn = UIBarButtonItem(customView: cancelView)

    topItem?.titleView = bar
    topItem?.title = nil
    topItem?.rightBarButtonItems = [cancelBtn]
    searchBar = bar

    // Принудительная layout-pass до becomeFirstResponder: без неё UIKit
    // иногда не успевает положить searchBar в window-hierarchy.
    topBar?.setNeedsLayout()
    topBar?.layoutIfNeeded()

    if !wasActive {
      // Несколько попыток сделать searchBar first responder. На iOS 26
      // одной попытки часто недостаточно — UISearchBar внутри
      // UINavigationItem.titleView долго инициализирует backing window.
      attemptFocusSearch(retries: 8)
    }
  }

  private func attemptFocusSearch(retries: Int) {
    guard retries > 0 else {
      Self.log("attemptFocusSearch: исчерпан лимит попыток, клавиатура не открылась")
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
      guard let self = self, let bar = self.searchBar else { return }
      if !self.searchActive {
        Self.log("attemptFocusSearch: searchActive=false, пропускаем")
        return
      }
      let inWindow = bar.window != nil
      let canFocus: Bool = {
        if #available(iOS 13.0, *) {
          return bar.searchTextField.canBecomeFirstResponder
        }
        return bar.canBecomeFirstResponder
      }()
      Self.log("attemptFocusSearch try=\(8 - retries + 1) inWindow=\(inWindow) canFocus=\(canFocus)")
      guard inWindow, canFocus else {
        self.attemptFocusSearch(retries: retries - 1)
        return
      }
      let became: Bool
      if #available(iOS 13.0, *) {
        became = bar.searchTextField.becomeFirstResponder()
      } else {
        became = bar.becomeFirstResponder()
      }
      Self.log("attemptFocusSearch became=\(became)")
      if !became { self.attemptFocusSearch(retries: retries - 1) }
    }
  }

  @objc private func onExplicitSearchCancel() {
    Self.log("onExplicitSearchCancel: X tapped")
    onEvent?("searchCancel", [:])
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
    // Telegram-style: avatar+title+subtitle ВНУТРИ Liquid Glass пилюли,
    // которая визуально такая же, как pill'ы у back/search/video items'ов
    // (их iOS 26 рендерит сам). Без backing-фона текст «терялся» на
    // полупрозрачном чате.
    let pill: UIView
    if #available(iOS 13.0, *) {
      let visual = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemThinMaterial))
      visual.translatesAutoresizingMaskIntoConstraints = false
      visual.layer.cornerRadius = 22  // = height/2 для full pill (44pt)
      visual.layer.masksToBounds = true
      pill = visual
    } else {
      let v = UIView()
      v.translatesAutoresizingMaskIntoConstraints = false
      v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.65)
      v.layer.cornerRadius = 22
      v.layer.masksToBounds = true
      pill = v
    }
    // Container = inner content area под padding'ом pill'а.
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    // Аватар + имя должны кликаться — отдают actionTap("_chat_title_tap")
    // обратно в Flutter; ChatHeader маппит на onProfileTap.
    container.isUserInteractionEnabled = true
    let tap = UITapGestureRecognizer(target: self, action: #selector(onTitleTap))
    container.addGestureRecognizer(tap)
    pill.isUserInteractionEnabled = true
    let pillTap = UITapGestureRecognizer(
      target: self, action: #selector(onTitleTap))
    pill.addGestureRecognizer(pillTap)

    let contentHost: UIView = {
      if let vfx = pill as? UIVisualEffectView {
        return vfx.contentView
      }
      return pill
    }()
    contentHost.addSubview(container)
    NSLayoutConstraint.activate([
      container.leadingAnchor.constraint(
        equalTo: contentHost.leadingAnchor, constant: 4),
      container.trailingAnchor.constraint(
        equalTo: contentHost.trailingAnchor, constant: -10),
      container.topAnchor.constraint(equalTo: contentHost.topAnchor),
      container.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor),
    ])

    let avatar = UIImageView()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.layer.cornerRadius = 17  // half of 34 для round avatar
    avatar.layer.masksToBounds = true
    avatar.contentMode = .scaleAspectFill
    // Fallback fill: solid 0xFF18357C (тот же start-цвет Flutter
    // ChatAvatar gradient dark mode). Solid вместо CAGradientLayer —
    // gradient.frame не успевал под auto-layout и рисовался не на месте
    // (выглядел как светло-голубой круг вместо тёмно-синего).
    avatar.backgroundColor = UIColor(
      red: 0x18 / 255.0, green: 0x35 / 255.0, blue: 0x7C / 255.0, alpha: 1)

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
    initialLabel.font = .systemFont(ofSize: 13, weight: .heavy)
    initialLabel.textAlignment = .center
    initialLabel.textColor = .white
    // КЛЮЧЕВО: initialLabel прячется, если уже есть image (cached или
    // только что переданный). Иначе он рисуется ПОВЕРХ avatar.image и
    // буква перекрывает фото.
    initialLabel.isHidden = avatar.image != nil
    avatar.addSubview(initialLabel)
    avatarInitialLabel = initialLabel

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
      // Avatar 34×34, pill 44 — точно совпадает с Apple's iOS 26
      // barButtonItem pills (back / search-video-phone group).
      avatar.widthAnchor.constraint(equalToConstant: 34),
      avatar.heightAnchor.constraint(equalToConstant: 34),
      avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),

      initialLabel.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      initialLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

      textStack.leadingAnchor.constraint(
        equalTo: avatar.trailingAnchor, constant: 8),
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

    if let raw = avatarUrl, !raw.isEmpty {
      if let url = URL(string: raw) {
        Self.log("makeTitleView avatarUrl='\(raw)' → URL parsed OK")
        // Уже загружали этот URL → отдаём из кэша, без сетевого запроса.
        if lastAvatarUrl == url, let cached = cachedAvatarImage {
          avatar.image = cached
        } else {
          lastAvatarUrl = url
          cachedAvatarImage = nil
          loadAvatar(url: url, into: avatar)
        }
      } else {
        Self.log("makeTitleView avatarUrl='\(raw)' → URL parse FAILED")
        lastAvatarUrl = nil
        cachedAvatarImage = nil
      }
    } else {
      // URL не задан → сбрасываем кэш, чтобы при возврате аватара его
      // перезагрузили.
      Self.log("makeTitleView avatarUrl is nil/empty → using fallback gradient + initial")
      lastAvatarUrl = nil
      cachedAvatarImage = nil
    }

    return pill
  }

  private func loadAvatar(url: URL, into imageView: UIImageView) {
    if avatarTasks[url] != nil {
      Self.log("loadAvatar already in flight: \(url.absoluteString)")
      return
    }
    Self.log("loadAvatar START \(url.absoluteString)")
    let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard let self = self else { return }
      let status = (response as? HTTPURLResponse)?.statusCode ?? -1
      let bytes = data?.count ?? 0
      let errDescr = error.map { String(describing: $0) } ?? "nil"
      DispatchQueue.main.async {
        self.avatarTasks[url] = nil
        guard self.lastAvatarUrl == url else {
          Self.log("loadAvatar FINISH url stale (current=\(self.lastAvatarUrl?.absoluteString ?? "nil")), drop")
          return
        }
        guard let data = data, let image = UIImage(data: data) else {
          Self.log("loadAvatar FINISH FAILED status=\(status) bytes=\(bytes) err=\(errDescr)")
          return
        }
        Self.log("loadAvatar FINISH OK status=\(status) bytes=\(bytes)")
        self.cachedAvatarImage = image
        imageView.image = image
        // Скрываем initial-букву под фото.
        self.avatarInitialLabel?.isHidden = true
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
    // ВАЖНО: insets.top = 0 — Flutter content рисует во всю высоту view,
    // status bar items + наши pills overlay'ются сверху на контент. При
    // скролле messages и date-tag проходят под прозрачной пилюлей шапки
    // (Telegram-эффект). Раньше insets.top = 32 → контент cut'ился у
    // safeArea-границы.
    // ВАЖНО: insets.bottom = 0 даже когда tab bar виден. Контент Flutter
    // (списки чатов/звонков, сообщения чата) рисуется до view.bottom-34
    // (system home indicator), и items tab bar'а наезжают сверху с
    // прозрачным glass-фоном. Apple Photos pattern — последние items
    // частично видны под bar'ом, полностью открываются при scroll'е.
    // Flutter-сторона должна добавить bottom-padding (≈ tabBar content +
    // overlap) на свои ListView'ы, чтобы пользователь мог проскроллить
    // последнюю запись выше bar'а.
    vc.additionalSafeAreaInsets = insets

    // КОМПЕНСАЦИЯ circular feedback для TOP bar:
    // additionalSafeAreaInsets.top сдвигает safeAreaLayoutGuide.topAnchor
    // вниз на insets.top. bar.topConstraint к нему привязан — без
    // коррекции bar едет вниз вместе с safeArea. Восстанавливаем абсолютную
    // позицию bar.top = originalSafeArea + navBarTopGap.
    topBarTopConstraint?.constant = Self.navBarTopGap - insets.top

    // НЕ компенсируем bottom bar: UITabBar полагается на собственный
    // расчёт safeAreaInsets для позиционирования items'ов. Apple ожидает,
    // что bar.frame заходит ДО view.bottom (включая home indicator zone),
    // а items рендерятся в верхних `tabBarContentHeight` pt frame'а.
    // Compensation роняла items за пределы видимой области.
    Self.log(
      "updateSafeAreaInsets insets.top=\(insets.top) topConst=\(Self.navBarTopGap - insets.top) insets.bottom=\(insets.bottom)"
    )
  }

  // MARK: - Targets

  @objc private func onLeadingTap() {
    onEvent?("leadingTap", ["id": leadingId])
  }

  @objc private func onTitleTap() {
    // Тап по avatar/title/subtitle. Flutter маппит этот id в onProfileTap.
    onEvent?("actionTap", ["id": "_chat_title_tap"])
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
