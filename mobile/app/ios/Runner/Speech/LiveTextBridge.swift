import Flutter
import UIKit
import VisionKit

/// Bridge для Live Text — нативной OCR-фичи iOS 16+. Открывает full-screen
/// модальный VC с UIImageView, обёрнутым `ImageAnalysisInteraction`, чтобы
/// пользователь мог выделять/копировать текст с фото, набирать его как
/// номер телефона / email / адрес.
///
/// Channel: `lighchat/live_text`. Методы:
///  - `isAvailable()` → `Bool` — Live Text поддерживается устройством.
///  - `present(imageUrl)` → `Void` — открыть фуллскрин-вьюер.
///    Принимает либо `file://...` либо `http(s)://...` URL.
final class LiveTextBridge: NSObject {
  static let shared = LiveTextBridge()
  private static let logTag = "[LiveText]"

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/live_text", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      if #available(iOS 16.0, *) {
        result(ImageAnalyzer.isSupported)
      } else {
        result(false)
      }

    case "present":
      let args = call.arguments as? [String: Any] ?? [:]
      let urlString = (args["imageUrl"] as? String ?? "")
      if urlString.isEmpty {
        result(
          FlutterError(code: "invalid_url", message: "Empty imageUrl", details: nil))
        return
      }
      if #available(iOS 16.0, *) {
        Self.presentViewer(urlString: urlString, completion: result)
      } else {
        result(
          FlutterError(
            code: "unsupported_os",
            message: "Live Text requires iOS 16+",
            details: nil))
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.0, *)
  private static func presentViewer(
    urlString: String, completion: @escaping FlutterResult
  ) {
    guard let url = URL(string: urlString) else {
      completion(
        FlutterError(code: "invalid_url", message: urlString, details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let data: Data?
      if url.isFileURL {
        data = try? Data(contentsOf: url)
      } else {
        data = try? Data(contentsOf: url) // sync; ok для уже-кэшированных URL
      }
      guard let bytes = data, let image = UIImage(data: bytes) else {
        DispatchQueue.main.async {
          completion(
            FlutterError(
              code: "load_failed", message: "Couldn't load image", details: nil))
        }
        return
      }
      DispatchQueue.main.async {
        guard let root = Self.topViewController() else {
          completion(
            FlutterError(
              code: "no_root", message: "Couldn't find rootVC", details: nil))
          return
        }
        let vc = LiveTextViewerController(image: image)
        vc.modalPresentationStyle = .fullScreen
        root.present(vc, animated: true) {
          completion(nil)
        }
      }
    }
  }

  /// Самый верхний presented VC — куда надо present-ить fullscreen-модалку.
  private static func topViewController(
    base: UIViewController? = nil
  ) -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
    let root = base ?? scene?.keyWindow?.rootViewController
    if let nav = root as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = root?.presentedViewController {
      return topViewController(base: presented)
    }
    return root
  }
}

/// Простой UIViewController, который показывает изображение полно-экранно,
/// поверх него — `ImageAnalysisInteraction` для Live Text (выделение/copy/
/// data detectors). Сверху — кнопка закрытия.
@available(iOS 16.0, *)
private final class LiveTextViewerController: UIViewController {
  private let image: UIImage
  private let scroll = UIScrollView()
  private let imageView = UIImageView()
  private let interaction = ImageAnalysisInteraction()
  private let analyzer = ImageAnalyzer()

  init(image: UIImage) {
    self.image = image
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    // Скролл с пинч-зумом, как у системного quick look.
    scroll.frame = view.bounds
    scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scroll.minimumZoomScale = 1
    scroll.maximumZoomScale = 4
    scroll.delegate = self
    scroll.backgroundColor = .black
    scroll.contentInsetAdjustmentBehavior = .never
    view.addSubview(scroll)

    imageView.contentMode = .scaleAspectFit
    imageView.image = image
    imageView.isUserInteractionEnabled = true
    imageView.frame = scroll.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scroll.addSubview(imageView)
    imageView.addInteraction(interaction)

    // Анализируем изображение в фоне. `.visualLookUp` добавляет
    // распознавание объектов/растений/животных/достопримечательностей
    // (iOS показывает значок ✨ на распознанных объектах — тап → системная
    // карточка Wikipedia/PetID/etc.).
    Task.detached { [weak self] in
      guard let self = self else { return }
      do {
        var configTypes: ImageAnalyzer.AnalysisTypes = [
          .text, .machineReadableCode,
        ]
        if #available(iOS 17.0, *) {
          configTypes.insert(.visualLookUp)
        }
        let analysis = try await self.analyzer.analyze(
          self.image,
          configuration: ImageAnalyzer.Configuration(configTypes)
        )
        await MainActor.run {
          self.interaction.analysis = analysis
          // Явно перечисляем все типы. `.automatic` показывал у нас только
          // text selection, без значка ✨ Visual Look Up на распознанных
          // объектах (башни, животные, растения). На iOS 17+ добавляем
          // `.visualLookUp` и `.imageSubject` (subject lift) — тогда iOS
          // сам рисует ✨ в углу фото и подсветку объекта.
          var types: ImageAnalysisInteraction.InteractionTypes =
            [.textSelection, .dataDetectors]
          if #available(iOS 17.0, *) {
            types.insert(.visualLookUp)
            types.insert(.imageSubject)
          }
          self.interaction.preferredInteractionTypes = types
        }
      } catch {
        NSLog("%@ analysis failed: %@", "[LiveText]", "\(error)")
      }
    }

    // Кнопка закрытия — белая «X» в полупрозрачном круге.
    let close = UIButton(type: .system)
    close.setImage(
      UIImage(systemName: "xmark.circle.fill", withConfiguration:
        UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)),
      for: .normal)
    close.tintColor = UIColor.white.withAlphaComponent(0.9)
    close.translatesAutoresizingMaskIntoConstraints = false
    close.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
    view.addSubview(close)
    NSLayoutConstraint.activate([
      close.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      close.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      close.widthAnchor.constraint(equalToConstant: 36),
      close.heightAnchor.constraint(equalToConstant: 36),
    ])
  }

  @objc private func closeTap() {
    dismiss(animated: true)
  }
}

@available(iOS 16.0, *)
extension LiveTextViewerController: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}
