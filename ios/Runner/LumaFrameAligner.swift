import CoreImage
import Foundation

/// Still-capture-only frame alignment for bracketed HDR merges.
///
/// The implementation keeps the search bounded to translation plus a very small
/// rotation window so handheld HDR merges stay sharp without adding heavy
/// still-capture latency.
final class LumaFrameAligner {
  private let ciContext: CIContext

  private struct AlignmentEstimate {
    let translation: CGPoint
    let rotationRadians: CGFloat
  }

  init(ciContext: CIContext) {
    self.ciContext = ciContext
  }

  func align(_ image: CIImage, to reference: CIImage) -> CIImage {
    let commonExtent = reference.extent.intersection(image.extent)
    guard commonExtent.width > 0, commonExtent.height > 0 else {
      return image.cropped(to: reference.extent)
    }

    guard
      let estimate = estimateTransform(
        moving: image.cropped(to: commonExtent),
        reference: reference.cropped(to: commonExtent)
      )
    else {
      return image.cropped(to: reference.extent)
    }

    return image
      .transformed(
        by: transform(
          for: reference.extent,
          translation: estimate.translation,
          rotationRadians: estimate.rotationRadians
        )
      )
      .cropped(to: reference.extent)
  }

  private func estimateTransform(
    moving: CIImage,
    reference: CIImage
  ) -> AlignmentEstimate? {
    let referenceExtent = reference.extent.integral
    guard referenceExtent.width > 0, referenceExtent.height > 0 else { return nil }

    let maxDimension = max(referenceExtent.width, referenceExtent.height)
    guard maxDimension > 0 else { return nil }

    let downsampleScale = min(1.0, 256.0 / maxDimension)
    let preparedReference = prepareForAlignment(reference, scale: downsampleScale)
    let preparedMoving = prepareForAlignment(moving, scale: downsampleScale)
    let preparedExtent = preparedReference.extent.integral
    guard preparedExtent.width > 0, preparedExtent.height > 0 else { return nil }

    guard downsampleScale > 0 else { return nil }
    let coarseAnglesDegrees: [CGFloat] = [-1.25, -0.5, 0.0, 0.5, 1.25]
    var bestEstimate = AlignmentEstimate(translation: .zero, rotationRadians: 0)
    var bestScore = Double.greatestFiniteMagnitude

    for angleDegrees in coarseAnglesDegrees {
      let angleRadians = angleDegrees * .pi / 180.0
      let candidate = searchTranslation(
        moving: preparedMoving,
        reference: preparedReference,
        rotationRadians: angleRadians,
        startingTranslation: .zero,
        radius: 12,
        step: 2
      )
      if candidate.score < bestScore {
        bestScore = candidate.score
        bestEstimate = AlignmentEstimate(
          translation: candidate.translation,
          rotationRadians: angleRadians
        )
      }
    }

    let fineAngleStepDegrees: CGFloat = 0.35
    for angleDegrees in stride(
      from: (bestEstimate.rotationRadians * 180.0 / .pi) - fineAngleStepDegrees,
      through: (bestEstimate.rotationRadians * 180.0 / .pi) + fineAngleStepDegrees,
      by: fineAngleStepDegrees
    ) {
      let angleRadians = angleDegrees * .pi / 180.0
      let candidate = searchTranslation(
        moving: preparedMoving,
        reference: preparedReference,
        rotationRadians: angleRadians,
        startingTranslation: bestEstimate.translation,
        radius: 2,
        step: 1
      )
      if candidate.score < bestScore {
        bestScore = candidate.score
        bestEstimate = AlignmentEstimate(
          translation: candidate.translation,
          rotationRadians: angleRadians
        )
      }
    }

    return AlignmentEstimate(
      translation: CGPoint(
        x: bestEstimate.translation.x / downsampleScale,
        y: bestEstimate.translation.y / downsampleScale
      ),
      rotationRadians: bestEstimate.rotationRadians
    )
  }

  private func searchTranslation(
    moving: CIImage,
    reference: CIImage,
    rotationRadians: CGFloat,
    startingTranslation: CGPoint,
    radius: Int,
    step: Int
  ) -> (translation: CGPoint, score: Double) {
    var bestTranslation = startingTranslation
    var bestScore = score(
      moving: moving,
      reference: reference,
      transform: transform(
        for: reference.extent,
        translation: startingTranslation,
        rotationRadians: rotationRadians
      )
    )

    for tx in stride(
      from: Int(startingTranslation.x) - radius,
      through: Int(startingTranslation.x) + radius,
      by: step
    ) {
      for ty in stride(
        from: Int(startingTranslation.y) - radius,
        through: Int(startingTranslation.y) + radius,
        by: step
      ) {
        let translation = CGPoint(x: tx, y: ty)
        let candidate = score(
          moving: moving,
          reference: reference,
          transform: transform(
            for: reference.extent,
            translation: translation,
            rotationRadians: rotationRadians
          )
        )
        if candidate < bestScore {
          bestScore = candidate
          bestTranslation = translation
        }
      }
    }

    return (bestTranslation, bestScore)
  }

  private func prepareForAlignment(_ image: CIImage, scale: CGFloat) -> CIImage {
    var output = image
      .applyingFilter(
        "CIColorControls",
        parameters: [
          kCIInputSaturationKey: 0.0,
          kCIInputContrastKey: 1.08,
        ]
      )
      .cropped(to: image.extent)

    if scale < 0.999 {
      output = output
        .applyingFilter(
          "CILanczosScaleTransform",
          parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: 1.0,
          ]
        )
        .cropped(to: CGRect(
          x: 0,
          y: 0,
          width: max(1.0, image.extent.width * scale),
          height: max(1.0, image.extent.height * scale)
        ))
    }

    return output
      .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 1.2])
      .cropped(to: output.extent.integral)
  }

  private func score(
    moving: CIImage,
    reference: CIImage,
    transform: CGAffineTransform
  ) -> Double {
    let shifted = moving
      .transformed(by: transform)
      .cropped(to: reference.extent)
    let difference = shifted
      .applyingFilter(
        "CIDifferenceBlendMode",
        parameters: [kCIInputBackgroundImageKey: reference]
      )
      .cropped(to: reference.extent)
    let average = difference.applyingFilter(
      "CIAreaAverage",
      parameters: [kCIInputExtentKey: CIVector(cgRect: reference.extent)]
    )

    var pixel = [Float](repeating: 0, count: 4)
    ciContext.render(
      average,
      toBitmap: &pixel,
      rowBytes: MemoryLayout<Float>.size * 4,
      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
      format: .RGBAf,
      colorSpace: nil
    )

    return Double(pixel[0] + pixel[1] + pixel[2])
  }

  private func transform(
    for extent: CGRect,
    translation: CGPoint,
    rotationRadians: CGFloat
  ) -> CGAffineTransform {
    let center = CGPoint(x: extent.midX, y: extent.midY)
    return CGAffineTransform(translationX: -center.x, y: -center.y)
      .rotated(by: rotationRadians)
      .translatedBy(x: center.x, y: center.y)
      .translatedBy(x: translation.x, y: translation.y)
  }
}
