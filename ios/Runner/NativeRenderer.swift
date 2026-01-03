import Foundation
import Photos
import CoreImage
import UIKit
import ImageIO

final class NativeRenderer {
  static let shared = NativeRenderer()

  // Force predictable color output (fixes purple/magenta)
  private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

  // GPU-backed context + explicit working/output spaces
  private lazy var ciContext: CIContext = {
    CIContext(options: [
      .useSoftwareRenderer: false,
      .workingColorSpace: sRGB,
      .outputColorSpace: sRGB
    ])
  }()

  // MARK: - Public API

  func renderPreview(
    assetId: String,
    values: [String: Double],
    maxSide: Int,
    quality: Double,
    completion: @escaping (Result<Data, Error>) -> Void
  ) {
    fetchFullCIImage(assetId: assetId) { result in
      switch result {
      case .failure(let err):
        completion(.failure(err))
      case .success(let input):
        let filtered = self.applyAdjustments(input: input, values: values)
        let scaled = self.downscale(ciImage: filtered, maxSide: maxSide)
        guard let jpeg = self.encodeJPEG(ciImage: scaled, quality: quality) else {
          completion(.failure(NSError(domain: "NativeRenderer", code: -3, userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])))
          return
        }
        completion(.success(jpeg))
      }
    }
  }

  func exportFullRes(
    assetId: String,
    values: [String: Double],
    quality: Double,
    completion: @escaping (Result<String, Error>) -> Void
  ) {
    fetchFullCIImage(assetId: assetId) { result in
      switch result {
      case .failure(let err):
        completion(.failure(err))
      case .success(let input):
        let filtered = self.applyAdjustments(input: input, values: values)
        guard let jpeg = self.encodeJPEG(ciImage: filtered, quality: quality) else {
          completion(.failure(NSError(domain: "NativeRenderer", code: -4, userInfo: [NSLocalizedDescriptionKey: "JPEG encode failed"])))
          return
        }

        self.requestAddPermission { ok, err in
          if let err = err {
            completion(.failure(err))
            return
          }
          guard ok else {
            completion(.failure(NSError(domain: "NativeRenderer", code: -5, userInfo: [NSLocalizedDescriptionKey: "No Photos add permission"])))
            return
          }

          PHPhotoLibrary.shared().performChanges({
            let req = PHAssetCreationRequest.forAsset()
            let opts = PHAssetResourceCreationOptions()
            opts.uniformTypeIdentifier = "public.jpeg"
            req.addResource(with: .photo, data: jpeg, options: opts)
          }, completionHandler: { success, error in
            if let error = error {
              completion(.failure(error))
              return
            }
            if success {
              completion(.success("saved"))
            } else {
              completion(.failure(NSError(domain: "NativeRenderer", code: -6, userInfo: [NSLocalizedDescriptionKey: "Save failed"])))
            }
          })
        }
      }
    }
  }

  // MARK: - Photos Permission (iOS 13+ compatible)

  private func requestAddPermission(completion: @escaping (Bool, Error?) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        // On iOS 14+, limited exists
        let ok = (status == .authorized) || (status == .limited)
        completion(ok, nil)
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        let ok = (status == .authorized)
        completion(ok, nil)
      }
    }
  }

  // MARK: - PhotoKit decode (full-res)

  private func fetchFullCIImage(assetId: String, completion: @escaping (Result<CIImage, Error>) -> Void) {
    let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
    guard let asset = fetch.firstObject else {
      completion(.failure(NSError(domain: "NativeRenderer", code: -1, userInfo: [NSLocalizedDescriptionKey: "PHAsset not found for id: \(assetId)"])))
      return
    }

    let opts = PHImageRequestOptions()
    opts.isSynchronous = false
    opts.isNetworkAccessAllowed = true
    opts.deliveryMode = .highQualityFormat
    opts.version = .current

    PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, orientation, _ in
      guard let data = data else {
        completion(.failure(NSError(domain: "NativeRenderer", code: -2, userInfo: [NSLocalizedDescriptionKey: "No image data returned"])))
        return
      }

      guard var ci = CIImage(data: data) else {
        completion(.failure(NSError(domain: "NativeRenderer", code: -2, userInfo: [NSLocalizedDescriptionKey: "CIImage decode failed (data)"])))
        return
      }

      // Safer orientation handling across iOS versions
      ci = ci.oriented(forExifOrientation: Int32(orientation.rawValue))

      // Optional: attempt to coerce to sRGB via CIColorSpaceConvert (best-effort)
      if let converted = self.coerceToSRGB(ci) {
        ci = converted
      }

      completion(.success(ci))
    }
  }

  private func coerceToSRGB(_ image: CIImage) -> CIImage? {
    // Not strictly required since we force sRGB at createCGImage,
    // but helps some wide-gamut inputs.
    guard let f = CIFilter(name: "CIColorSpaceConvert") else { return nil }
    f.setValue(image, forKey: kCIInputImageKey)
    f.setValue(sRGB, forKey: "inputColorSpace")
    f.setValue(sRGB, forKey: "inputOutputColorSpace")
    return f.outputImage
  }

  // MARK: - Core Image adjustments

  private func applyAdjustments(input: CIImage, values: [String: Double]) -> CIImage {
    var out = input

    func v(_ key: String) -> Double { values[key] ?? 0.0 }

    // exposure: -1..1
    let exposure = v("exposure") * 1.0
    if abs(exposure) > 0.0001 {
      out = out.applyingFilter("CIExposureAdjust", parameters: [
        kCIInputEVKey: exposure
      ])
    }

    let contrast = v("contrast")
    let saturation = v("saturation")
    let vibrance = v("vibrance")

    // highlights/shadows
    let highlights = v("highlights")
    let shadows = v("shadows")
    if abs(highlights) > 0.0001 || abs(shadows) > 0.0001 {
      let shadowAmt = clamp01(0.5 + shadows * 0.5)
      let highlightAmt = clamp01(0.5 - highlights * 0.5)
      out = out.applyingFilter("CIHighlightShadowAdjust", parameters: [
        "inputShadowAmount": shadowAmt,
        "inputHighlightAmount": highlightAmt
      ])
    }

    // whites/blacks -> brightness approximation
    let whites = v("whites")
    let blacks = v("blacks")
    let brightness = (whites - blacks) * 0.10

    // temperature/tint
    let balance = v("color_balance")
    let tint = v("tint")
    if abs(balance) > 0.0001 || abs(tint) > 0.0001 {
      let neutral = CIVector(x: 6500, y: 0)
      let target = CIVector(x: 6500 + CGFloat(balance * 1800), y: CGFloat(tint * 120))
      out = out.applyingFilter("CITemperatureAndTint", parameters: [
        "inputNeutral": neutral,
        "inputTargetNeutral": target
      ])
    }

    // color controls
    let contrastVal = CGFloat(1.0 + contrast * 0.35)
    let saturationVal = CGFloat(1.0 + saturation * 0.85)
    let brightnessVal = CGFloat(brightness)

    if abs(contrast) > 0.0001 || abs(saturation) > 0.0001 || abs(brightness) > 0.0001 {
      out = out.applyingFilter("CIColorControls", parameters: [
        kCIInputContrastKey: contrastVal,
        kCIInputSaturationKey: saturationVal,
        kCIInputBrightnessKey: brightnessVal
      ])
    }

    // vibrance
    if abs(vibrance) > 0.0001 {
      out = out.applyingFilter("CIVibrance", parameters: [
        "inputAmount": CGFloat(vibrance * 0.9)
      ])
    }

    // sharpen/clarity/texture
    let clarity = v("clarity")
    let texture = v("texture")
    let sharpen = v("sharpen")

    let sharpenAmt = CGFloat(max(0.0, sharpen) * 1.2)
    if sharpenAmt > 0.0001 {
      out = out.applyingFilter("CISharpenLuminance", parameters: [
        "inputSharpness": sharpenAmt
      ])
    }

    let unsharpAmount = CGFloat(max(0.0, texture) * 1.0 + max(0.0, clarity) * 1.4)
    if unsharpAmount > 0.0001 {
      out = out.applyingFilter("CIUnsharpMask", parameters: [
        "inputRadius": 2.0,
        "inputIntensity": unsharpAmount
      ])
    }

    // dehaze approximation
    let dehaze = v("dehaze")
    if abs(dehaze) > 0.0001 {
      out = out.applyingFilter("CIColorControls", parameters: [
        kCIInputContrastKey: CGFloat(1.0 + dehaze * 0.25)
      ])
    }

    // vignette
    let vignette = v("vignette")
    if vignette > 0.0001 {
      out = out.applyingFilter("CIVignette", parameters: [
        "inputIntensity": CGFloat(vignette * 1.2),
        "inputRadius": 2.0
      ])
    }

    // grain
    let grain = v("grain")
    if grain > 0.0001 {
      let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
        .cropped(to: out.extent)
        .applyingFilter("CIColorMatrix", parameters: [
          "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(grain * 0.12)),
        ])
      out = noise.applyingFilter("CISourceOverCompositing", parameters: [
        kCIInputBackgroundImageKey: out
      ])
    }

    return out
  }

  // MARK: - Scale + Encode

  private func downscale(ciImage: CIImage, maxSide: Int) -> CIImage {
    let extent = ciImage.extent
    let w = extent.width
    let h = extent.height
    let maxDim = max(w, h)
    guard maxDim > 0 else { return ciImage }
    let target = CGFloat(maxSide)
    if maxDim <= target { return ciImage }

    let scale = target / maxDim
    let transform = CGAffineTransform(scaleX: scale, y: scale)
    return ciImage.transformed(by: transform)
  }

  // Critical fix for purple output:
  // - force RGBA8 pixel format
  // - force sRGB colorspace
  // - use integral extent
  private func encodeJPEG(ciImage: CIImage, quality: Double) -> Data? {
    let extent = ciImage.extent.integral
    guard extent.width > 1, extent.height > 1 else { return nil }

    guard let cg = ciContext.createCGImage(
      ciImage,
      from: extent,
      format: .RGBA8,
      colorSpace: sRGB
    ) else { return nil }

    let ui = UIImage(cgImage: cg)
    return ui.jpegData(compressionQuality: CGFloat(clamp01(quality)))
  }

  private func clamp01(_ x: Double) -> Double {
    return min(1.0, max(0.0, x))
  }
}