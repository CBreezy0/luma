import CoreImage
import Foundation

enum LumaFilmSimulation {
  static let defaultSimulationId = "slate"

  static let supportedSimulationIds: Set<String> = [
    "slate",
    "ember",
    "bloom",
    "drift",
    "vale",
    "mono",
  ]

  static func apply(
    simulationId: String,
    to image: CIImage,
    intensity: Double,
    strength: Double,
    lutLoader: LumaLUTLoader = .shared
  ) -> CIImage {
    let id = supportedSimulationIds.contains(simulationId)
      ? simulationId
      : defaultSimulationId
    let lookStrength = clamp01(strength)
    if lookStrength < 0.0001 { return image }

    let t = clamp01(intensity)
    if t < 0.0001 { return image }

    var out: CIImage
    switch id {
    case "ember":
      out = ember(image: image, t: t)
    case "bloom":
      out = bloom(image: image, t: t)
    case "drift":
      out = drift(image: image, t: t)
    case "vale":
      out = vale(image: image, t: t)
    case "mono":
      out = mono(image: image, t: t)
    default:
      out = slate(image: image, t: t)
    }

    // Future LUT hook without changing Dart/native API shape.
    if let lut = lutLoader.colorCubeFilter(named: id, intensity: t) {
      lut.setValue(out, forKey: kCIInputImageKey)
      if let output = lut.outputImage {
        out = output
      }
    }

    if lookStrength >= 0.9999 { return out }
    return blendWithOriginal(original: image, processed: out, strength: lookStrength)
  }

  private static func blendWithOriginal(
    original: CIImage,
    processed: CIImage,
    strength: Double
  ) -> CIImage {
    let alpha = CGFloat(clamp01(strength))
    let alphaScaled = processed.applyingFilter("CIColorMatrix", parameters: [
      "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
      "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
      "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
      "inputAVector": CIVector(x: 0, y: 0, z: 0, w: alpha),
      "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
    ])
    return alphaScaled.applyingFilter("CISourceOverCompositing", parameters: [
      kCIInputBackgroundImageKey: original,
    ])
  }

  private static func slate(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = applyHighlightShadow(out, shadows: 0.52 + 0.06 * t, highlights: 0.50 - 0.03 * t)
    out = applyColorControls(
      out,
      contrast: 1.0 + 0.10 * t,
      saturation: 1.0 - 0.05 * t,
      brightness: 0.0
    )
    out = applyToneCurve(
      out,
      p0: CGPoint(x: 0.0, y: 0.0),
      p1: CGPoint(x: 0.25, y: 0.24 + 0.02 * t),
      p2: CGPoint(x: 0.5, y: 0.5),
      p3: CGPoint(x: 0.75, y: 0.76),
      p4: CGPoint(x: 1.0, y: 1.0)
    )
    return out
  }

  private static func ember(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = applyTemperature(out, warmth: 0.22 * t, tint: 0.03 * t)
    out = applyColorControls(
      out,
      contrast: 1.0 + 0.14 * t,
      saturation: 1.0 + 0.10 * t,
      brightness: 0.0
    )
    out = applyVibrance(out, amount: 0.22 * t)
    out = applyHighlightShadow(out, shadows: 0.50 + 0.04 * t, highlights: 0.50 - 0.05 * t)
    return out
  }

  private static func bloom(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = applyColorControls(
      out,
      contrast: 1.0 - 0.08 * t,
      saturation: 1.0 - 0.03 * t,
      brightness: 0.02 * t
    )
    out = applyHighlightShadow(out, shadows: 0.50 + 0.08 * t, highlights: 0.50 - 0.10 * t)
    out = applyToneCurve(
      out,
      p0: CGPoint(x: 0.0, y: 0.03 * t),
      p1: CGPoint(x: 0.25, y: 0.28 + 0.03 * t),
      p2: CGPoint(x: 0.5, y: 0.53),
      p3: CGPoint(x: 0.75, y: 0.78 + 0.02 * t),
      p4: CGPoint(x: 1.0, y: 0.98)
    )
    return out
  }

  private static func drift(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = applyTemperature(out, warmth: -0.18 * t, tint: -0.02 * t)
    out = applyColorControls(
      out,
      contrast: 1.0 - 0.06 * t,
      saturation: 1.0 - 0.14 * t,
      brightness: 0.0
    )
    out = applyVibrance(out, amount: -0.18 * t)
    out = applyToneCurve(
      out,
      p0: CGPoint(x: 0.0, y: 0.06 * t),
      p1: CGPoint(x: 0.25, y: 0.25 + 0.02 * t),
      p2: CGPoint(x: 0.5, y: 0.49),
      p3: CGPoint(x: 0.75, y: 0.73),
      p4: CGPoint(x: 1.0, y: 0.94)
    )
    return out
  }

  private static func vale(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = applyColorControls(
      out,
      contrast: 1.0 + 0.12 * t,
      saturation: 1.0 + 0.08 * t,
      brightness: 0.0
    )
    out = applyVibrance(out, amount: 0.14 * t)
    out = applyTemperature(out, warmth: -0.05 * t, tint: -0.01 * t)
    out = applyHighlightShadow(out, shadows: 0.50 + 0.03 * t, highlights: 0.50 - 0.04 * t)
    out = applyToneCurve(
      out,
      p0: CGPoint(x: 0.0, y: 0.0),
      p1: CGPoint(x: 0.25, y: 0.23),
      p2: CGPoint(x: 0.5, y: 0.5),
      p3: CGPoint(x: 0.75, y: 0.79 + 0.02 * t),
      p4: CGPoint(x: 1.0, y: 1.0)
    )
    return out
  }

  private static func mono(image: CIImage, t: Double) -> CIImage {
    var out = image
    out = out.applyingFilter("CIPhotoEffectNoir")
    out = applyColorControls(
      out,
      contrast: 1.0 + 0.16 * t,
      saturation: 0.0,
      brightness: 0.0
    )
    out = applyToneCurve(
      out,
      p0: CGPoint(x: 0.0, y: 0.0),
      p1: CGPoint(x: 0.25, y: 0.22),
      p2: CGPoint(x: 0.5, y: 0.5),
      p3: CGPoint(x: 0.75, y: 0.80),
      p4: CGPoint(x: 1.0, y: 1.0)
    )
    return out
  }

  private static func applyColorControls(
    _ image: CIImage,
    contrast: Double,
    saturation: Double,
    brightness: Double
  ) -> CIImage {
    return image.applyingFilter("CIColorControls", parameters: [
      kCIInputContrastKey: CGFloat(contrast),
      kCIInputSaturationKey: CGFloat(saturation),
      kCIInputBrightnessKey: CGFloat(brightness),
    ])
  }

  private static func applyHighlightShadow(
    _ image: CIImage,
    shadows: Double,
    highlights: Double
  ) -> CIImage {
    return image.applyingFilter("CIHighlightShadowAdjust", parameters: [
      "inputShadowAmount": CGFloat(clamp01(shadows)),
      "inputHighlightAmount": CGFloat(clamp01(highlights)),
    ])
  }

  private static func applyVibrance(_ image: CIImage, amount: Double) -> CIImage {
    return image.applyingFilter("CIVibrance", parameters: [
      "inputAmount": CGFloat(amount),
    ])
  }

  private static func applyTemperature(
    _ image: CIImage,
    warmth: Double,
    tint: Double
  ) -> CIImage {
    let neutral = CIVector(x: 6500, y: 0)
    let target = CIVector(
      x: 6500 + CGFloat(warmth * 1400),
      y: CGFloat(tint * 120)
    )
    return image.applyingFilter("CITemperatureAndTint", parameters: [
      "inputNeutral": neutral,
      "inputTargetNeutral": target,
    ])
  }

  private static func applyToneCurve(
    _ image: CIImage,
    p0: CGPoint,
    p1: CGPoint,
    p2: CGPoint,
    p3: CGPoint,
    p4: CGPoint
  ) -> CIImage {
    return image.applyingFilter("CIToneCurve", parameters: [
      "inputPoint0": CIVector(cgPoint: p0),
      "inputPoint1": CIVector(cgPoint: p1),
      "inputPoint2": CIVector(cgPoint: p2),
      "inputPoint3": CIVector(cgPoint: p3),
      "inputPoint4": CIVector(cgPoint: p4),
    ])
  }

  private static func clamp01(_ value: Double) -> Double {
    return min(1.0, max(0.0, value))
  }
}
