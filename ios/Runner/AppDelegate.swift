import UIKit
import Photos
#if canImport(Flutter)
import Flutter
#endif

#if canImport(Flutter)
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let previewRenderQueue = DispatchQueue(
    label: "com.luma.preview.render",
    qos: .userInitiated
  )
  private var nativeRendererChannel: FlutterMethodChannel?
  private var nativeShareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerNativeRendererChannel()
    registerNativeShareChannel()
    registerLumaCameraPlugin()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerNativeShareChannel() {
    guard let registrar = registrar(forPlugin: "LumaNativeShareChannel") else { return }
    let channel = FlutterMethodChannel(
      name: "luma/native_share",
      binaryMessenger: registrar.messenger()
    )
    nativeShareChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "App delegate unavailable", details: nil))
        return
      }
      let args = (call.arguments as? [String: Any]) ?? [:]
      let paths = (args["paths"] as? [String]) ?? []

      switch call.method {
      case "shareFiles":
        let subject = args["subject"] as? String
        self.shareFiles(paths: paths, subject: subject, result: result)
      case "saveFilesToPhotos":
        self.saveFilesToPhotos(paths: paths, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerNativeRendererChannel() {
    guard let registrar = registrar(forPlugin: "LumaNativeRendererChannel") else { return }
    let channel = FlutterMethodChannel(
      name: "luma/native_renderer",
      binaryMessenger: registrar.messenger()
    )
    nativeRendererChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "App delegate unavailable", details: nil))
        return
      }
      let args = (call.arguments as? [String: Any]) ?? [:]
      let crop = args["crop"] as? [String: Any]
      let cropAspect = crop?["aspect"] as? Double
      let cropStraighten = (crop?["straighten"] as? Double) ?? 0.0
      let cropRotationTurns = (crop?["rotationTurns"] as? NSNumber)?.intValue ?? 0
      let cropRect = crop?["rect"] as? [String: Any]
      let cropRectX = cropRect?["x"] as? Double
      let cropRectY = cropRect?["y"] as? Double
      let cropRectW = cropRect?["w"] as? Double
      let cropRectH = cropRect?["h"] as? Double
      let normalizedCropRect: CGRect? = {
        guard
          let x = cropRectX,
          let y = cropRectY,
          let w = cropRectW,
          let h = cropRectH
        else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
      }()

      switch call.method {
      case "renderPreview":
        guard
          let assetId = args["assetId"] as? String,
          let values = args["values"] as? [String: Double],
          let maxSide = args["maxSide"] as? Int
        else {
          result(FlutterError(code: "bad_args", message: "assetId/values/maxSide required", details: nil))
          return
        }

        let assetPath = args["assetPath"] as? String
        let quality = (args["quality"] as? Double) ?? 0.82
        let previewTier = (args["previewTier"] as? String) ?? "final"
        let isDragPreview = previewTier == "drag"
        let requestId = (args["requestId"] as? NSNumber)?.intValue ?? 0
        let presetValues = args["presetValues"] as? [String: Double]
        let presetIntensity = (args["presetIntensity"] as? Double) ?? 1.0
        let presetBlendMode = (args["presetBlendMode"] as? String) ?? "params"

        self.previewRenderQueue.async {
          NativeRenderer.shared.renderPreview(
            assetId: assetId,
            assetPath: assetPath,
            values: values,
            maxSide: maxSide,
            quality: quality,
            cropAspect: cropAspect,
            rotationTurns: cropRotationTurns,
            straightenDegrees: cropStraighten,
            cropRect: normalizedCropRect,
            isDragPreview: isDragPreview,
            requestId: requestId,
            presetValues: presetValues,
            presetIntensity: presetIntensity,
            presetBlendMode: presetBlendMode
          ) { r in
            DispatchQueue.main.async {
              switch r {
              case .failure(let err):
                result(FlutterError(code: "render_failed", message: err.localizedDescription, details: nil))
              case .success(let data):
                result([
                  "requestId": requestId,
                  "bytes": FlutterStandardTypedData(bytes: data),
                ])
              }
            }
          }
        }

      case "exportFullRes":
        guard
          let assetId = args["assetId"] as? String,
          let values = args["values"] as? [String: Double]
        else {
          result(FlutterError(code: "bad_args", message: "assetId/values required", details: nil))
          return
        }

        let assetPath = args["assetPath"] as? String
        let quality = (args["quality"] as? Double) ?? 0.92

        NativeRenderer.shared.exportFullRes(
          assetId: assetId,
          assetPath: assetPath,
          values: values,
          quality: quality,
          cropAspect: cropAspect,
          rotationTurns: cropRotationTurns,
          straightenDegrees: cropStraighten,
          cropRect: normalizedCropRect
        ) { r in
          switch r {
          case .failure(let err):
            result(FlutterError(code: "export_failed", message: err.localizedDescription, details: nil))
          case .success(let status):
            result(status)
          }
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerLumaCameraPlugin() {
    if let registrar = self.registrar(forPlugin: "LumaCameraPlugin") {
      LumaCameraPlugin.register(with: registrar)
    }
  }

  private func shareFiles(
    paths: [String],
    subject: String?,
    result: @escaping FlutterResult
  ) {
    let fileURLs = paths
      .map { URL(fileURLWithPath: $0) }
      .filter { FileManager.default.fileExists(atPath: $0.path) }
    guard !fileURLs.isEmpty else {
      result(
        FlutterError(
          code: "share_missing_files",
          message: "No export files were available to share.",
          details: nil
        )
      )
      return
    }

    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else {
        result(
          FlutterError(
            code: "share_presenter_missing",
            message: "Could not find a view controller to present the share sheet.",
            details: nil
          )
        )
        return
      }

      let activityController = UIActivityViewController(
        activityItems: fileURLs,
        applicationActivities: nil
      )
      if let subject, !subject.isEmpty {
        activityController.setValue(subject, forKey: "subject")
      }
      if let popover = activityController.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX,
          y: presenter.view.bounds.midY,
          width: 1,
          height: 1
        )
        popover.permittedArrowDirections = []
      }

      presenter.present(activityController, animated: true)
      result(nil)
    }
  }

  private func saveFilesToPhotos(
    paths: [String],
    result: @escaping FlutterResult
  ) {
    let fileURLs = paths
      .map { URL(fileURLWithPath: $0) }
      .filter { FileManager.default.fileExists(atPath: $0.path) }
    guard !fileURLs.isEmpty else {
      result(
        FlutterError(
          code: "save_missing_files",
          message: "No export files were available to save.",
          details: nil
        )
      )
      return
    }

    requestPhotoLibraryAddAccess { accessResult in
      switch accessResult {
      case .failure(let error):
        result(
          FlutterError(
            code: "photo_access_denied",
            message: error.localizedDescription,
            details: nil
          )
        )
      case .success:
        PHPhotoLibrary.shared().performChanges({
          for fileURL in fileURLs {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            request.addResource(with: .photo, fileURL: fileURL, options: options)
          }
        }, completionHandler: { success, error in
          if let error {
            result(
              FlutterError(
                code: "save_to_photos_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
            return
          }
          if success {
            result(nil)
          } else {
            result(
              FlutterError(
                code: "save_to_photos_failed",
                message: "Photos did not accept the exported file.",
                details: nil
              )
            )
          }
        })
      }
    }
  }

  private func requestPhotoLibraryAddAccess(
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          completion(.success(()))
        } else {
          completion(
            .failure(
              NSError(
                domain: "LumaNativeShare",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Photos access was denied."]
              )
            )
          )
        }
      }
      return
    }

    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized {
        completion(.success(()))
      } else {
        completion(
          .failure(
            NSError(
              domain: "LumaNativeShare",
              code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Photos access was denied."]
            )
          )
        )
      }
    }
  }

  private func topViewController(
    from root: UIViewController? = nil
  ) -> UIViewController? {
    let baseController: UIViewController?
    if let root {
      baseController = root
    } else {
      baseController = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?
        .rootViewController
    }

    if let navigation = baseController as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tab = baseController as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = baseController?.presentedViewController {
      return topViewController(from: presented)
    }
    return baseController
  }
}
#else
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
  ) -> Bool {
    // Flutter isn't available; provide a minimal window so the app can launch for native-only builds/tests.
    let window = UIWindow(frame: UIScreen.main.bounds)
    let vc = UIViewController()
    vc.view.backgroundColor = .systemBackground
    window.rootViewController = vc
    window.makeKeyAndVisible()
    self.window = window
    return true
  }
}
#endif
