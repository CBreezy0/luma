import Foundation
import UIKit
#if canImport(Flutter)
import Flutter
#endif

#if canImport(Flutter)
final class LumaCameraPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let cameraController = CameraViewController()
  private var histogramSink: FlutterEventSink?

  override init() {
    super.init()
    cameraController.onHistogramUpdated = { [weak self] values in
      self?.histogramSink?(values)
    }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "luma/camera",
      binaryMessenger: registrar.messenger()
    )
    let instance = LumaCameraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    let histogramChannel = FlutterEventChannel(
      name: "luma/camera_histogram",
      binaryMessenger: registrar.messenger()
    )
    histogramChannel.setStreamHandler(instance)
    let factory = LumaCameraPreviewFactory(controller: instance.cameraController)
    registrar.register(factory, withId: "luma/camera_preview")
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = (call.arguments as? [String: Any]) ?? [:]

    switch call.method {
    case "initializeCamera":
      cameraController.initialize { initResult in
        switch initResult {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_init_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "startCamera":
      cameraController.start { startResult in
        switch startResult {
        case .success:
          result(nil)
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_start_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "stopCamera":
      cameraController.stop { stopResult in
        switch stopResult {
        case .success:
          result(nil)
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_stop_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "setSimulation":
      let simulationId = (args["simulationId"] as? String) ?? LumaFilmSimulation.defaultSimulationId
      let intensity = (args["intensity"] as? NSNumber)?.doubleValue ?? 1.0
      cameraController.setSimulation(id: simulationId, intensity: intensity)
      result(nil)

    case "setFocusPoint":
      let x = (args["x"] as? NSNumber)?.doubleValue ?? 0.5
      let y = (args["y"] as? NSNumber)?.doubleValue ?? 0.5
      let lock = (args["lock"] as? Bool) ?? false
      cameraController.setFocusPoint(normalizedX: x, normalizedY: y, lock: lock) { focusResult in
        switch focusResult {
        case .success(let payload):
          result([
            "x": payload.x,
            "y": payload.y,
            "isAeAfLocked": payload.isLocked,
          ])
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_focus_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "setLookStrength":
      let requestedStrength = (args["strength"] as? NSNumber)?.doubleValue ?? 1.0
      cameraController.setLookStrength(requestedStrength) { lookResult in
        switch lookResult {
        case .success(let appliedStrength):
          result(["lookStrength": appliedStrength])
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_look_strength_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "setFlashMode":
      let modeRaw = (args["flashMode"] as? String) ?? CameraControllerFlashMode.auto.rawValue
      let mode = CameraControllerFlashMode(rawValue: modeRaw) ?? .auto
      cameraController.setFlashMode(mode)
      result(nil)

    case "setLensMode":
      let modeRaw = (args["lensMode"] as? String) ?? CameraControllerLensMode.wide.rawValue
      let mode = CameraControllerLensMode(rawValue: modeRaw) ?? .wide
      cameraController.setLensMode(mode) { lensResult in
        switch lensResult {
        case .success(let activeMode):
          result(["activeLensMode": activeMode.rawValue])
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_lens_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "setExposureBias":
      let requestedBias = (args["bias"] as? NSNumber)?.doubleValue ?? 0.0
      cameraController.setExposureBias(requestedBias) { exposureResult in
        switch exposureResult {
        case .success(let appliedBias):
          result(["exposureBias": appliedBias])
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_exposure_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "capturePhoto":
      cameraController.capturePhoto { captureResult in
        switch captureResult {
        case .success(let payload):
          result(payload)
        case .failure(let error):
          result(
            FlutterError(
              code: "camera_capture_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }

    case "latestThumbnail":
      if let bytes = cameraController.latestThumbnail() {
        result(FlutterStandardTypedData(bytes: bytes))
      } else {
        result(nil)
      }

    case "disposeCamera":
      cameraController.dispose()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    histogramSink = events
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    histogramSink = nil
    return nil
  }
}

private final class LumaCameraPreviewFactory: NSObject, FlutterPlatformViewFactory {
  private let controller: CameraViewController

  init(controller: CameraViewController) {
    self.controller = controller
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier _: Int64,
    arguments _: Any?
  ) -> FlutterPlatformView {
    return LumaCameraPreview(frame: frame, controller: controller)
  }
}

private final class LumaCameraPreview: NSObject, FlutterPlatformView {
  private let hostView: UIView

  init(frame: CGRect, controller: CameraViewController) {
    hostView = UIView(frame: frame)
    hostView.backgroundColor = .black
    super.init()

    let preview = controller.previewView
    preview.removeFromSuperview()
    preview.frame = hostView.bounds
    preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hostView.addSubview(preview)
  }

  func view() -> UIView {
    return hostView
  }
}
#endif
