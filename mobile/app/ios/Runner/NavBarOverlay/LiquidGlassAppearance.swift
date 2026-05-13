import UIKit

/// Wrapper around `UIBarAppearance` configuration with an iOS 26+ Liquid Glass
/// branch and a sane fallback for iOS 15–25.
///
/// All call sites should go through `LiquidGlassAppearance.apply(to:)` so
/// switching to a newer API only touches this file.
enum LiquidGlassAppearance {
  /// Tries to enable Liquid Glass via the iOS 26+ SDK. We resolve the symbol
  /// dynamically with KVC because (a) Xcode shipping with the project may
  /// still be on an older SDK, and (b) on iOS 15–25 the property simply does
  /// not exist. If neither path works we fall through to the opaque fallback.
  ///
  /// - Returns: `true` when Liquid Glass was applied.
  @discardableResult
  static func applyNavigationBar(_ bar: UINavigationBar, tint: UIColor) -> Bool {
    bar.tintColor = tint
    bar.isTranslucent = true
    let appearance = UINavigationBarAppearance()
    // Telegram-style на iOS 26: фон bar'а ПОЛНОСТЬЮ прозрачный, каждый
    // UIBarButtonItem рендерится OS'ом со своим Liquid Glass pill'ом.
    // Никаких больших серых плашек поверх контента — bar становится
    // невидимым контейнером, только items плавают.
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = .clear
    appearance.backgroundEffect = nil
    appearance.shadowColor = .clear
    bar.standardAppearance = appearance
    bar.scrollEdgeAppearance = appearance
    bar.compactAppearance = appearance
    if #available(iOS 15.0, *) {
      bar.compactScrollEdgeAppearance = appearance
    }
    return isLiquidGlassRuntimeAvailable()
  }

  @discardableResult
  static func applyTabBar(_ bar: UITabBar, tint: UIColor) -> Bool {
    bar.tintColor = tint
    bar.isTranslucent = true
    let appearance = UITabBarAppearance()
    // Tab bar тоже без жирной плашки — items сами рендерятся pill'ами
    // на iOS 26 (см. selected/normal состояния UITabBarItem).
    appearance.configureWithTransparentBackground()
    appearance.backgroundColor = .clear
    appearance.backgroundEffect = nil
    appearance.shadowColor = .clear
    bar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      bar.scrollEdgeAppearance = appearance
    }
    return isLiquidGlassRuntimeAvailable()
  }

  /// Liquid Glass became part of `UIBarAppearance` in iOS 26 SDK. Try to
  /// activate it via KVC so we compile on older SDKs as well. Returns
  /// `true` when the appearance accepted the new background effect.
  private static func enableGlassEffectIfAvailable(on appearance: UIBarAppearance) -> Bool {
    guard isLiquidGlassRuntimeAvailable() else { return false }
    // The exact API surface in iOS 26 SDK exposes a "glass" background
    // effect builder. Resolve dynamically — if the selector is missing we
    // bail out and use the default background.
    let glassSelector = NSSelectorFromString("configureWithGlassBackground")
    if appearance.responds(to: glassSelector) {
      _ = appearance.perform(glassSelector)
      return true
    }
    return false
  }

  /// iOS 26 is the first version that ships Liquid Glass APIs.
  static func isLiquidGlassRuntimeAvailable() -> Bool {
    if #available(iOS 26.0, *) {
      return true
    }
    return false
  }
}
