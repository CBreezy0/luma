import CoreImage
import UIKit

enum LumaPreviewProcessingMode {
  case standard
  case reduced

  var shouldComputeHistogram: Bool {
    switch self {
    case .standard:
      return true
    case .reduced:
      return false
    }
  }
}

/// Dedicated preview processing pipeline.
///
/// Stage order:
/// 1. light neutral tone mapping
/// 2. creative look transform
/// 3. preview output (no still-only sharpening or grain)
final class LumaPreviewProcessor {
  private let ciContext: CIContext
  private let filmPipeline: LumaFilmRenderPipeline

  init(ciContext: CIContext, lutLoader: LumaLUTLoader = .shared) {
    self.ciContext = ciContext
    filmPipeline = LumaFilmRenderPipeline(mode: .preview, lutLoader: lutLoader)
  }

  func processPreviewFrame(
    _ image: CIImage,
    simulationId: String,
    simulationIntensity: Double,
    lookStrength: Double,
    applyEnhancement: Bool,
    processingMode: LumaPreviewProcessingMode
  ) -> CIImage {
    let effectiveEnhancement = applyEnhancement && processingMode == .standard
    let effectiveLookStrength = processingMode == .reduced
      ? min(lookStrength, 0.9)
      : lookStrength
    return filmPipeline.render(
      image,
      simulationId: simulationId,
      simulationIntensity: simulationIntensity,
      lookStrength: effectiveLookStrength,
      allowEnhancement: effectiveEnhancement,
      shouldDenoise: false
    )
  }

  func makePreviewImage(from image: CIImage) -> UIImage? {
    guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
      return nil
    }
    return UIImage(cgImage: cgImage)
  }
}
