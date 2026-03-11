import CoreImage
import Foundation

struct LumaLUTCubeDescriptor {
  let dimension: Int
  let cubeData: Data
  let colorSpace: CGColorSpace
}

final class LumaLUTLoader {
  static let shared = LumaLUTLoader()

  private enum LUTPreset: String, CaseIterable {
    case slate
    case ember
    case bloom
    case drift
    case vale
    case mono
  }

  private typealias RGB = (r: Float, g: Float, b: Float)

  private struct LUTStyle {
    let shadowDesaturation: Float
    let skinProtection: Float
    let highlightShoulder: Float
  }

  private let cubeDimension = 32
  private let colorSpace = LumaCIContext.workingColorSpace
  private static let lock = NSLock()
  private static var cubeDataCache: [String: LumaLUTCubeDescriptor] = [:]

  private init() {}

  func cubeDescriptor(named name: String) -> LumaLUTCubeDescriptor? {
    guard let preset = LUTPreset(rawValue: name) else { return nil }

    return cachedDescriptor(forKey: name) {
      generateCubeData { r, g, b in
        transform(r: r, g: g, b: b, preset: preset)
      }
    }
  }

  func preloadAllDescriptors() {
    for preset in LUTPreset.allCases {
      _ = cubeDescriptor(named: preset.rawValue)
    }
  }

  private func cachedDescriptor(
    forKey key: String,
    generator: () -> Data
  ) -> LumaLUTCubeDescriptor {
    Self.lock.lock()
    if let cached = Self.cubeDataCache[key] {
      Self.lock.unlock()
      return cached
    }
    Self.lock.unlock()

    let descriptor = LumaLUTCubeDescriptor(
      dimension: cubeDimension,
      cubeData: generator(),
      colorSpace: colorSpace
    )

    Self.lock.lock()
    Self.cubeDataCache[key] = descriptor
    Self.lock.unlock()

    return descriptor
  }

  private func generateCubeData(
    transform: (Float, Float, Float) -> RGB
  ) -> Data {
    let dim = cubeDimension
    let cubeSize = dim * dim * dim * 4
    var cube = [Float](repeating: 0, count: cubeSize)
    let maxIndex = Float(dim - 1)
    var offset = 0

    for b in 0..<dim {
      for g in 0..<dim {
        for r in 0..<dim {
          let rf = Float(r) / maxIndex
          let gf = Float(g) / maxIndex
          let bf = Float(b) / maxIndex
          let transformed = transform(rf, gf, bf)

          cube[offset] = clamp01(transformed.r)
          cube[offset + 1] = clamp01(transformed.g)
          cube[offset + 2] = clamp01(transformed.b)
          cube[offset + 3] = 1.0
          offset += 4
        }
      }
    }

    return cube.withUnsafeBufferPointer { pointer in
      Data(buffer: pointer)
    }
  }

  private func transform(
    r: Float,
    g: Float,
    b: Float,
    preset: LUTPreset
  ) -> RGB {
    let original = RGB(r: r, g: g, b: b)
    let luma = luminance(r: r, g: g, b: b)
    let transformed: RGB
    let style: LUTStyle

    switch preset {
    case .slate:
      transformed = RGB(
        r: mix(luma, r, t: 0.95) * 0.992,
        g: mix(luma, g, t: 0.97) * 0.998,
        b: mix(luma, b, t: 1.015) * 1.012
      )
      style = LUTStyle(
        shadowDesaturation: 0.08,
        skinProtection: 0.18,
        highlightShoulder: 0.08
      )

    case .ember:
      transformed = RGB(
        r: mix(r, 1.0, t: 0.018 * (1.0 - luma)) * 1.010,
        g: mix(g, r, t: 0.010) * 1.002,
        b: mix(b, luma, t: 0.045) * 0.988
      )
      style = LUTStyle(
        shadowDesaturation: 0.07,
        skinProtection: 0.58,
        highlightShoulder: 0.10
      )

    case .bloom:
      transformed = RGB(
        r: mix(luma, lift(r, amount: 0.016), t: 0.94),
        g: mix(luma, lift(g, amount: 0.020), t: 0.95),
        b: mix(luma, lift(b, amount: 0.024), t: 0.97)
      )
      style = LUTStyle(
        shadowDesaturation: 0.06,
        skinProtection: 0.40,
        highlightShoulder: 0.12
      )

    case .drift:
      transformed = RGB(
        r: mix(luma, r, t: 0.92) * 0.990,
        g: mix(luma, g, t: 0.94) * 0.998,
        b: mix(luma, b, t: 1.03) * 1.015
      )
      style = LUTStyle(
        shadowDesaturation: 0.10,
        skinProtection: 0.25,
        highlightShoulder: 0.10
      )

    case .vale:
      transformed = RGB(
        r: softClip(r * 1.006, shoulder: 0.03),
        g: softClip(g * 1.002, shoulder: 0.03),
        b: mix(luma, b, t: 0.985)
      )
      style = LUTStyle(
        shadowDesaturation: 0.05,
        skinProtection: 0.30,
        highlightShoulder: 0.08
      )

    case .mono:
      let neutral = softClip(luma, shoulder: 0.10)
      return RGB(r: neutral, g: neutral, b: neutral)
    }

    return finalizeTransform(
      original: original,
      transformed: transformed,
      style: style
    )
  }

  private func finalizeTransform(
    original: RGB,
    transformed: RGB,
    style: LUTStyle
  ) -> RGB {
    var output = transformed
    output = applyShadowDesaturation(to: output, amount: style.shadowDesaturation)
    output = protectSkinTones(original: original, transformed: output, amount: style.skinProtection)
    output = softClipPreservingHue(output, shoulder: style.highlightShoulder)
    return RGB(
      r: clamp01(output.r),
      g: clamp01(output.g),
      b: clamp01(output.b)
    )
  }

  private func applyShadowDesaturation(to color: RGB, amount: Float) -> RGB {
    guard amount > 0.0001 else { return color }
    let luma = luminance(r: color.r, g: color.g, b: color.b)
    let shadowMask = 1.0 - smoothstep(0.18, 0.60, luma)
    let chromaWeight = 0.35 + (0.65 * saturation(r: color.r, g: color.g, b: color.b))
    let desaturation = amount * shadowMask * chromaWeight
    return RGB(
      r: mix(color.r, luma, t: desaturation),
      g: mix(color.g, luma, t: desaturation),
      b: mix(color.b, luma, t: desaturation)
    )
  }

  private func protectSkinTones(
    original: RGB,
    transformed: RGB,
    amount: Float
  ) -> RGB {
    guard amount > 0.0001 else { return transformed }
    let protection = amount * skinToneMask(for: original)
    guard protection > 0.0001 else { return transformed }
    return RGB(
      r: mix(transformed.r, original.r, t: protection),
      g: mix(transformed.g, original.g, t: protection),
      b: mix(transformed.b, original.b, t: protection)
    )
  }

  private func skinToneMask(for color: RGB) -> Float {
    guard color.r > color.g, color.g > color.b else { return 0.0 }
    let luma = luminance(r: color.r, g: color.g, b: color.b)
    let sat = saturation(r: color.r, g: color.g, b: color.b)
    let rg = clamp01((color.r - color.g) / 0.20)
    let gb = clamp01((color.g - color.b) / 0.18)
    let lumaWeight = smoothstep(0.12, 0.28, luma) * (1.0 - smoothstep(0.85, 0.98, luma))
    let satWeight = 1.0 - smoothstep(0.42, 0.72, sat)
    return clamp01(min(rg, gb) * lumaWeight * (0.55 + (0.45 * satWeight)))
  }

  private func softClipPreservingHue(_ color: RGB, shoulder: Float) -> RGB {
    guard shoulder > 0.0001 else { return color }
    let luma = max(luminance(r: color.r, g: color.g, b: color.b), 0.0001)
    let clippedLuma = softClip(luma, shoulder: shoulder)
    let scale = clippedLuma / luma
    return RGB(
      r: clamp01(color.r * scale),
      g: clamp01(color.g * scale),
      b: clamp01(color.b * scale)
    )
  }

  private func luminance(r: Float, g: Float, b: Float) -> Float {
    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  }

  private func saturation(r: Float, g: Float, b: Float) -> Float {
    let maxChannel = max(r, max(g, b))
    let minChannel = min(r, min(g, b))
    guard maxChannel > 0.0001 else { return 0.0 }
    return (maxChannel - minChannel) / maxChannel
  }

  private func mix(_ a: Float, _ b: Float, t: Float) -> Float {
    a + ((b - a) * t)
  }

  private func lift(_ value: Float, amount: Float) -> Float {
    mix(value, 1.0, t: amount * (1.0 - value))
  }

  private func smoothstep(_ edge0: Float, _ edge1: Float, _ value: Float) -> Float {
    guard abs(edge1 - edge0) > 0.0001 else { return value >= edge1 ? 1.0 : 0.0 }
    let x = clamp01((value - edge0) / (edge1 - edge0))
    return x * x * (3.0 - (2.0 * x))
  }

  private func softClip(_ value: Float, shoulder: Float) -> Float {
    guard shoulder > 0.0001 else { return clamp01(value) }
    let clamped = clamp01(value)
    let threshold = max(0.0, 1.0 - shoulder)
    guard clamped > threshold else { return clamped }
    let normalized = (clamped - threshold) / max(shoulder, 0.0001)
    let curved = threshold + (1.0 - expf(-normalized)) * shoulder
    return clamp01(curved)
  }

  private func clamp01(_ value: Float) -> Float {
    min(1.0, max(0.0, value))
  }
}
