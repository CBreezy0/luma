import CoreImage
import Foundation

/// Placeholder for future LUT-backed look support.
final class LumaLUTLoader {
  static let shared = LumaLUTLoader()

  private init() {}

  func colorCubeFilter(named _: String, intensity _: Double) -> CIFilter? {
    return nil
  }
}
