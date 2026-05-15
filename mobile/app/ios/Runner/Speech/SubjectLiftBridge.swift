import Flutter
import Foundation
import UIKit
import VisionKit

/// Bridge для нативного Subject Lift (iOS 17+ VisionKit). Открывает
/// изображение фуллскрин с `ImageAnalysisInteraction`; пользователь
/// долгим тапом на объект → iOS извлекает subject (вырезает из фона),
/// мы получаем `UIImage` и сохраняем PNG в tmp/.
///
/// Channel: `lighchat/subject_lift`. Методы:
///  - `isAvailable()` → `Bool` — `iOS 17+` + `ImageAnalyzer.isSupported`
///  - `lift(imageUrl)` → `String?` — путь к PNG, или `nil` если отменил
final class SubjectLiftBridge: NSObject {
  static let shared = SubjectLiftBridge()

  private var pendingResult: FlutterResult?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/subject_lift", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      if #available(iOS 17.0, *) {
        result(ImageAnalyzer.isSupported)
      } else {
        result(false)
      }

    case "lift":
      guard #available(iOS 17.0, *) else {
        result(FlutterError(
          code: "unsupported_os",
          message: "Subject Lift requires iOS 17+",
          details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let urlString = (args["imageUrl"] as? String ?? "")
      if urlString.isEmpty {
        result(FlutterError(
          code: "invalid_url", message: "Empty imageUrl", details: nil))
        return
      }
      if pendingResult != nil {
        result(FlutterError(
          code: "busy",
          message: "Another lift is already in progress",
          details: nil))
        return
      }
      pendingResult = result
      Self.presentLifter(urlString: urlString) { [weak self] payload in
        let r = self?.pendingResult
        self?.pendingResult = nil
        r?(payload)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 17.0, *)
  private static func presentLifter(
    urlString: String, completion: @escaping (Any?) -> Void
  ) {
    guard let url = URL(string: urlString) else {
      completion(FlutterError(
        code: "invalid_url", message: urlString, details: nil))
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let data: Data? = try? Data(contentsOf: url)
      guard let bytes = data, let image = UIImage(data: bytes) else {
        DispatchQueue.main.async {
          completion(FlutterError(
            code: "load_failed",
            message: "Couldn't load image",
            details: nil))
        }
        return
      }
      DispatchQueue.main.async {
        guard let root = topViewController() else {
          completion(FlutterError(
            code: "no_root", message: "No root VC", details: nil))
          return
        }
        let vc = SubjectLiftViewController(image: image, completion: completion)
        vc.modalPresentationStyle = .fullScreen
        root.present(vc, animated: true)
      }
    }
  }

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

@available(iOS 17.0, *)
private final class SubjectLiftViewController: UIViewController {
  private let image: UIImage
  private let completion: (Any?) -> Void
  private let imageView = UIImageView()
  private let interaction = ImageAnalysisInteraction()
  private let analyzer = ImageAnalyzer()
  private var didFinish = false

  // Подсказка-pill сверху + индикатор пока идёт анализ.
  private let hintLabel = UILabel()
  private let spinner = UIActivityIndicatorView(style: .medium)

  init(image: UIImage, completion: @escaping (Any?) -> Void) {
    self.image = image
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    imageView.frame = view.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.contentMode = .scaleAspectFit
    imageView.image = image
    imageView.isUserInteractionEnabled = true
    view.addSubview(imageView)

    interaction.preferredInteractionTypes = .imageSubject
    imageView.addInteraction(interaction)

    // Тап в произвольную точку → пытаемся вытащить subject под тапом.
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tap.numberOfTapsRequired = 1
    imageView.addGestureRecognizer(tap)

    // Hint pill.
    hintLabel.text = "Анализ изображения…"
    hintLabel.textColor = UIColor.white.withAlphaComponent(0.95)
    hintLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    hintLabel.textAlignment = .center
    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    let hintBg = UIView()
    hintBg.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    hintBg.layer.cornerRadius = 18
    hintBg.layer.cornerCurve = .continuous
    hintBg.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hintBg)
    hintBg.addSubview(hintLabel)
    spinner.color = .white
    spinner.translatesAutoresizingMaskIntoConstraints = false
    hintBg.addSubview(spinner)
    spinner.startAnimating()

    NSLayoutConstraint.activate([
      hintBg.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      hintBg.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      hintBg.heightAnchor.constraint(equalToConstant: 36),
      spinner.leadingAnchor.constraint(
        equalTo: hintBg.leadingAnchor, constant: 14),
      spinner.centerYAnchor.constraint(equalTo: hintBg.centerYAnchor),
      hintLabel.leadingAnchor.constraint(
        equalTo: spinner.trailingAnchor, constant: 8),
      hintLabel.trailingAnchor.constraint(
        equalTo: hintBg.trailingAnchor, constant: -14),
      hintLabel.centerYAnchor.constraint(equalTo: hintBg.centerYAnchor),
    ])

    // Кнопка close.
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
      close.leadingAnchor.constraint(
        equalTo: view.leadingAnchor, constant: 8),
      close.widthAnchor.constraint(equalToConstant: 44),
      close.heightAnchor.constraint(equalToConstant: 44),
    ])

    Task.detached { [weak self] in
      guard let self = self else { return }
      do {
        let analysis = try await self.analyzer.analyze(
          self.image,
          configuration: ImageAnalyzer.Configuration([.visualLookUp]))
        // interaction.analysis нужно ставить на main; subjects — async
        // property, читаем её на main thread после установки analysis.
        await MainActor.run {
          self.interaction.analysis = analysis
        }
        let subjects = await self.interaction.subjects
        await MainActor.run {
          self.spinner.stopAnimating()
          self.spinner.isHidden = true
          self.hintLabel.text = subjects.isEmpty
            ? "Объекты не найдены"
            : "Нажми на объект чтобы вырезать"
        }
      } catch {
        await MainActor.run {
          self.spinner.stopAnimating()
          self.spinner.isHidden = true
          self.hintLabel.text = "Не удалось проанализировать"
        }
      }
    }
  }

  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    let point = recognizer.location(in: imageView)
    // Точка в координатах imageView — `ImageAnalysisInteraction.subject(at:)`
    // сам конвертит coord в координаты самого image (учитывая letterbox от
    // contentMode .scaleAspectFit).
    Task { [weak self] in
      guard let self = self else { return }
      let subject = await self.interaction.subject(at: point)
      guard let subject = subject else {
        await MainActor.run {
          self.hintLabel.text = "Тут нет объекта — нажми на другой"
        }
        return
      }
      do {
        let lifted = try await subject.image
        await MainActor.run { self.finish(with: lifted) }
      } catch {
        await MainActor.run {
          self.hintLabel.text = "Не удалось вырезать объект"
        }
      }
    }
  }

  private func finish(with image: UIImage) {
    guard !didFinish else { return }
    didFinish = true
    let path = NSTemporaryDirectory()
      + "subject_lift_\(Int(Date().timeIntervalSince1970 * 1000)).png"
    guard let data = image.pngData() else {
      dismiss(animated: true) { [self] in completion(nil) }
      return
    }
    do {
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
      dismiss(animated: true) { [self] in completion(path) }
    } catch {
      dismiss(animated: true) { [self] in completion(nil) }
    }
  }

  @objc private func closeTap() {
    guard !didFinish else { return }
    didFinish = true
    dismiss(animated: true) { [self] in completion(nil) }
  }
}
