import CoreImage
import Foundation

// MARK: - Film Look Metadata

enum LumaFilmSimulation {
  static let defaultSimulationId = "original"

  static let supportedSimulationIds: Set<String> = [
    "original",
    "slate",
    "ember",
    "bloom",
    "drift",
    "vale",
    "mono",
  ]

  static func normalizedSimulationId(_ simulationId: String) -> String {
    supportedSimulationIds.contains(simulationId) ? simulationId : defaultSimulationId
  }

  static func lookProfile(for simulationId: String) -> LumaLookProfile {
    switch normalizedSimulationId(simulationId) {
    case "slate":
      return LumaLookProfile(
        lutPresetName: "slate",
        highlightRolloffAmount: 0.10,
        shadowLiftAmount: 0.03,
        contrastBias: 0.05,
        saturationBias: -0.05,
        temperatureBias: -0.012,
        tintBias: -0.003,
        vibranceBias: -0.01,
        grainAmount: 0.004,
        stillSharpenAmount: 0.12,
        toneCurve: .slate
      )
    case "ember":
      return LumaLookProfile(
        lutPresetName: "ember",
        highlightRolloffAmount: 0.12,
        shadowLiftAmount: 0.04,
        contrastBias: -0.01,
        saturationBias: 0.018,
        temperatureBias: 0.026,
        tintBias: 0.006,
        vibranceBias: 0.01,
        grainAmount: 0.004,
        stillSharpenAmount: 0.12,
        toneCurve: .ember
      )
    case "bloom":
      return LumaLookProfile(
        lutPresetName: "bloom",
        highlightRolloffAmount: 0.14,
        shadowLiftAmount: 0.06,
        contrastBias: -0.06,
        saturationBias: -0.01,
        temperatureBias: 0.012,
        tintBias: 0.004,
        vibranceBias: -0.02,
        grainAmount: 0.003,
        stillSharpenAmount: 0.11,
        toneCurve: .bloom
      )
    case "drift":
      return LumaLookProfile(
        lutPresetName: "drift",
        highlightRolloffAmount: 0.11,
        shadowLiftAmount: 0.05,
        contrastBias: -0.02,
        saturationBias: -0.06,
        temperatureBias: -0.034,
        tintBias: -0.009,
        vibranceBias: -0.03,
        grainAmount: 0.005,
        stillSharpenAmount: 0.11,
        toneCurve: .drift
      )
    case "vale":
      return LumaLookProfile(
        lutPresetName: "vale",
        highlightRolloffAmount: 0.08,
        shadowLiftAmount: 0.03,
        contrastBias: 0.02,
        saturationBias: 0.01,
        temperatureBias: 0.008,
        tintBias: 0.002,
        vibranceBias: 0.01,
        grainAmount: 0.003,
        stillSharpenAmount: 0.12,
        toneCurve: .vale
      )
    case "mono":
      return LumaLookProfile(
        lutPresetName: "mono",
        highlightRolloffAmount: 0.14,
        shadowLiftAmount: 0.05,
        contrastBias: 0.09,
        saturationBias: -1.0,
        temperatureBias: 0.0,
        tintBias: 0.0,
        vibranceBias: 0.0,
        grainAmount: 0.006,
        stillSharpenAmount: 0.14,
        toneCurve: .mono
      )
    default:
      return LumaLookProfile(
        lutPresetName: nil,
        highlightRolloffAmount: 0.0,
        shadowLiftAmount: 0.0,
        contrastBias: 0.0,
        saturationBias: 0.0,
        temperatureBias: 0.0,
        tintBias: 0.0,
        vibranceBias: 0.0,
        grainAmount: 0.0,
        stillSharpenAmount: 0.10
      )
    }
  }
}

struct LumaLookProfile {
  let lutPresetName: String?
  let highlightRolloffAmount: Double
  let shadowLiftAmount: Double
  let contrastBias: Double
  let saturationBias: Double
  let temperatureBias: Double
  let tintBias: Double
  let vibranceBias: Double
  let grainAmount: Double
  let stillSharpenAmount: Double
  let toneCurve: LumaToneCurve?

  init(
    lutPresetName: String?,
    highlightRolloffAmount: Double,
    shadowLiftAmount: Double,
    contrastBias: Double,
    saturationBias: Double,
    temperatureBias: Double,
    tintBias: Double,
    vibranceBias: Double,
    grainAmount: Double,
    stillSharpenAmount: Double,
    toneCurve: LumaToneCurve? = nil
  ) {
    self.lutPresetName = lutPresetName
    self.highlightRolloffAmount = highlightRolloffAmount
    self.shadowLiftAmount = shadowLiftAmount
    self.contrastBias = contrastBias
    self.saturationBias = saturationBias
    self.temperatureBias = temperatureBias
    self.tintBias = tintBias
    self.vibranceBias = vibranceBias
    self.grainAmount = grainAmount
    self.stillSharpenAmount = stillSharpenAmount
    self.toneCurve = toneCurve
  }

  var isOriginal: Bool { lutPresetName == nil }
}

struct LumaToneCurve {
  let point0: CGPoint
  let point1: CGPoint
  let point2: CGPoint
  let point3: CGPoint
  let point4: CGPoint
}

extension LumaToneCurve {
  static let linear = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.25, y: 0.25),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.75, y: 0.75),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let neutralPreviewBase = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.18, y: 0.19),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.80, y: 0.79),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let neutralStillBase = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.17, y: 0.18),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.79, y: 0.77),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let slate = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.18, y: 0.17),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.78, y: 0.82),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let ember = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.21, y: 0.23),
    point2: CGPoint(x: 0.50, y: 0.52),
    point3: CGPoint(x: 0.78, y: 0.80),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let bloom = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.02),
    point1: CGPoint(x: 0.20, y: 0.23),
    point2: CGPoint(x: 0.50, y: 0.53),
    point3: CGPoint(x: 0.78, y: 0.79),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let drift = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.03),
    point1: CGPoint(x: 0.22, y: 0.25),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.78, y: 0.76),
    point4: CGPoint(x: 1.0, y: 0.99)
  )

  static let vale = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.0),
    point1: CGPoint(x: 0.20, y: 0.20),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.79, y: 0.80),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  static let mono = LumaToneCurve(
    point0: CGPoint(x: 0.0, y: 0.01),
    point1: CGPoint(x: 0.20, y: 0.18),
    point2: CGPoint(x: 0.50, y: 0.50),
    point3: CGPoint(x: 0.77, y: 0.83),
    point4: CGPoint(x: 1.0, y: 1.0)
  )

  func applyingStrength(_ strength: Double) -> LumaToneCurve {
    Self.interpolate(from: .linear, to: self, amount: strength)
  }

  private static func interpolate(
    from start: LumaToneCurve,
    to end: LumaToneCurve,
    amount: Double
  ) -> LumaToneCurve {
    let t = CGFloat(min(1.0, max(0.0, amount)))
    return LumaToneCurve(
      point0: mix(start.point0, end.point0, t: t),
      point1: mix(start.point1, end.point1, t: t),
      point2: mix(start.point2, end.point2, t: t),
      point3: mix(start.point3, end.point3, t: t),
      point4: mix(start.point4, end.point4, t: t)
    )
  }

  private static func mix(_ a: CGPoint, _ b: CGPoint, t: CGFloat) -> CGPoint {
    CGPoint(
      x: a.x + ((b.x - a.x) * t),
      y: a.y + ((b.y - a.y) * t)
    )
  }
}

private struct LumaNeutralBaseConfiguration {
  let noiseReductionLevel: Double
  let noiseReductionSharpness: Double
  let shadowLift: Double
  let highlightCompression: Double
  let contrast: Double
  let saturation: Double
  let toneCurve: LumaToneCurve
}

enum LumaFilmRenderMode {
  case preview
  case still
}

// MARK: - Shared Native Render Pipeline

/// Shared film render pipeline used by both preview and final processed still capture.
///
/// Stage order:
/// 1. neutral base preparation
/// 2. creative look transform
/// 3. final still processing / polish
final class LumaFilmRenderPipeline {
  private let mode: LumaFilmRenderMode
  private let lutLoader: LumaLUTLoader

  // Reused filters. Each pipeline instance is used on a single processing queue.
  private let noiseReductionFilter = CIFilter(name: "CINoiseReduction")
  private let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
  private let colorControlsFilter = CIFilter(name: "CIColorControls")
  private let vibranceFilter = CIFilter(name: "CIVibrance")
  private let temperatureFilter = CIFilter(name: "CITemperatureAndTint")
  private let toneCurveFilter = CIFilter(name: "CIToneCurve")
  private let unsharpMaskFilter = CIFilter(name: "CIUnsharpMask")
  private let blendAlphaFilter = CIFilter(name: "CIColorMatrix")
  private let sourceOverFilter = CIFilter(name: "CISourceOverCompositing")
  private let randomGeneratorFilter = CIFilter(name: "CIRandomGenerator")
  private let grainMonochromeFilter = CIFilter(name: "CIColorControls")
  private let grainColorMatrixFilter = CIFilter(name: "CIColorMatrix")
  private let grainBlendFilter = CIFilter(name: "CIAdditionCompositing")
  private var lutFilters: [String: CIFilter] = [:]

  init(mode: LumaFilmRenderMode, lutLoader: LumaLUTLoader = .shared) {
    self.mode = mode
    self.lutLoader = lutLoader
  }

  func render(
    _ image: CIImage,
    simulationId: String,
    simulationIntensity: Double,
    lookStrength: Double,
    allowEnhancement: Bool,
    shouldDenoise: Bool,
    captureISO: Float? = nil
  ) -> CIImage {
    let safeSimulationId = LumaFilmSimulation.normalizedSimulationId(simulationId)
    let safeIntensity = clamp01(simulationIntensity)
    let safeStrength = clamp01(lookStrength)

    // Neutral preview base / neutral capture base.
    let neutralBase = prepareNeutralBase(
      image,
      allowEnhancement: allowEnhancement,
      shouldDenoise: shouldDenoise,
      captureISO: captureISO
    )

    let profile = LumaFilmSimulation.lookProfile(for: safeSimulationId)
    let creativeOutput: CIImage

    // Creative look transform.
    if profile.isOriginal || safeIntensity < 0.0001 {
      creativeOutput = neutralBase
    } else {
      creativeOutput = applyCreativeLookTransform(
        neutralBase,
        profile: profile,
        intensity: safeIntensity
      )
    }

    let blendedCreative: CIImage
    if profile.isOriginal || safeStrength < 0.0001 {
      blendedCreative = neutralBase
    } else if safeStrength >= 0.9999 {
      blendedCreative = creativeOutput
    } else {
      blendedCreative = blendWithBase(
        base: neutralBase,
        processed: creativeOutput,
        strength: safeStrength
      )
    }

    // Final still processing / polish.
    return applyFinalPolish(
      blendedCreative,
      profile: profile,
      creativeStrength: safeIntensity * safeStrength,
      allowEnhancement: allowEnhancement,
      captureISO: captureISO
    )
  }

  private func prepareNeutralBase(
    _ image: CIImage,
    allowEnhancement: Bool,
    shouldDenoise: Bool,
    captureISO: Float?
  ) -> CIImage {
    let config = neutralBaseConfiguration(
      allowEnhancement: allowEnhancement,
      shouldDenoise: shouldDenoise,
      captureISO: captureISO
    )
    var output = image

    // Neutral base preparation:
    // light denoise, mild highlight compression, slight shadow lift,
    // and a restrained neutral tone curve.
    if config.noiseReductionLevel > 0.0001,
      let noiseReductionFilter
    {
      noiseReductionFilter.setValue(output, forKey: kCIInputImageKey)
      noiseReductionFilter.setValue(config.noiseReductionLevel, forKey: "inputNoiseLevel")
      noiseReductionFilter.setValue(config.noiseReductionSharpness, forKey: "inputSharpness")
      output = noiseReductionFilter.outputImage ?? output
    }

    if let highlightShadowFilter {
      highlightShadowFilter.setValue(output, forKey: kCIInputImageKey)
      highlightShadowFilter.setValue(config.shadowLift, forKey: "inputShadowAmount")
      highlightShadowFilter.setValue(config.highlightCompression, forKey: "inputHighlightAmount")
      output = highlightShadowFilter.outputImage ?? output
    }

    if let colorControlsFilter {
      colorControlsFilter.setValue(output, forKey: kCIInputImageKey)
      colorControlsFilter.setValue(config.contrast, forKey: kCIInputContrastKey)
      colorControlsFilter.setValue(config.saturation, forKey: kCIInputSaturationKey)
      colorControlsFilter.setValue(0.0, forKey: kCIInputBrightnessKey)
      output = colorControlsFilter.outputImage ?? output
    }

    output = applyToneCurve(output, toneCurve: config.toneCurve)
    return output
  }

  private func applyCreativeLookTransform(
    _ image: CIImage,
    profile: LumaLookProfile,
    intensity: Double
  ) -> CIImage {
    var output = image

    // Creative look transform:
    // LUT color character, subtle per-look tonal bias, and restrained color tuning.
    if let presetName = profile.lutPresetName {
      output = applyLUTColorCharacter(
        output,
        presetName: presetName,
        intensity: intensity
      )
    }

    if abs(profile.temperatureBias) > 0.0001 || abs(profile.tintBias) > 0.0001 {
      output = applyTemperature(
        output,
        warmth: profile.temperatureBias * intensity,
        tint: profile.tintBias * intensity
      )
    }

    let highlightAmount = clamp01(1.0 - (profile.highlightRolloffAmount * intensity))
    let shadowAmount = clamp01(profile.shadowLiftAmount * intensity)
    if shadowAmount > 0.0001 || highlightAmount < 0.9999 {
      output = applyHighlightShadow(
        output,
        shadows: shadowAmount,
        highlights: highlightAmount
      )
    }

    output = applyColorControls(
      output,
      contrast: 1.0 + (profile.contrastBias * intensity),
      saturation: max(0.0, 1.0 + (profile.saturationBias * intensity)),
      brightness: 0.0
    )

    if abs(profile.vibranceBias) > 0.0001 {
      output = applyVibrance(output, amount: profile.vibranceBias * intensity)
    }

    if let toneCurve = profile.toneCurve {
      output = applyToneCurve(
        output,
        toneCurve: toneCurve.applyingStrength(intensity)
      )
    }

    return output
  }

  private func applyFinalPolish(
    _ image: CIImage,
    profile: LumaLookProfile,
    creativeStrength: Double,
    allowEnhancement: Bool,
    captureISO: Float?
  ) -> CIImage {
    var output = image

    guard mode == .still else {
      return output
    }

    // Final still processing:
    // subtle sharpening for processed stills and look grain only on saved output.
    let effectiveProfile = creativeStrength > 0.0001
      ? profile
      : LumaFilmSimulation.lookProfile(for: LumaFilmSimulation.defaultSimulationId)
    let baseSharpenAmount = allowEnhancement
      ? effectiveProfile.stillSharpenAmount
      : effectiveProfile.stillSharpenAmount * 0.55
    let sharpenAmount = baseSharpenAmount * sharpenScale(for: captureISO)
    if sharpenAmount > 0.0001,
      let unsharpMaskFilter
    {
      unsharpMaskFilter.setValue(output, forKey: kCIInputImageKey)
      unsharpMaskFilter.setValue(1.05, forKey: kCIInputRadiusKey)
      unsharpMaskFilter.setValue(sharpenAmount * 0.55, forKey: kCIInputIntensityKey)
      output = unsharpMaskFilter.outputImage ?? output
    }

    if creativeStrength > 0.0001,
      !effectiveProfile.isOriginal
    {
      let grainAmount = effectiveProfile.grainAmount
        * creativeStrength
        * grainScale(for: captureISO)
      output = applyOptionalGrain(output, amount: grainAmount)
    }

    return output
  }

  private func applyLUTColorCharacter(
    _ image: CIImage,
    presetName: String,
    intensity: Double
  ) -> CIImage {
    guard intensity > 0.0001 else { return image }
    guard let cube = lutLoader.cubeDescriptor(named: presetName) else {
      return image
    }
    let filter: CIFilter
    if let cached = lutFilters[presetName] {
      filter = cached
    } else {
      guard let created = CIFilter(name: "CIColorCubeWithColorSpace") else {
        return image
      }
      created.setValue(cube.dimension, forKey: "inputCubeDimension")
      created.setValue(cube.cubeData, forKey: "inputCubeData")
      created.setValue(cube.colorSpace, forKey: "inputColorSpace")
      lutFilters[presetName] = created
      filter = created
    }

    filter.setValue(image, forKey: kCIInputImageKey)
    let transformed = filter.outputImage ?? image
    if intensity >= 0.9999 {
      return transformed
    }
    return blendWithBase(base: image, processed: transformed, strength: intensity)
  }

  private func applyOptionalGrain(_ image: CIImage, amount: Double) -> CIImage {
    guard amount > 0.0001 else {
      return image
    }
    guard
      let randomGeneratorFilter,
      let grainMonochromeFilter,
      let grainColorMatrixFilter,
      let grainBlendFilter
    else {
      return image
    }

    let grainImage = (randomGeneratorFilter.outputImage ?? image).cropped(to: image.extent)
    grainMonochromeFilter.setValue(grainImage, forKey: kCIInputImageKey)
    grainMonochromeFilter.setValue(0.0, forKey: kCIInputSaturationKey)
    grainMonochromeFilter.setValue(1.0, forKey: kCIInputContrastKey)

    let monochromeNoise = grainMonochromeFilter.outputImage ?? grainImage
    let grain = CGFloat(amount)

    grainColorMatrixFilter.setValue(monochromeNoise, forKey: kCIInputImageKey)
    grainColorMatrixFilter.setValue(CIVector(x: grain, y: 0, z: 0, w: 0), forKey: "inputRVector")
    grainColorMatrixFilter.setValue(CIVector(x: 0, y: grain, z: 0, w: 0), forKey: "inputGVector")
    grainColorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: grain, w: 0), forKey: "inputBVector")
    grainColorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
    grainColorMatrixFilter.setValue(
      CIVector(
        x: -0.5 * grain,
        y: -0.5 * grain,
        z: -0.5 * grain,
        w: 0
      ),
      forKey: "inputBiasVector"
    )

    let centeredNoise = grainColorMatrixFilter.outputImage ?? monochromeNoise
    grainBlendFilter.setValue(centeredNoise, forKey: kCIInputImageKey)
    grainBlendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
    return (grainBlendFilter.outputImage ?? image).cropped(to: image.extent)
  }

  private func blendWithBase(
    base: CIImage,
    processed: CIImage,
    strength: Double
  ) -> CIImage {
    let alpha = CGFloat(clamp01(strength))
    guard alpha > 0.0001 else { return base }
    guard
      let blendAlphaFilter,
      let sourceOverFilter
    else {
      return processed
    }

    blendAlphaFilter.setValue(processed, forKey: kCIInputImageKey)
    blendAlphaFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
    blendAlphaFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
    blendAlphaFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
    blendAlphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: alpha), forKey: "inputAVector")
    blendAlphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")
    let alphaScaled = blendAlphaFilter.outputImage ?? processed

    sourceOverFilter.setValue(alphaScaled, forKey: kCIInputImageKey)
    sourceOverFilter.setValue(base, forKey: kCIInputBackgroundImageKey)
    return (sourceOverFilter.outputImage ?? processed).cropped(to: base.extent)
  }

  private func applyColorControls(
    _ image: CIImage,
    contrast: Double,
    saturation: Double,
    brightness: Double
  ) -> CIImage {
    guard let colorControlsFilter else { return image }
    colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
    colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
    colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
    colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
    return colorControlsFilter.outputImage ?? image
  }

  private func applyHighlightShadow(
    _ image: CIImage,
    shadows: Double,
    highlights: Double
  ) -> CIImage {
    guard let highlightShadowFilter else { return image }
    highlightShadowFilter.setValue(image, forKey: kCIInputImageKey)
    highlightShadowFilter.setValue(clamp01(shadows), forKey: "inputShadowAmount")
    highlightShadowFilter.setValue(clamp01(highlights), forKey: "inputHighlightAmount")
    return highlightShadowFilter.outputImage ?? image
  }

  private func applyVibrance(_ image: CIImage, amount: Double) -> CIImage {
    guard let vibranceFilter else { return image }
    vibranceFilter.setValue(image, forKey: kCIInputImageKey)
    vibranceFilter.setValue(amount, forKey: "inputAmount")
    return vibranceFilter.outputImage ?? image
  }

  private func applyTemperature(
    _ image: CIImage,
    warmth: Double,
    tint: Double
  ) -> CIImage {
    guard let temperatureFilter else { return image }
    temperatureFilter.setValue(image, forKey: kCIInputImageKey)
    temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
    temperatureFilter.setValue(
      CIVector(
        x: 6500 + CGFloat(warmth * 1200),
        y: CGFloat(tint * 140)
      ),
      forKey: "inputTargetNeutral"
    )
    return temperatureFilter.outputImage ?? image
  }

  private func applyToneCurve(_ image: CIImage, toneCurve: LumaToneCurve) -> CIImage {
    guard let toneCurveFilter else { return image }
    toneCurveFilter.setValue(image, forKey: kCIInputImageKey)
    toneCurveFilter.setValue(CIVector(cgPoint: toneCurve.point0), forKey: "inputPoint0")
    toneCurveFilter.setValue(CIVector(cgPoint: toneCurve.point1), forKey: "inputPoint1")
    toneCurveFilter.setValue(CIVector(cgPoint: toneCurve.point2), forKey: "inputPoint2")
    toneCurveFilter.setValue(CIVector(cgPoint: toneCurve.point3), forKey: "inputPoint3")
    toneCurveFilter.setValue(CIVector(cgPoint: toneCurve.point4), forKey: "inputPoint4")
    return toneCurveFilter.outputImage ?? image
  }

  private func neutralBaseConfiguration(
    allowEnhancement: Bool,
    shouldDenoise: Bool,
    captureISO: Float?
  ) -> LumaNeutralBaseConfiguration {
    switch mode {
    case .preview:
      return LumaNeutralBaseConfiguration(
        noiseReductionLevel: 0.0,
        noiseReductionSharpness: 0.22,
        shadowLift: allowEnhancement ? 0.15 : 0.12,
        highlightCompression: allowEnhancement ? 0.90 : 0.94,
        contrast: allowEnhancement ? 1.015 : 1.0,
        saturation: 1.00,
        toneCurve: .neutralPreviewBase
      )
    case .still:
      let noiseConfig = stillNoiseReductionConfiguration(
        shouldDenoise: shouldDenoise,
        captureISO: captureISO
      )
      return LumaNeutralBaseConfiguration(
        noiseReductionLevel: noiseConfig.level,
        noiseReductionSharpness: noiseConfig.sharpness,
        shadowLift: 0.20,
        highlightCompression: 0.84,
        contrast: 1.025,
        saturation: 1.01,
        toneCurve: .neutralStillBase
      )
    }
  }

  private func stillNoiseReductionConfiguration(
    shouldDenoise: Bool,
    captureISO: Float?
  ) -> (level: Double, sharpness: Double) {
    guard shouldDenoise else {
      return (0.0, 0.24)
    }
    let iso = Double(captureISO ?? 0)
    switch iso {
    case ..<100:
      return (0.0, 0.24)
    case 100..<400:
      return (0.008, 0.34)
    case 400..<800:
      return (0.014, 0.28)
    default:
      return (0.022, 0.22)
    }
  }

  private func grainScale(for captureISO: Float?) -> Double {
    guard let captureISO, captureISO > 0 else {
      return 0.65
    }
    let normalized = clamp01((Double(captureISO) - 80.0) / 720.0)
    return 0.55 + (normalized * 0.65)
  }

  private func sharpenScale(for captureISO: Float?) -> Double {
    guard let captureISO, captureISO > 0 else {
      return 0.95
    }
    switch captureISO {
    case ..<100:
      return 1.0
    case 100..<400:
      return 0.95
    case 400..<800:
      return 0.88
    default:
      return 0.78
    }
  }

  private func clamp01(_ value: Double) -> Double {
    min(1.0, max(0.0, value))
  }
}
