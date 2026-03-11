import CoreImage

final class LumaCIContext {
  static let workingColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

  static let shared = CIContext(options: [
    .cacheIntermediates: true,
    .priorityRequestLow: false,
    .workingColorSpace: workingColorSpace,
    .outputColorSpace: workingColorSpace,
    .useSoftwareRenderer: false,
  ])
}
