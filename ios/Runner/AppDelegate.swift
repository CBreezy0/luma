import UIKit
#if canImport(Flutter)
import Flutter
#endif

#if canImport(Flutter)
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "luma/native_renderer",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
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

        let quality = (args["quality"] as? Double) ?? 0.82

        NativeRenderer.shared.renderPreview(
          assetId: assetId,
          values: values,
          maxSide: maxSide,
          quality: quality,
          cropAspect: cropAspect,
          rotationTurns: cropRotationTurns,
          straightenDegrees: cropStraighten,
          cropRect: normalizedCropRect
        ) { r in
          switch r {
          case .failure(let err):
            result(FlutterError(code: "render_failed", message: err.localizedDescription, details: nil))
          case .success(let data):
            result(FlutterStandardTypedData(bytes: data))
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

        let quality = (args["quality"] as? Double) ?? 0.92

        NativeRenderer.shared.exportFullRes(
          assetId: assetId,
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

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
