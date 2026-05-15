import Flutter
import Foundation
import UIKit
import VisionKit

/// Bridge для нативного сканера документов (VisionKit
/// `VNDocumentCameraViewController`, iOS 13+).
///
/// Channel: `lighchat/document_scanner`. Методы:
///  - `isAvailable()` — `true`, если `VNDocumentCameraViewController.isSupported`
///  - `scan()` — открывает камеру, делает edge-detection + perspective
///    correction, возвращает список путей к JPEG-файлам в tmp-директории.
///    Junk-страницы пользователь удаляет в нативном UI; результат —
///    только подтверждённые страницы.
///
/// Возвращаемые пути живут в tmp/ — caller сам их перемещает в
/// постоянное хранилище (или в Firebase Storage) и удаляет после.
final class DocumentScannerBridge: NSObject {
  static let shared = DocumentScannerBridge()

  private var pendingResult: FlutterResult?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "lighchat/document_scanner", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call: call, result: result)
    }
  }

  private func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(VNDocumentCameraViewController.isSupported)

    case "scan":
      guard VNDocumentCameraViewController.isSupported else {
        result(FlutterError(code: "unsupported",
                            message: "Device does not support document scanning",
                            details: nil))
        return
      }
      guard pendingResult == nil else {
        result(FlutterError(code: "busy",
                            message: "Another scan is already in progress",
                            details: nil))
        return
      }
      pendingResult = result
      DispatchQueue.main.async { [weak self] in
        self?.presentScanner()
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentScanner() {
    guard let root = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?
      .rootViewController?.topMostViewController()
    else {
      finish(with: FlutterError(code: "no_root",
                                message: "No root view controller",
                                details: nil))
      return
    }
    let vc = VNDocumentCameraViewController()
    vc.delegate = self
    vc.modalPresentationStyle = .fullScreen
    root.present(vc, animated: true)
  }

  private func finish(with payload: Any?) {
    let r = pendingResult
    pendingResult = nil
    r?(payload)
  }
}

extension DocumentScannerBridge: VNDocumentCameraViewControllerDelegate {
  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFinishWith scan: VNDocumentCameraScan
  ) {
    let tmp = NSTemporaryDirectory()
    let stamp = Int(Date().timeIntervalSince1970 * 1000)
    var paths: [String] = []
    for i in 0..<scan.pageCount {
      let img = scan.imageOfPage(at: i)
      guard let data = img.jpegData(compressionQuality: 0.86) else { continue }
      let path = "\(tmp)scan_\(stamp)_\(i).jpg"
      do {
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        paths.append(path)
      } catch {
        // skip page on write failure but keep going
      }
    }
    controller.dismiss(animated: true) { [weak self] in
      self?.finish(with: paths)
    }
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true) { [weak self] in
      self?.finish(with: [])
    }
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController,
    didFailWithError error: Error
  ) {
    controller.dismiss(animated: true) { [weak self] in
      self?.finish(with: FlutterError(
        code: "scan_failed",
        message: error.localizedDescription,
        details: nil))
    }
  }
}

private extension UIViewController {
  func topMostViewController() -> UIViewController {
    if let presented = presentedViewController {
      return presented.topMostViewController()
    }
    if let nav = self as? UINavigationController, let top = nav.topViewController {
      return top.topMostViewController()
    }
    if let tab = self as? UITabBarController, let sel = tab.selectedViewController {
      return sel.topMostViewController()
    }
    return self
  }
}
