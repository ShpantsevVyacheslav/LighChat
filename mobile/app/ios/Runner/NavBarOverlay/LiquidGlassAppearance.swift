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
    let appearance = UINavigationBarAppearance()
    let glassApplied = enableGlassEffectIfAvailable(on: appearance)
    if !glassApplied {
      appearance.configureWithDefaultBackground()
    }
    bar.standardAppearance = appearance
    bar.scrollEdgeAppearance = appearance
    bar.compactAppearance = appearance
    if #available(iOS 15.0, *) {
      bar.compactScrollEdgeAppearance = appearance
    }
    return glassApplied
  }

  @discardableResult
  static func applyTabBar(_ bar: UITabBar, tint: UIColor) -> Bool {
    bar.tintColor = tint
    let appearance = UITabBarAppearance()
    let glassApplied = enableGlassEffectIfAvailable(on: appearance)
    if !glassApplied {
      appearance.configureWithDefaultBackground()
    }
    bar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      bar.scrollEdgeAppearance = appearance
    }
    return glassApplied
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
