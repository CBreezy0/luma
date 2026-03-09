import AVFoundation
import CoreLocation
import CoreImage
import ImageIO
import UIKit

enum CameraControllerLensMode: String {
  case wide
  case ultraWide
}

enum CameraControllerFlashMode: String {
  case auto
  case off
  case on
}

enum CameraControllerCaptureFormat: String {
  case heic
  case jpg
  case raw
  case proRaw = "pro_raw"
  case rawPlusHeic = "raw_plus_heic"
  case rawPlusJpg = "raw_plus_jpg"

  var isProcessedCapture: Bool {
    switch self {
    case .heic, .jpg, .rawPlusHeic, .rawPlusJpg:
      return true
    case .raw, .proRaw:
      return false
    }
  }

  var hasRawCompanion: Bool {
    switch self {
    case .raw, .proRaw, .rawPlusHeic, .rawPlusJpg:
      return true
    case .heic, .jpg:
      return false
    }
  }

  var hasProcessedCompanion: Bool {
    switch self {
    case .rawPlusHeic, .rawPlusJpg, .heic, .jpg:
      return true
    case .raw, .proRaw:
      return false
    }
  }

  var processedCaptureFormat: CameraControllerCaptureFormat? {
    switch self {
    case .rawPlusHeic:
      return .heic
    case .rawPlusJpg:
      return .jpg
    case .heic, .jpg:
      return self
    case .raw, .proRaw:
      return nil
    }
  }
}

enum CameraControllerError: LocalizedError {
  case cameraPermissionDenied
  case noBackCamera
  case sessionNotConfigured
  case captureInProgress
  case photoEncodingFailed
  case photoDataUnavailable
  case photoLibraryDenied
  case configurationFailed(String)

  var errorDescription: String? {
    switch self {
    case .cameraPermissionDenied:
      return "Camera permission denied."
    case .noBackCamera:
      return "No back camera available."
    case .sessionNotConfigured:
      return "Camera session is not configured."
    case .captureInProgress:
      return "A capture is already in progress."
    case .photoEncodingFailed:
      return "Could not encode captured photo."
    case .photoDataUnavailable:
      return "No photo data returned from capture."
    case .photoLibraryDenied:
      return "Photo Library add permission denied."
    case .configurationFailed(let reason):
      return reason
    }
  }
}

struct FocusPointUpdate {
  let x: Double
  let y: Double
  let isLocked: Bool
}

private typealias CaptureSnapshot = (
  simulationId: String,
  simulationIntensity: Double,
  lookStrength: Double,
  videoOrientation: AVCaptureVideoOrientation,
  cameraPosition: AVCaptureDevice.Position,
  lensMode: CameraControllerLensMode,
  captureFormat: CameraControllerCaptureFormat
)

private struct BracketFrame {
  let image: CIImage
  let exposureBias: Float
}

private struct CameraPhotoResolutionOption: Hashable {
  let width: Int32
  let height: Int32

  init?(dimensions: CMVideoDimensions) {
    guard dimensions.width > 0, dimensions.height > 0 else {
      return nil
    }
    width = dimensions.width
    height = dimensions.height
  }

  init?(width: Int, height: Int) {
    guard width > 0, height > 0 else {
      return nil
    }
    self.width = Int32(width)
    self.height = Int32(height)
  }

  var dimensions: CMVideoDimensions {
    CMVideoDimensions(width: width, height: height)
  }

  var megapixels: Double {
    let safeWidth = max(Double(width), 1)
    let safeHeight = max(Double(height), 1)
    return max(0.1, (safeWidth * safeHeight) / 1_000_000.0)
  }

  var payload: [String: Any] {
    [
      "width": Int(width),
      "height": Int(height),
    ]
  }
}

final class CameraPreviewContainerView: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

final class CameraViewController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
  let previewView = CameraPreviewContainerView()

  private let previewImageView = UIImageView()
  private let focusPointConversionLayer = AVCaptureVideoPreviewLayer()
  private let session = AVCaptureSession()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let photoOutput = AVCapturePhotoOutput()

  private let sessionQueue = DispatchQueue(label: "com.luma.camera.session", qos: .userInitiated)
  private let previewQueue = DispatchQueue(label: "com.luma.camera.preview", qos: .userInitiated)
  private let stateQueue = DispatchQueue(label: "com.luma.camera.state")
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 25
    return manager
  }()

  private let ciContext: CIContext
  private let lutLoader = LumaLUTLoader.shared
  private let workingColorSpace = LumaColorPipeline.workingColorSpace
  private lazy var previewProcessor = LumaPreviewProcessor(
    ciContext: ciContext,
    lutLoader: lutLoader
  )
  private lazy var frameAligner = LumaFrameAligner(ciContext: ciContext)
  private lazy var stillRenderPipeline = LumaFilmRenderPipeline(
    mode: .still,
    lutLoader: lutLoader
  )

  private var videoInput: AVCaptureDeviceInput?
  private var isConfigured = false
  private var isRenderingFrame = false
  private var captureCompletion: ((Result<[String: Any], Error>) -> Void)?

  private var _simulationId = LumaFilmSimulation.defaultSimulationId
  private var _simulationIntensity = 1.0
  private var _isAeAfLocked = false
  private var _lookStrength = 1.0
  private var _exposureBias = 0.0
  private var _lensMode: CameraControllerLensMode = .wide
  private var _flashMode: CameraControllerFlashMode = .auto
  private var _captureFormat: CameraControllerCaptureFormat = .heic
  private var _captureVideoOrientation: AVCaptureVideoOrientation = .portrait
  private var _captureCameraPosition: AVCaptureDevice.Position = .back
  private var _captureFormatForCurrentPhoto: CameraControllerCaptureFormat = .heic
  private var _didTemporarilyLockExposureForCapture = false
  private var _zoomFactor: Double = 1.0
  private var _minZoomFactor: Double = 1.0
  private var _maxZoomFactor: Double = 5.0
  private var _megapixels: Double = 12.0
  private var _availablePhotoResolutions: [CameraPhotoResolutionOption] = []
  private var _selectedPhotoResolution: CameraPhotoResolutionOption?
  private var _supportsManualFocus = false
  private var _focusDistance: Double = 0.0
  private var _isManualFocusActive = false
  private var _latestLocation: CLLocation?
  private var _latestThumbnailData: Data?
  var onHistogramUpdated: (([Double]) -> Void)?
  var onZoomUpdated: (([String: Any]) -> Void)?
  private let tempCapturePrefix = "luma_capture_"
  private let tempCaptureMaxAgeSeconds: TimeInterval = 24 * 60 * 60
  private let histogramQueue = DispatchQueue(
    label: "com.luma.camera.histogram",
    qos: .utility
  )
  private let histogramBinCount = 96
  private let histogramDownsampleWidth: CGFloat = 144
  private let histogramMinInterval: TimeInterval = 0.1
  private let histogramMaxInterval: TimeInterval = 0.35
  private let previewFpsThrottleThreshold = 24.0
  private let previewFpsRecoveryThreshold = 28.0
  private let previewHistogramCostThreshold: TimeInterval = 0.018
  private let previewReducedHistogramInterval: TimeInterval = 0.5
  private let highlightClippingThreshold = 0.02
  private let highlightClippingRecoveryThreshold = 0.008
  private let highlightProtectionMaximumBias = 0.45
  private let highlightProtectionMinimumUpdateInterval: TimeInterval = 0.25
  private var histogramUpdateInterval: TimeInterval = 0.1
  private var histogramLastDispatchTime: CFAbsoluteTime = 0
  private var histogramIsComputing = false
  private var histogramComputeEMA: TimeInterval = 0
  private var previewFrameIntervalEMA: TimeInterval = 0
  private var previewLastFrameTimestamp: CFAbsoluteTime = 0
  private var previewProcessingMode: LumaPreviewProcessingMode = .standard
  private var pinchZoomStartFactor: CGFloat = 1.0
  private let bracketISOThreshold: Float = 500
  private let sceneContrastThreshold = 0.55
  private let bracketExposureBiasValues: [Float] = [-1.0, 0.0, 1.0]
  private var bracketExpectedFrameCount = 1
  private var bracketReceivedFrameCount = 0
  private var bracketFrames: [BracketFrame] = []
  private var bracketSourceMetadata: [String: Any]?
  private var isBracketCaptureActive = false
  private var sceneContrastEstimate: Double = 0
  private var highlightClippingEstimate: Double = 0
  private var autoExposureProtectionBias: Double = 0
  private var lastHighlightProtectionAdjustmentTime: CFAbsoluteTime = 0
  private var rawPlusProcessedRawData: Data?
  private var rawPlusProcessedProcessedData: Data?
  private var rawPlusProcessedProcessedMetadata: [AnyHashable: Any]?
  private var hasRequestedLocationAuthorization = false
  private lazy var gpsDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy:MM:dd"
    return formatter
  }()
  private lazy var gpsTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "HH:mm:ss.SSSSSS"
    return formatter
  }()

  override init() {
    ciContext = CIContext(options: [
      .useSoftwareRenderer: false,
      .cacheIntermediates: true,
      .workingColorSpace: workingColorSpace,
      .outputColorSpace: workingColorSpace,
    ])
    super.init()
    focusPointConversionLayer.session = session
    focusPointConversionLayer.videoGravity = .resizeAspectFill
    configurePreviewView()
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleDeviceOrientationDidChange),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
  }

  func initialize(completion: @escaping (Result<[String: Any], Error>) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      configureSession(completion: completion)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          self.configureSession(completion: completion)
        } else {
          DispatchQueue.main.async {
            completion(.failure(CameraControllerError.cameraPermissionDenied))
          }
        }
      }
    default:
      DispatchQueue.main.async {
        completion(.failure(CameraControllerError.cameraPermissionDenied))
      }
    }
  }

  func start(completion: @escaping (Result<Void, Error>) -> Void) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      if !self.session.isRunning {
        self.session.startRunning()
      }
      if let device = self.videoInput?.device {
        self.applyDefaultAutoFocusAndExposure(to: device)
        _ = self.applyZoomFactorOnSessionQueue(1.0, emitUpdate: true)
      }
      DispatchQueue.main.async {
        self.updateLocationCaptureState()
        completion(.success(()))
      }
    }
  }

  func stop(completion: @escaping (Result<Void, Error>) -> Void) {
    sessionQueue.async {
      if self.session.isRunning {
        self.session.stopRunning()
      }
      DispatchQueue.main.async {
        self.locationManager.stopUpdatingLocation()
        completion(.success(()))
      }
    }
  }

  func dispose() {
    sessionQueue.async {
      if self.session.isRunning {
        self.session.stopRunning()
      }
      self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
      self.stateQueue.sync {
        self._latestThumbnailData = nil
        self._isAeAfLocked = false
        self._isManualFocusActive = false
      }
      self.resetRawPlusProcessedBuffers()
      self.onHistogramUpdated = nil
      self.onZoomUpdated = nil
    }
    DispatchQueue.main.async {
      self.locationManager.stopUpdatingLocation()
      self.previewImageView.image = nil
    }
  }

  func setSimulation(id: String, intensity: Double) {
    let safeId = LumaFilmSimulation.supportedSimulationIds.contains(id)
      ? id
      : LumaFilmSimulation.defaultSimulationId
    stateQueue.sync {
      _simulationId = safeId
      _simulationIntensity = max(0.0, min(1.0, intensity))
    }
  }

  func setFocusPoint(
    normalizedX x: Double,
    normalizedY y: Double,
    lock: Bool,
    completion: @escaping (Result<FocusPointUpdate, Error>) -> Void
  ) {
    let normalized = CGPoint(
      x: min(max(x, 0.0), 1.0),
      y: min(max(y, 0.0), 1.0)
    )
    let previewBounds = currentPreviewBounds()
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      guard let device = self.videoInput?.device else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.noBackCamera))
        }
        return
      }

      do {
        let orientation = self.currentVideoOrientationForFocus()
        let devicePoint = self.deviceFocusPoint(
          fromNormalizedPreviewPoint: normalized,
          previewBounds: previewBounds,
          videoOrientation: orientation,
          cameraPosition: device.position
        )
        try self.applyFocusAndExposure(
          to: device,
          point: devicePoint,
          lock: lock
        )
        let payload = FocusPointUpdate(
          x: normalized.x,
          y: normalized.y,
          isLocked: lock
        )
        DispatchQueue.main.async {
          completion(.success(payload))
        }
      } catch {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed(
                "Could not set focus point: \(error.localizedDescription)"
              )
            )
          )
        }
      }
    }
  }

  func setLookStrength(
    _ strength: Double,
    completion: @escaping (Result<Double, Error>) -> Void
  ) {
    let clamped = min(max(strength, 0.0), 1.0)
    stateQueue.sync {
      _lookStrength = clamped
    }
    DispatchQueue.main.async {
      completion(.success(clamped))
    }
  }

  func setManualFocusDistance(
    _ focusDistance: Double,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      guard let device = self.videoInput?.device else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.noBackCamera))
        }
        return
      }
      guard device.isFocusModeSupported(.locked) else {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed(
                "Manual focus is not supported on this device."
              )
            )
          )
        }
        return
      }

      let clampedDistance = min(max(focusDistance, 0.0), 1.0)
      do {
        try device.lockForConfiguration()
        device.setFocusModeLocked(
          lensPosition: Float(clampedDistance),
          completionHandler: nil
        )
        if device.isExposureModeSupported(.continuousAutoExposure) {
          device.exposureMode = .continuousAutoExposure
        }
        device.isSubjectAreaChangeMonitoringEnabled = false
        device.unlockForConfiguration()
        self.stateQueue.sync {
          self._supportsManualFocus = true
          self._focusDistance = clampedDistance
          self._isManualFocusActive = true
        }
        let payload = self.manualFocusPayload()
        DispatchQueue.main.async {
          completion(.success(payload))
        }
      } catch {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed(
                "Could not set manual focus: \(error.localizedDescription)"
              )
            )
          )
        }
      }
    }
  }

  func setFlashMode(_ mode: CameraControllerFlashMode) {
    stateQueue.sync {
      _flashMode = mode
    }
  }

  func setCaptureFormat(
    _ format: CameraControllerCaptureFormat,
    completion: @escaping (Result<CameraControllerCaptureFormat, Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      do {
        let requested = self.applyRequestedCaptureFormatOnSessionQueue(format)
        let activeDevice = try self.reconcileCaptureDeviceOnSessionQueue(
          preferredCaptureFormat: requested
        )
        if requested == .proRaw {
          _ = self.applyZoomFactorOnSessionQueue(1.0, emitUpdate: false)
        }
        _ = self.refreshPhotoConfigurationOnSessionQueue(device: activeDevice)
        self.emitZoomUpdate()
        DispatchQueue.main.async {
          completion(.success(self.captureFormat()))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  func setPhotoResolution(
    width: Int,
    height: Int,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      guard let requested = CameraPhotoResolutionOption(width: width, height: height) else {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed("Invalid photo resolution.")
            )
          )
        }
        return
      }

      do {
        let activeDevice = try self.reconcileCaptureDeviceOnSessionQueue(
          preferredResolution: requested
        )
        _ = self.refreshPhotoConfigurationOnSessionQueue(
          device: activeDevice,
          preferredResolution: requested
        )
        let payload = self.zoomPayload()
        DispatchQueue.main.async {
          completion(.success(payload))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  func setZoomFactor(
    _ zoomFactor: Double,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      guard self.videoInput?.device != nil else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.noBackCamera))
        }
        return
      }

      if self.applyZoomFactorOnSessionQueue(CGFloat(zoomFactor), emitUpdate: true) == nil {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed("Could not update zoom.")
            )
          )
        }
        return
      }

      let payload = self.zoomPayload()
      DispatchQueue.main.async {
        completion(.success(payload))
      }
    }
  }

  func setExposureBias(
    _ bias: Double,
    completion: @escaping (Result<Double, Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      guard let device = self.videoInput?.device else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.noBackCamera))
        }
        return
      }
      do {
        let applied = try self.applyExposureBias(bias, to: device)
        DispatchQueue.main.async {
          completion(.success(applied))
        }
      } catch {
        DispatchQueue.main.async {
          completion(
            .failure(
              CameraControllerError.configurationFailed(
                "Could not set exposure bias: \(error.localizedDescription)"
              )
            )
          )
        }
      }
    }
  }

  func setLensMode(
    _ mode: CameraControllerLensMode,
    completion: @escaping (Result<CameraControllerLensMode, Error>) -> Void
  ) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      do {
        let activeDevice = try self.reconcileCaptureDeviceOnSessionQueue(
          preferredLensMode: mode
        )
        _ = self.refreshPhotoConfigurationOnSessionQueue(device: activeDevice)
        self.emitZoomUpdate()
        let active = self.stateQueue.sync { self._lensMode }
        DispatchQueue.main.async {
          completion(.success(active))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  func capturePhoto(completion: @escaping (Result<[String: Any], Error>) -> Void) {
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      do {
        let activeDevice = try self.reconcileCaptureDeviceOnSessionQueue()
        _ = self.refreshPhotoConfigurationOnSessionQueue(device: activeDevice)
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
        return
      }

      let assigned = self.stateQueue.sync { () -> Bool in
        if self.captureCompletion != nil {
          return false
        }
        self.captureCompletion = completion
        return true
      }

      guard assigned else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.captureInProgress))
        }
        return
      }

      let orientation = self.currentPreferredVideoOrientation()
      self.applyVideoOrientation(orientation)
      let activePosition = self.videoInput?.device.position ?? .back
      self.stateQueue.sync {
        self._captureVideoOrientation = orientation
        self._captureCameraPosition = activePosition
      }

      self.lockExposureForCaptureIfNeeded()
      self.triggerShutterHaptic()
      self.resetRawPlusProcessedBuffers()
      let enableBracketing = self.shouldUseExposureBracketing()
      if enableBracketing, let bracketSettings = self.makeBracketPhotoSettings() {
        self.prepareFrameCollection(
          expectedFrameCount: bracketSettings.bracketedSettings.count,
          bracketed: true
        )
        self.photoOutput.capturePhoto(with: bracketSettings, delegate: self)
      } else {
        self.prepareFrameCollection(expectedFrameCount: 1, bracketed: false)
        let settings = self.makePhotoSettings()
        self.photoOutput.capturePhoto(with: settings, delegate: self)
      }
    }
  }

  func latestThumbnail() -> Data? {
    return stateQueue.sync { _latestThumbnailData }
  }

  func supportsUltraWide() -> Bool {
    return availableDevice(for: .ultraWide) != nil
  }

  func supportsRawCapture() -> Bool {
    return standardRawPhotoPixelFormatTypeOnSessionQueue() != nil
  }

  func supportsAppleProRAWCapture() -> Bool {
    return appleProRAWPhotoPixelFormatTypeOnSessionQueue() != nil
  }

  func activeLensMode() -> CameraControllerLensMode {
    return stateQueue.sync { _lensMode }
  }

  func isAeAfLocked() -> Bool {
    return stateQueue.sync { _isAeAfLocked }
  }

  func lookStrength() -> Double {
    return stateQueue.sync { _lookStrength }
  }

  func exposureBias() -> Double {
    return stateQueue.sync { _exposureBias }
  }

  func captureFormat() -> CameraControllerCaptureFormat {
    return stateQueue.sync { _captureFormat }
  }

  func zoomFactor() -> Double {
    return stateQueue.sync { _zoomFactor }
  }

  func minZoomFactor() -> Double {
    return stateQueue.sync { _minZoomFactor }
  }

  func maxZoomFactor() -> Double {
    return stateQueue.sync { _maxZoomFactor }
  }

  func megapixels() -> Double {
    return stateQueue.sync { _megapixels }
  }

  func supportsManualFocus() -> Bool {
    return stateQueue.sync { _supportsManualFocus }
  }

  func focusDistance() -> Double {
    return stateQueue.sync { _focusDistance }
  }

  func isManualFocusActive() -> Bool {
    return stateQueue.sync { _isManualFocusActive }
  }

  // MARK: - Preview Pipeline

  func captureOutput(
    _: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from _: AVCaptureConnection
  ) {
    let frameTimestamp = CFAbsoluteTimeGetCurrent()
    stateQueue.sync {
      updatePreviewFrameInterval(now: frameTimestamp)
    }

    guard !isRenderingFrame else { return }
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    isRenderingFrame = true
    autoreleasepool {
      let simulationState = stateQueue.sync {
        (_simulationId, _simulationIntensity, _lookStrength)
      }
      let image = CIImage(cvPixelBuffer: pixelBuffer)
      let previewProcessingState = stateQueue.sync { () -> (Bool, LumaPreviewProcessingMode) in
        let processingMode = updatePreviewProcessingModeOnStateQueue()
        guard previewFrameIntervalEMA > 0 else { return (true, processingMode) }
        let fps = 1.0 / previewFrameIntervalEMA
        return (fps >= previewFpsThrottleThreshold, processingMode)
      }
      // Preview pipeline:
      // 1. neutral preview base
      // 2. creative look transform
      // 3. preview output (no still-only polish)
      let processedImage = previewProcessor.processPreviewFrame(
        image,
        simulationId: simulationState.0,
        simulationIntensity: simulationState.1,
        lookStrength: simulationState.2,
        applyEnhancement: previewProcessingState.0,
        processingMode: previewProcessingState.1
      )

      // Histogram pipeline (preview-derived bins).
      if previewProcessingState.1.shouldComputeHistogram {
        maybeDispatchHistogram(from: processedImage)
      }

      guard let frameImage = previewProcessor.makePreviewImage(from: processedImage) else {
        isRenderingFrame = false
        return
      }

      isRenderingFrame = false
      DispatchQueue.main.async { [weak self] in
        self?.previewImageView.image = frameImage
      }
    }
  }

  // MARK: - AVCapturePhotoCaptureDelegate

  func photoOutput(
    _: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    let photoData = photo.fileDataRepresentation()
    let photoMetadata = photo.metadata
    let bracketSettings = photo.bracketSettings
    let captureState = stateQueue.sync { () -> CaptureSnapshot in
      (
        simulationId: _simulationId,
        simulationIntensity: _simulationIntensity,
        lookStrength: _lookStrength,
        videoOrientation: _captureVideoOrientation,
        cameraPosition: _captureCameraPosition,
        lensMode: _lensMode,
        captureFormat: _captureFormatForCurrentPhoto
      )
    }
    sessionQueue.async {
      guard self.hasPendingCapture() else { return }
      autoreleasepool {
        if captureState.captureFormat == .raw || captureState.captureFormat == .proRaw {
          self.processRawCapture(
            photoData: photoData,
            error: error,
            captureState: captureState
          )
          return
        }
        if captureState.captureFormat.hasRawCompanion,
          captureState.captureFormat.hasProcessedCompanion
        {
          self.processRawPlusProcessedCaptureFrame(
            photo: photo,
            photoData: photoData,
            error: error,
            captureState: captureState
          )
          return
        }
        self.processCompressedCaptureFrame(
          photoData: photoData,
          photoMetadata: photoMetadata,
          bracketSettings: bracketSettings,
          error: error,
          captureState: captureState
        )
      }
    }
  }

  private func hasPendingCapture() -> Bool {
    return stateQueue.sync { captureCompletion != nil }
  }

  // MARK: - RAW Pipeline

  private func shouldUseExposureBracketing() -> Bool {
    let currentFormat = stateQueue.sync { _captureFormat }
    guard currentFormat.isProcessedCapture, !currentFormat.hasRawCompanion else {
      return false
    }
    guard let device = videoInput?.device else { return false }
    let highISO = device.iso > bracketISOThreshold
    let highContrast = stateQueue.sync {
      sceneContrastEstimate >= sceneContrastThreshold
    }
    return highISO || highContrast
  }

  private func prepareFrameCollection(expectedFrameCount: Int, bracketed: Bool) {
    bracketExpectedFrameCount = min(max(expectedFrameCount, 1), 5)
    bracketReceivedFrameCount = 0
    bracketFrames.removeAll(keepingCapacity: true)
    bracketFrames.reserveCapacity(bracketExpectedFrameCount)
    bracketSourceMetadata = nil
    isBracketCaptureActive = bracketed
  }

  private func resetFrameCollectionState() {
    bracketExpectedFrameCount = 1
    bracketReceivedFrameCount = 0
    bracketFrames.removeAll(keepingCapacity: false)
    bracketSourceMetadata = nil
    isBracketCaptureActive = false
  }

  private func makeBracketPhotoSettings() -> AVCapturePhotoBracketSettings? {
    guard !bracketExposureBiasValues.isEmpty else { return nil }
    let maxBracketCount = max(photoOutput.maxBracketedCapturePhotoCount, 0)
    guard maxBracketCount >= bracketExposureBiasValues.count else { return nil }
    let selectedBiasValues = bracketExposureBiasValues
    let bracketSettings: [AVCaptureBracketedStillImageSettings] = selectedBiasValues.map {
      AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(
        exposureTargetBias: $0
      )
    }

    let requestedFormat = stateQueue.sync { _captureFormat }
    let processedFormat: [String: Any]
    let activeFormat: CameraControllerCaptureFormat
    if requestedFormat == .jpg,
      photoOutput.availablePhotoCodecTypes.contains(.jpeg)
    {
      processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
      activeFormat = .jpg
    } else if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
      processedFormat = [AVVideoCodecKey: AVVideoCodecType.hevc]
      activeFormat = .heic
    } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
      processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
      activeFormat = .jpg
    } else {
      return nil
    }

    let settings = AVCapturePhotoBracketSettings(
      rawPixelFormatType: 0,
      processedFormat: processedFormat,
      bracketedSettings: bracketSettings
    )
    if #available(iOS 16.0, *) {
      let maxDimensions = photoOutput.maxPhotoDimensions
      if maxDimensions.width > 0, maxDimensions.height > 0 {
        settings.maxPhotoDimensions = maxDimensions
      }
    }
    settings.isHighResolutionPhotoEnabled = true
    if #available(iOS 13.0, *) {
      settings.photoQualityPrioritization = .quality
    }
    if photoOutput.isVirtualDeviceFusionSupported {
      settings.isAutoVirtualDeviceFusionEnabled = true
    }
    if photoOutput.isDepthDataDeliverySupported {
      settings.isDepthDataDeliveryEnabled = false
    }
    if activeFormat == .heic,
      photoOutput.availablePhotoCodecTypes.contains(.hevc)
    {
      settings.embeddedThumbnailPhotoFormat = [
        AVVideoCodecKey: AVVideoCodecType.hevc
      ]
    }
    stateQueue.sync {
      _captureFormatForCurrentPhoto = activeFormat
      _captureFormat = activeFormat
    }
    return settings
  }

  private func failCaptureOnSessionQueue(_ error: Error) {
    resetRawPlusProcessedBuffers()
    resetFrameCollectionState()
    restoreExposureAfterCaptureIfNeeded()
    finishCapture(.failure(error))
  }

  private func processRawCapture(
    photoData: Data?,
    error: Error?,
    captureState: CaptureSnapshot
  ) {
    if let error {
      failCaptureOnSessionQueue(error)
      return
    }
    guard let photoData else {
      failCaptureOnSessionQueue(CameraControllerError.photoDataUnavailable)
      return
    }

    resetFrameCollectionState()
    restoreExposureAfterCaptureIfNeeded()
    let captureOrientation = ciImageOrientation(
      for: captureState.videoOrientation,
      cameraPosition: captureState.cameraPosition
    )
    let orientedImage = CIImage(
      data: photoData,
      options: [.applyOrientationProperty: false]
    )?.oriented(captureOrientation)
    guard let tempPath = writeTempCapture(data: photoData, fileExtension: "dng") else {
      finishCapture(.failure(CameraControllerError.photoEncodingFailed))
      return
    }
    let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)
    if let orientedImage {
      storeLatestThumbnail(from: orientedImage)
    }
    let payload: [String: Any] = [
      "localIdentifier": nil as String?,
      "filePath": tempPath,
      "simulationId": captureState.simulationId,
      "lookStrength": captureState.lookStrength,
      "mimeType": "image/x-adobe-dng",
      "width": orientedImage.map { Int($0.extent.width.rounded()) } as Any,
      "height": orientedImage.map { Int($0.extent.height.rounded()) } as Any,
      "captureFormat": captureState.captureFormat.rawValue,
      "capturedAt": capturedAtMs,
      "savedAtMs": capturedAtMs
    ]
    finishCapture(
      .success(
        enrichedCapturePayload(
          payload,
          metadata: normalizedMetadata(from: photoData),
          captureState: captureState
        )
      )
    )
  }

  private func processRawPlusProcessedCaptureFrame(
    photo: AVCapturePhoto,
    photoData: Data?,
    error: Error?,
    captureState: CaptureSnapshot
  ) {
    if let error {
      failCaptureOnSessionQueue(error)
      return
    }
    guard let photoData else {
      failCaptureOnSessionQueue(CameraControllerError.photoDataUnavailable)
      return
    }

    if photo.isRawPhoto {
      rawPlusProcessedRawData = photoData
    } else {
      rawPlusProcessedProcessedData = photoData
      rawPlusProcessedProcessedMetadata = photo.metadata
    }

    guard
      let rawData = rawPlusProcessedRawData,
      let processedData = rawPlusProcessedProcessedData
    else {
      return
    }

    let processedMetadata = rawPlusProcessedProcessedMetadata ?? [:]
    resetRawPlusProcessedBuffers()
    resetFrameCollectionState()
    restoreExposureAfterCaptureIfNeeded()
    completeRawPlusProcessedCapture(
      rawData: rawData,
      processedData: processedData,
      processedMetadata: processedMetadata,
      captureState: captureState
    )
  }

  private func completeRawPlusProcessedCapture(
    rawData: Data,
    processedData: Data,
    processedMetadata: [AnyHashable: Any],
    captureState: CaptureSnapshot
  ) {
    let captureOrientation = ciImageOrientation(
      for: captureState.videoOrientation,
      cameraPosition: captureState.cameraPosition
    )
    guard
      let processedCIImage = CIImage(
        data: processedData,
        options: [.applyOrientationProperty: false]
      )
    else {
      finishCapture(.failure(CameraControllerError.photoDataUnavailable))
      return
    }

    let orientedProcessed = processedCIImage.oriented(captureOrientation)
    let sourceMetadata = processedMetadata.isEmpty
      ? normalizedMetadata(from: processedData)
      : normalizedMetadataFromDictionary(processedMetadata)

    // Final still processing:
    // 1. neutral base preparation
    // 2. creative look transform
    // 3. still-only polish
    let captureISO = currentCaptureISOOnSessionQueue()
    let finalProcessed = stillRenderPipeline.render(
      orientedProcessed,
      simulationId: captureState.simulationId,
      simulationIntensity: captureState.simulationIntensity,
      lookStrength: captureState.lookStrength,
      allowEnhancement: true,
      shouldDenoise: shouldApplyStillNoiseReductionOnSessionQueue(),
      captureISO: captureISO
    )

    guard
      let processedCaptureFormat = captureState.captureFormat.processedCaptureFormat,
      let encodedProcessed = encodeCaptureImage(
        finalProcessed,
        sourceMetadata: sourceMetadata,
        captureFormat: processedCaptureFormat
      )
    else {
      finishCapture(.failure(CameraControllerError.photoEncodingFailed))
      return
    }

    guard
      let rawTempPath = writeTempCapture(data: rawData, fileExtension: "dng"),
      let processedTempPath = writeTempCapture(
        data: encodedProcessed.data,
        fileExtension: encodedProcessed.fileExtension
      )
    else {
      finishCapture(.failure(CameraControllerError.photoEncodingFailed))
      return
    }

    storeLatestThumbnail(from: finalProcessed)
    let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)

    let payload: [String: Any] = [
      "localIdentifier": nil as String?,
      "rawLocalIdentifier": nil as String?,
      "filePath": processedTempPath,
      "rawFilePath": rawTempPath,
      "simulationId": captureState.simulationId,
      "lookStrength": captureState.lookStrength,
      "mimeType": encodedProcessed.mimeType,
      "rawMimeType": "image/x-adobe-dng",
      "width": Int(finalProcessed.extent.width.rounded()),
      "height": Int(finalProcessed.extent.height.rounded()),
      "captureFormat": captureState.captureFormat.rawValue,
      "capturedAt": capturedAtMs,
      "savedAtMs": capturedAtMs
    ]
    finishCapture(
      .success(
        enrichedCapturePayload(
          payload,
          metadata: sourceMetadata,
          captureState: captureState
        )
      )
    )
  }

  // MARK: - Processed Still Pipeline

  private func processCompressedCaptureFrame(
    photoData: Data?,
    photoMetadata: [AnyHashable: Any],
    bracketSettings: AVCaptureBracketedStillImageSettings?,
    error: Error?,
    captureState: CaptureSnapshot
  ) {
    if let error {
      failCaptureOnSessionQueue(error)
      return
    }
    guard let photoData else {
      failCaptureOnSessionQueue(CameraControllerError.photoDataUnavailable)
      return
    }

    let captureOrientation = ciImageOrientation(
      for: captureState.videoOrientation,
      cameraPosition: captureState.cameraPosition
    )
    guard
      let ciImage = CIImage(
        data: photoData,
        options: [.applyOrientationProperty: false]
      )
    else {
      failCaptureOnSessionQueue(CameraControllerError.photoDataUnavailable)
      return
    }
    let orientedImage = ciImage.oriented(captureOrientation)
    if bracketSourceMetadata == nil {
      bracketSourceMetadata = normalizedMetadata(from: photoData)
    }
    let frameBias = exposureBiasValue(from: bracketSettings) ??
      exposureBiasValue(from: photoMetadata) ??
      fallbackBracketBias(forFrameIndex: bracketReceivedFrameCount)
    bracketFrames.append(BracketFrame(image: orientedImage, exposureBias: frameBias))
    bracketReceivedFrameCount += 1

    guard bracketReceivedFrameCount >= bracketExpectedFrameCount else {
      return
    }

    let fallbackImage =
      preferredBracketFallbackFrame(from: bracketFrames)?.image ?? orientedImage
    let mergedImage =
      isBracketCaptureActive ? (mergeBracketedFrames(bracketFrames) ?? fallbackImage) : fallbackImage
    let sourceMetadata = bracketSourceMetadata ?? normalizedMetadata(from: photoData)

    resetFrameCollectionState()
    restoreExposureAfterCaptureIfNeeded()
    completeProcessedCompressedCapture(
      mergedImage,
      sourceMetadata: sourceMetadata,
      captureState: captureState
    )
  }

  private func completeProcessedCompressedCapture(
    _ orientedImage: CIImage,
    sourceMetadata: [String: Any],
    captureState: CaptureSnapshot
  ) {
    // Final still processing:
    // 1. neutral base preparation
    // 2. creative look transform
    // 3. still-only polish
    let captureISO = currentCaptureISOOnSessionQueue()
    let finalImage = stillRenderPipeline.render(
      orientedImage,
      simulationId: captureState.simulationId,
      simulationIntensity: captureState.simulationIntensity,
      lookStrength: captureState.lookStrength,
      allowEnhancement: true,
      shouldDenoise: shouldApplyStillNoiseReductionOnSessionQueue(),
      captureISO: captureISO
    )

    guard
      let encoded = encodeCaptureImage(
        finalImage,
        sourceMetadata: sourceMetadata,
        captureFormat: captureState.captureFormat
      )
    else {
      finishCapture(.failure(CameraControllerError.photoEncodingFailed))
      return
    }

    guard
      let tempPath = writeTempCapture(
        data: encoded.data,
        fileExtension: encoded.fileExtension
      )
    else {
      finishCapture(.failure(CameraControllerError.photoEncodingFailed))
      return
    }

    let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)
    storeLatestThumbnail(from: finalImage)
    let payload: [String: Any] = [
      "localIdentifier": nil as String?,
      "filePath": tempPath,
      "simulationId": captureState.simulationId,
      "lookStrength": captureState.lookStrength,
      "mimeType": encoded.mimeType,
      "width": Int(finalImage.extent.width.rounded()),
      "height": Int(finalImage.extent.height.rounded()),
      "captureFormat": captureState.captureFormat.rawValue,
      "capturedAt": capturedAtMs,
      "savedAtMs": capturedAtMs
    ]
    finishCapture(
      .success(
        enrichedCapturePayload(
          payload,
          metadata: sourceMetadata,
          captureState: captureState
        )
      )
    )
  }

  private func exposureBiasValue(from metadata: [AnyHashable: Any]) -> Float? {
    guard let exif = metadata[kCGImagePropertyExifDictionary as String] as? [AnyHashable: Any] else {
      return nil
    }
    if let value = (exif[kCGImagePropertyExifExposureBiasValue as String] as? NSNumber)?.floatValue {
      return value
    }
    if let value = (exif["ExposureBiasValue"] as? NSNumber)?.floatValue {
      return value
    }
    return nil
  }

  private func exposureBiasValue(
    from bracketSettings: AVCaptureBracketedStillImageSettings?
  ) -> Float? {
    guard
      let autoExposureSettings =
        bracketSettings as? AVCaptureAutoExposureBracketedStillImageSettings
    else {
      return nil
    }
    return autoExposureSettings.exposureTargetBias
  }

  private func fallbackBracketBias(forFrameIndex index: Int) -> Float {
    guard isBracketCaptureActive else { return 0.0 }
    guard !bracketExposureBiasValues.isEmpty else { return 0.0 }
    let safeIndex = min(max(index, 0), bracketExposureBiasValues.count - 1)
    return bracketExposureBiasValues[safeIndex]
  }

  private func preferredBracketFallbackFrame(from frames: [BracketFrame]) -> BracketFrame? {
    guard !frames.isEmpty else { return nil }
    return frames.min(by: { abs($0.exposureBias) < abs($1.exposureBias) }) ??
      frames[frames.count / 2]
  }

  private func mergeBracketedFrames(_ frames: [BracketFrame]) -> CIImage? {
    guard frames.count >= 3, let selection = selectBracketFrames(from: frames) else {
      return nil
    }
    let middleImage = selection.middle.image
    let darkerFrame = frameAligner.align(selection.dark.image, to: middleImage)
    let brighterFrame = frameAligner.align(selection.bright.image, to: middleImage)

    let highlightFrame = darkerFrame.applyingFilter(
      "CIExposureAdjust",
      parameters: [kCIInputEVKey: 0.14]
    ).cropped(to: middleImage.extent)
    let shadowFrame = brighterFrame.applyingFilter(
      "CIExposureAdjust",
      parameters: [kCIInputEVKey: -0.18]
    ).cropped(to: middleImage.extent)

    let luminanceMask = makeLuminanceMask(from: middleImage)
    let softenedLuminanceMask = luminanceMask
      .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 7.0])
      .cropped(to: middleImage.extent)

    let highlightMask = softenedLuminanceMask.applyingFilter(
      "CIToneCurve",
      parameters: [
        "inputPoint0": CIVector(x: 0, y: 0),
        "inputPoint1": CIVector(x: 0.52, y: 0.0),
        "inputPoint2": CIVector(x: 0.72, y: 0.16),
        "inputPoint3": CIVector(x: 0.88, y: 0.92),
        "inputPoint4": CIVector(x: 1, y: 1)
      ]
    ).cropped(to: middleImage.extent)

    let shadowMask = softenedLuminanceMask
      .applyingFilter("CIColorInvert")
      .applyingFilter(
        "CIToneCurve",
        parameters: [
          "inputPoint0": CIVector(x: 0, y: 0),
          "inputPoint1": CIVector(x: 0.18, y: 0.88),
          "inputPoint2": CIVector(x: 0.42, y: 0.24),
          "inputPoint3": CIVector(x: 0.74, y: 0),
          "inputPoint4": CIVector(x: 1, y: 0)
        ]
      )
      .cropped(to: middleImage.extent)

    let shadowRecovered = blendImage(shadowFrame, over: middleImage, mask: shadowMask)
    let highlightRecovered = blendImage(
      highlightFrame,
      over: shadowRecovered,
      mask: highlightMask
    )
    let compressedHighlights = highlightRecovered.applyingFilter(
      "CIHighlightShadowAdjust",
      parameters: [
        "inputShadowAmount": 0.14,
        "inputHighlightAmount": 0.18
      ]
    ).cropped(to: middleImage.extent)
    let restoredContrast = compressedHighlights.applyingFilter(
      "CIColorControls",
      parameters: [
        kCIInputContrastKey: 1.035,
        kCIInputSaturationKey: 1.0,
        kCIInputBrightnessKey: 0.0
      ]
    ).cropped(to: middleImage.extent)
    let naturalBlend = blendImageWithOpacity(
      restoredContrast,
      over: middleImage,
      opacity: 0.9
    )
    return naturalBlend.applyingFilter(
      "CIToneCurve",
      parameters: [
        "inputPoint0": CIVector(x: 0, y: 0),
        "inputPoint1": CIVector(x: 0.2, y: 0.18),
        "inputPoint2": CIVector(x: 0.5, y: 0.5),
        "inputPoint3": CIVector(x: 0.82, y: 0.85),
        "inputPoint4": CIVector(x: 1, y: 1)
      ]
    ).cropped(to: middleImage.extent)
  }

  private func selectBracketFrames(
    from frames: [BracketFrame]
  ) -> (dark: BracketFrame, middle: BracketFrame, bright: BracketFrame)? {
    guard !frames.isEmpty else { return nil }
    let sorted = frames.sorted { $0.exposureBias < $1.exposureBias }
    guard let dark = sorted.first, let bright = sorted.last else { return nil }
    let middle =
      sorted.min(by: { abs($0.exposureBias) < abs($1.exposureBias) }) ??
      sorted[sorted.count / 2]
    return (dark: dark, middle: middle, bright: bright)
  }

  private func makeLuminanceMask(from image: CIImage) -> CIImage {
    image.applyingFilter(
      "CIColorControls",
      parameters: [
        kCIInputSaturationKey: 0.0,
        kCIInputContrastKey: 1.0
      ]
    ).cropped(to: image.extent)
  }

  private func blendImage(
    _ foreground: CIImage,
    over background: CIImage,
    mask: CIImage
  ) -> CIImage {
    foreground.applyingFilter(
      "CIBlendWithMask",
      parameters: [
        kCIInputBackgroundImageKey: background,
        kCIInputMaskImageKey: mask
      ]
    ).cropped(to: background.extent)
  }

  private func blendImageWithOpacity(
    _ foreground: CIImage,
    over background: CIImage,
    opacity: CGFloat
  ) -> CIImage {
    let clampedOpacity = min(max(opacity, 0), 1)
    let alphaScaled = foreground.applyingFilter(
      "CIColorMatrix",
      parameters: [
        "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: clampedOpacity),
        "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
      ]
    )
    return alphaScaled.applyingFilter(
      "CISourceOverCompositing",
      parameters: [kCIInputBackgroundImageKey: background]
    ).cropped(to: background.extent)
  }

  // MARK: - Private

  private func configurePreviewView() {
    previewView.backgroundColor = .black
    previewView.clipsToBounds = true
    previewView.isUserInteractionEnabled = true
    previewView.onLayout = { [weak self] in
      self?.updateVideoOrientation()
    }

    let pinchRecognizer = UIPinchGestureRecognizer(
      target: self,
      action: #selector(handlePreviewPinchGesture(_:))
    )
    previewView.addGestureRecognizer(pinchRecognizer)

    previewImageView.translatesAutoresizingMaskIntoConstraints = false
    previewImageView.backgroundColor = .black
    previewImageView.contentMode = .scaleAspectFill
    previewImageView.clipsToBounds = true

    previewView.addSubview(previewImageView)
    NSLayoutConstraint.activate([
      previewImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
      previewImageView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
      previewImageView.topAnchor.constraint(equalTo: previewView.topAnchor),
      previewImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
    ])
  }

  // MARK: - Camera Configuration

  private func configureSession(completion: @escaping (Result<[String: Any], Error>) -> Void) {
    sessionQueue.async {
      self.cleanupExpiredTempCaptures()
      if self.isConfigured {
        _ = self.refreshPhotoConfigurationOnSessionQueue()
        let payload = self.cameraStatePayload(
          activeLensMode: self.activeLensMode(),
          exposureBias: self.exposureBias()
        )
        DispatchQueue.main.async {
          completion(.success(payload))
        }
        return
      }

      var didBeginConfiguration = false
      do {
        guard let device = self.availableDevice(for: .wide) else {
          throw CameraControllerError.noBackCamera
        }

        self.session.beginConfiguration()
        didBeginConfiguration = true
        defer {
          if didBeginConfiguration {
            self.session.commitConfiguration()
            didBeginConfiguration = false
          }
        }

        self.configureSession()

        let input = try AVCaptureDeviceInput(device: device)
        guard self.session.canAddInput(input) else {
          throw CameraControllerError.configurationFailed("Could not add camera input.")
        }
        self.session.addInput(input)
        self.videoInput = input

        let appliedExposure = self.configureDefaultDeviceState()
        try self.configurePhotoOutput()
        try self.configurePreviewPipeline()

        self.updateVideoOrientation()
        didBeginConfiguration = false
        self.session.commitConfiguration()
        self.stateQueue.sync {
          self._lensMode = .wide
        }
        self.applyRequestedCaptureFormatOnSessionQueue(self.defaultCaptureFormatOnSessionQueue())
        _ = self.refreshPhotoConfigurationOnSessionQueue(device: device)
        self.isConfigured = true
        let payload = self.cameraStatePayload(
          activeLensMode: .wide,
          exposureBias: appliedExposure
        )
        DispatchQueue.main.async {
          completion(.success(payload))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }

  /// Capture-session configuration defaults.
  /// Must be invoked from `sessionQueue`.
  private func configureSession() {
    session.automaticallyConfiguresCaptureDeviceForWideColor = true
    if session.canSetSessionPreset(.photo) {
      session.sessionPreset = .photo
    } else {
      session.sessionPreset = .high
    }
  }

  /// Processed still capture output defaults.
  /// Must be invoked from `sessionQueue`.
  private func configurePhotoOutput() throws {
    guard session.canAddOutput(photoOutput) else {
      throw CameraControllerError.configurationFailed("Could not add photo output.")
    }
    session.addOutput(photoOutput)
    configureRawCaptureSupportOnSessionQueue()
    photoOutput.isHighResolutionCaptureEnabled = true
    if #available(iOS 13.0, *) {
      photoOutput.maxPhotoQualityPrioritization = .quality
    }
  }

  /// Enables additional RAW capability, such as Apple ProRAW, when the current
  /// device/output configuration supports it.
  /// Must be invoked from `sessionQueue`.
  private func configureRawCaptureSupportOnSessionQueue() {
    if #available(iOS 14.3, *) {
      let shouldEnableAppleProRAW = photoOutput.isAppleProRAWSupported
      if photoOutput.isAppleProRAWEnabled != shouldEnableAppleProRAW {
        photoOutput.isAppleProRAWEnabled = shouldEnableAppleProRAW
      }
    }
  }

  /// Primary camera device startup state.
  /// Must be invoked from `sessionQueue`.
  @discardableResult
  private func configureDefaultDeviceState() -> Double {
    guard let device = videoInput?.device else {
      return exposureBias()
    }
    applyPreferredPhotoCaptureFormat(to: device)
    applyDefaultAutoFocusAndExposure(to: device)
    applyPreferredCaptureColorSpace(to: device)
    let appliedExposure = (try? applyExposureBias(exposureBias(), to: device)) ?? exposureBias()
    _ = applyZoomFactorOnSessionQueue(1.0, emitUpdate: false)
    stateQueue.sync {
      _lensMode = .wide
      _isAeAfLocked = false
      _supportsManualFocus = device.isFocusModeSupported(.locked)
      _focusDistance = Double(device.lensPosition)
      _isManualFocusActive = false
    }
    return appliedExposure
  }

  /// Preview data-output pipeline wiring.
  /// Must be invoked from `sessionQueue`.
  private func configurePreviewPipeline() throws {
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
    ]
    videoOutput.setSampleBufferDelegate(self, queue: previewQueue)

    guard session.canAddOutput(videoOutput) else {
      throw CameraControllerError.configurationFailed("Could not add video output.")
    }
    session.addOutput(videoOutput)
  }

  private func availableDevice(for mode: CameraControllerLensMode) -> AVCaptureDevice? {
    let preferredTypes: [AVCaptureDevice.DeviceType]
    switch mode {
    case .wide:
      if #available(iOS 13.0, *) {
        preferredTypes = [
          .builtInTripleCamera,
          .builtInDualWideCamera,
          .builtInDualCamera,
          .builtInWideAngleCamera,
        ]
      } else {
        preferredTypes = [.builtInWideAngleCamera]
      }
    case .ultraWide:
      preferredTypes = [.builtInUltraWideCamera]
    }

    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: preferredTypes,
      mediaType: .video,
      position: .back
    )

    if mode == .wide, let preferredWideDevice = preferredWideDevice(from: discovery.devices, ranking: preferredTypes) {
      return preferredWideDevice
    }

    for type in preferredTypes {
      if let matched = discovery.devices.first(where: { $0.deviceType == type }) {
        return matched
      }
    }
    return discovery.devices.first
  }

  private func dedicatedWideAngleDevice() -> AVCaptureDevice? {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: .back
    ).devices.first
  }

  private func shouldPreferDedicatedWideAngleDevice(
    for captureFormat: CameraControllerCaptureFormat,
    preferredResolution: CameraPhotoResolutionOption?
  ) -> Bool {
    if captureFormat.hasRawCompanion {
      return true
    }
    guard let preferredResolution else {
      return false
    }
    return preferredResolution.megapixels > 12.5
  }

  private func preferredCaptureDevice(
    for lensMode: CameraControllerLensMode,
    captureFormat: CameraControllerCaptureFormat,
    preferredResolution: CameraPhotoResolutionOption?
  ) -> AVCaptureDevice? {
    let resolvedLensMode = resolvedLensMode(
      for: lensMode,
      captureFormat: captureFormat
    )
    switch resolvedLensMode {
    case .wide:
      if shouldPreferDedicatedWideAngleDevice(
        for: captureFormat,
        preferredResolution: preferredResolution
      ),
        let dedicatedDevice = dedicatedWideAngleDevice()
      {
        return dedicatedDevice
      }
      return availableDevice(for: .wide)
    case .ultraWide:
      return availableDevice(for: .ultraWide)
    }
  }

  @discardableResult
  private func reconcileCaptureDeviceOnSessionQueue(
    preferredLensMode: CameraControllerLensMode? = nil,
    preferredCaptureFormat: CameraControllerCaptureFormat? = nil,
    preferredResolution: CameraPhotoResolutionOption? = nil
  ) throws -> AVCaptureDevice? {
    let captureFormat = preferredCaptureFormat ?? stateQueue.sync { _captureFormat }
    let requestedLensMode = preferredLensMode ?? stateQueue.sync { _lensMode }
    let lensMode = resolvedLensMode(
      for: requestedLensMode,
      captureFormat: captureFormat
    )
    let selectedResolution = preferredResolution ?? stateQueue.sync { _selectedPhotoResolution }

    guard
      let targetDevice = preferredCaptureDevice(
        for: lensMode,
        captureFormat: captureFormat,
        preferredResolution: selectedResolution
      )
    else {
      return videoInput?.device
    }

    if videoInput?.device.uniqueID != targetDevice.uniqueID {
      try switchInput(to: targetDevice)
    }

    stateQueue.sync {
      _lensMode = lensMode
    }
    if captureFormat == .proRaw {
      _ = applyZoomFactorOnSessionQueue(1.0, emitUpdate: false)
    }
    return videoInput?.device
  }

  private func switchInput(to device: AVCaptureDevice) throws {
    let newInput = try AVCaptureDeviceInput(device: device)
    let oldInput = videoInput

    session.beginConfiguration()
    if let oldInput {
      session.removeInput(oldInput)
    }

    guard session.canAddInput(newInput) else {
      if let oldInput, session.canAddInput(oldInput) {
        session.addInput(oldInput)
      }
      session.commitConfiguration()
      throw CameraControllerError.configurationFailed("Could not switch camera lens.")
    }

    session.addInput(newInput)
    videoInput = newInput
    applyPreferredPhotoCaptureFormat(to: device)
    configureRawCaptureSupportOnSessionQueue()
    let requestedBias = stateQueue.sync { _exposureBias }
    _ = try? applyExposureBias(requestedBias, to: device)
    applyDefaultAutoFocusAndExposure(to: device)
    applyPreferredCaptureColorSpace(to: device)
    stateQueue.sync {
      _supportsManualFocus = device.isFocusModeSupported(.locked)
      _focusDistance = Double(device.lensPosition)
      _isManualFocusActive = false
    }

    updateVideoOrientation()
    session.commitConfiguration()
    _ = refreshPhotoConfigurationOnSessionQueue(device: device)
  }

  private func makePhotoSettings() -> AVCapturePhotoSettings {
    let requestedFormat = stateQueue.sync { _captureFormat }
    var activeFormat: CameraControllerCaptureFormat = .heic
    var configuredSettings: AVCapturePhotoSettings?
    var usingBayerRAW = false

    func configureRawType(_ rawType: OSType) {
      if #available(iOS 14.3, *) {
        usingBayerRAW = AVCapturePhotoOutput.isBayerRAWPixelFormat(rawType)
      }
    }

    func makeRawSettings(
      rawType: OSType,
      processedCodec: AVVideoCodecType? = nil
    ) -> AVCapturePhotoSettings {
      configureRawType(rawType)
      if let processedCodec {
        return AVCapturePhotoSettings(
          rawPixelFormatType: rawType,
          processedFormat: [AVVideoCodecKey: processedCodec]
        )
      }
      return AVCapturePhotoSettings(rawPixelFormatType: rawType)
    }

    switch requestedFormat {
    case .rawPlusHeic:
      let preferredRawType = preferredRawPhotoPixelFormatTypeOnSessionQueue(
        for: .rawPlusHeic
      )
      if let rawType = preferredRawType,
        photoOutput.availablePhotoCodecTypes.contains(.hevc)
      {
        configuredSettings = makeRawSettings(
          rawType: rawType,
          processedCodec: .hevc
        )
        activeFormat = .rawPlusHeic
      }
    case .rawPlusJpg:
      let preferredRawType = preferredRawPhotoPixelFormatTypeOnSessionQueue(
        for: .rawPlusJpg
      )
      if let rawType = preferredRawType,
        photoOutput.availablePhotoCodecTypes.contains(.jpeg)
      {
        configuredSettings = makeRawSettings(
          rawType: rawType,
          processedCodec: .jpeg
        )
        activeFormat = .rawPlusJpg
      }
    case .raw:
      let preferredRawType = preferredRawPhotoPixelFormatTypeOnSessionQueue(
        for: .raw
      )
      if let rawType = preferredRawType {
        configuredSettings = makeRawSettings(rawType: rawType)
        activeFormat = .raw
      }
    case .proRaw:
      let preferredRawType = preferredRawPhotoPixelFormatTypeOnSessionQueue(
        for: .proRaw
      )
      if let rawType = preferredRawType {
        configuredSettings = makeRawSettings(rawType: rawType)
        activeFormat = .proRaw
      }
    case .jpg:
      if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
        configuredSettings = AVCapturePhotoSettings(
          format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
        )
        activeFormat = .jpg
      }
    case .heic:
      if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        configuredSettings = AVCapturePhotoSettings(
          format: [AVVideoCodecKey: AVVideoCodecType.hevc]
        )
        activeFormat = .heic
      }
    }

    if configuredSettings == nil {
      if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        configuredSettings = AVCapturePhotoSettings(
          format: [AVVideoCodecKey: AVVideoCodecType.hevc]
        )
        activeFormat = .heic
      } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
        configuredSettings = AVCapturePhotoSettings(
          format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
        )
        activeFormat = .jpg
      } else if let rawType = preferredRawPhotoPixelFormatTypeOnSessionQueue(
        for: .raw
      ) {
        configuredSettings = makeRawSettings(rawType: rawType)
        activeFormat = .raw
      }
    }

    var settings = configuredSettings ?? AVCapturePhotoSettings()
    if #available(iOS 16.0, *) {
      let preferredDimensions = stateQueue.sync { _selectedPhotoResolution?.dimensions }
      let maxDimensions = preferredDimensions ?? photoOutput.maxPhotoDimensions
      if maxDimensions.width > 0, maxDimensions.height > 0 {
        settings.maxPhotoDimensions = maxDimensions
      }
    }
    if activeFormat.processedCaptureFormat == .heic,
      photoOutput.availablePhotoCodecTypes.contains(.hevc)
    {
      settings.embeddedThumbnailPhotoFormat = [
        AVVideoCodecKey: AVVideoCodecType.hevc
      ]
    } else if activeFormat.processedCaptureFormat == .jpg,
      photoOutput.availablePhotoCodecTypes.contains(.jpeg)
    {
      settings.embeddedThumbnailPhotoFormat = [
        AVVideoCodecKey: AVVideoCodecType.jpeg
      ]
    }
    settings.isHighResolutionPhotoEnabled = activeFormat.isProcessedCapture
    if #available(iOS 13.0, *) {
      settings.photoQualityPrioritization = usingBayerRAW ? .speed : .quality
    }
    if photoOutput.isStillImageStabilizationSupported {
      settings.isAutoStillImageStabilizationEnabled = !usingBayerRAW
    }
    if photoOutput.isVirtualDeviceFusionSupported {
      settings.isAutoVirtualDeviceFusionEnabled = !usingBayerRAW
    }
    if photoOutput.isDepthDataDeliverySupported {
      settings.isDepthDataDeliveryEnabled = false
    }
    stateQueue.sync {
      _captureFormatForCurrentPhoto = activeFormat
      _captureFormat = activeFormat
    }

    let flash = stateQueue.sync { _flashMode }
    if let device = videoInput?.device, device.isFlashAvailable {
      switch flash {
      case .auto:
        settings.flashMode = .auto
      case .off:
        settings.flashMode = .off
      case .on:
        settings.flashMode = .on
      }
    }
    return settings
  }

  private struct EncodedCapture {
    let data: Data
    let uti: String
    let fileExtension: String
    let mimeType: String
  }

  private func encodeCaptureImage(
    _ image: CIImage,
    sourceMetadata: [String: Any],
    captureFormat: CameraControllerCaptureFormat
  ) -> EncodedCapture? {
    guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
      return nil
    }

    var metadata = sourceMetadata
    metadata[kCGImagePropertyOrientation as String] = 1
    if metadata[kCGImagePropertyGPSDictionary as String] == nil,
      let gpsMetadata = currentLocationMetadata()
    {
      metadata[kCGImagePropertyGPSDictionary as String] = gpsMetadata
    }

    let targets: [(uti: String, fileExtension: String, mimeType: String)]
    switch captureFormat {
    case .heic:
      if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        targets = [("public.heic", "heic", "image/heic")]
      } else {
        targets = [("public.jpeg", "jpg", "image/jpeg")]
      }
    case .jpg:
      targets = [("public.jpeg", "jpg", "image/jpeg")]
    case .rawPlusHeic:
      guard photoOutput.availablePhotoCodecTypes.contains(.hevc) else {
        return nil
      }
      targets = [("public.heic", "heic", "image/heic")]
    case .rawPlusJpg:
      guard photoOutput.availablePhotoCodecTypes.contains(.jpeg) else {
        return nil
      }
      targets = [("public.jpeg", "jpg", "image/jpeg")]
    case .raw, .proRaw:
      return nil
    }

    for target in targets {
      if let data = encodeImageData(
        cgImage,
        uti: target.uti,
        metadata: metadata,
        compressionQuality: 1.0
      ) {
        return EncodedCapture(
          data: data,
          uti: target.uti,
          fileExtension: target.fileExtension,
          mimeType: target.mimeType
        )
      }
    }
    return nil
  }

  private func encodeImageData(
    _ cgImage: CGImage,
    uti: String,
    metadata: [String: Any],
    compressionQuality: Double
  ) -> Data? {
    let mutableData = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        mutableData,
        uti as CFString,
        1,
        nil
      )
    else {
      return nil
    }

    var imageProperties = metadata
    imageProperties[kCGImageDestinationLossyCompressionQuality as String] =
      compressionQuality

    CGImageDestinationAddImage(destination, cgImage, imageProperties as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }
    return mutableData as Data
  }

  private func currentCaptureISOOnSessionQueue() -> Float? {
    videoInput?.device.iso
  }

  private func updateLocationCaptureState() {
    guard CLLocationManager.locationServicesEnabled() else {
      locationManager.stopUpdatingLocation()
      return
    }

    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      locationManager.startUpdatingLocation()
    case .notDetermined:
      guard !hasRequestedLocationAuthorization else { return }
      hasRequestedLocationAuthorization = true
      locationManager.requestWhenInUseAuthorization()
    default:
      locationManager.stopUpdatingLocation()
    }
  }

  private func enrichedCapturePayload(
    _ payload: [String: Any],
    metadata: [String: Any],
    captureState: CaptureSnapshot
  ) -> [String: Any] {
    var output = payload

    let exif = metadataDictionary(
      metadata[kCGImagePropertyExifDictionary as String]
    ) ?? [:]
    let tiff = metadataDictionary(
      metadata[kCGImagePropertyTIFFDictionary as String]
    ) ?? [:]
    let gps = metadataDictionary(
      metadata[kCGImagePropertyGPSDictionary as String]
    ) ?? [:]
    let device = videoInput?.device

    let isoValue =
      metadataISO(from: exif) ??
      currentCaptureISOOnSessionQueue().map(Double.init)
    if let isoValue {
      output["iso"] = isoValue
    }

    let exposureSeconds =
      metadataDouble(
        from: exif,
        keys: [
          kCGImagePropertyExifExposureTime as String,
          "ExposureTime",
        ]
      ) ??
      currentExposureDurationOnSessionQueue()
    if let exposureSeconds,
      let shutterSpeed = formattedShutterSpeed(seconds: exposureSeconds)
    {
      output["shutterSpeed"] = shutterSpeed
    }

    let aperture =
      metadataDouble(
        from: exif,
        keys: [
          kCGImagePropertyExifFNumber as String,
          "FNumber",
        ]
      ) ??
      device.map { Double($0.lensAperture) }
    if let aperture {
      output["aperture"] = aperture
    }

    let focalLength = metadataDouble(
      from: exif,
      keys: [
        kCGImagePropertyExifFocalLength as String,
        "FocalLength",
      ]
    )
    if let focalLength {
      output["focalLength"] = focalLength
    }

    let lens =
      metadataString(
        from: exif,
        keys: [
          kCGImagePropertyExifLensModel as String,
          "LensModel",
        ]
      ) ??
      metadataString(
        from: tiff,
        keys: [
          kCGImagePropertyTIFFModel as String,
          "Model",
        ]
      ) ??
      fallbackLensLabel(for: captureState.lensMode)
    if !lens.isEmpty {
      output["lens"] = lens
    }

    if let location = formattedLocation(from: gps) ?? currentLocationDescription() {
      output["location"] = location
    }

    return output
  }

  private func metadataDictionary(_ value: Any?) -> [AnyHashable: Any]? {
    if let dictionary = value as? [AnyHashable: Any] {
      return dictionary
    }
    if let dictionary = value as? [String: Any] {
      var output: [AnyHashable: Any] = [:]
      for (key, nestedValue) in dictionary {
        output[key] = nestedValue
      }
      return output
    }
    return nil
  }

  private func metadataDouble(
    from dictionary: [AnyHashable: Any],
    keys: [String]
  ) -> Double? {
    for key in keys {
      if let value = (dictionary[key] as? NSNumber)?.doubleValue {
        return value
      }
      if let array = dictionary[key] as? [NSNumber],
        let first = array.first
      {
        return first.doubleValue
      }
      if let array = dictionary[key] as? [Any],
        let first = array.first as? NSNumber
      {
        return first.doubleValue
      }
    }
    return nil
  }

  private func metadataString(
    from dictionary: [AnyHashable: Any],
    keys: [String]
  ) -> String? {
    for key in keys {
      if let value = dictionary[key] as? String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          return trimmed
        }
      }
    }
    return nil
  }

  private func metadataISO(from exif: [AnyHashable: Any]) -> Double? {
    if let iso = metadataDouble(
      from: exif,
      keys: [
        "PhotographicSensitivity",
      ]
    ) {
      return iso
    }
    return metadataDouble(
      from: exif,
      keys: [
        kCGImagePropertyExifISOSpeedRatings as String,
        "ISOSpeedRatings",
      ]
    )
  }

  private func currentExposureDurationOnSessionQueue() -> Double? {
    guard let duration = videoInput?.device.exposureDuration.seconds,
      duration.isFinite,
      duration > 0
    else {
      return nil
    }
    return duration
  }

  private func formattedShutterSpeed(seconds: Double) -> String? {
    guard seconds.isFinite, seconds > 0 else {
      return nil
    }
    if seconds >= 1 {
      let rounded = seconds.rounded()
      if abs(seconds - rounded) < 0.05 {
        return "\(Int(rounded))s"
      }
      return String(format: "%.1fs", seconds)
    }
    let reciprocal = 1.0 / seconds
    let denominator = max(Int(reciprocal.rounded()), 1)
    return "1/\(denominator)"
  }

  private func fallbackLensLabel(for lensMode: CameraControllerLensMode) -> String {
    switch lensMode {
    case .wide:
      return "Wide"
    case .ultraWide:
      return "Ultra Wide"
    }
  }

  private func formattedLocation(from gps: [AnyHashable: Any]) -> String? {
    guard
      let latitude = metadataDouble(
        from: gps,
        keys: [
          kCGImagePropertyGPSLatitude as String,
          "Latitude",
        ]
      ),
      let longitude = metadataDouble(
        from: gps,
        keys: [
          kCGImagePropertyGPSLongitude as String,
          "Longitude",
        ]
      )
    else {
      return nil
    }

    var signedLatitude = latitude
    if let latitudeRef = metadataString(
      from: gps,
      keys: [
        kCGImagePropertyGPSLatitudeRef as String,
        "LatitudeRef",
      ]
    ),
      latitudeRef.uppercased() == "S"
    {
      signedLatitude *= -1
    }

    var signedLongitude = longitude
    if let longitudeRef = metadataString(
      from: gps,
      keys: [
        kCGImagePropertyGPSLongitudeRef as String,
        "LongitudeRef",
      ]
    ),
      longitudeRef.uppercased() == "W"
    {
      signedLongitude *= -1
    }

    return String(format: "%.5f, %.5f", signedLatitude, signedLongitude)
  }

  private func currentLocation() -> CLLocation? {
    stateQueue.sync { _latestLocation }
  }

  private func currentLocationDescription() -> String? {
    guard let location = currentLocation() else {
      return nil
    }
    return String(
      format: "%.5f, %.5f",
      location.coordinate.latitude,
      location.coordinate.longitude
    )
  }

  private func currentLocationMetadata() -> [String: Any]? {
    guard let location = currentLocation() else {
      return nil
    }

    var metadata: [String: Any] = [
      kCGImagePropertyGPSLatitude as String: abs(location.coordinate.latitude),
      kCGImagePropertyGPSLatitudeRef as String:
        location.coordinate.latitude < 0 ? "S" : "N",
      kCGImagePropertyGPSLongitude as String: abs(location.coordinate.longitude),
      kCGImagePropertyGPSLongitudeRef as String:
        location.coordinate.longitude < 0 ? "W" : "E",
      kCGImagePropertyGPSDateStamp as String:
        gpsDateFormatter.string(from: location.timestamp),
      kCGImagePropertyGPSTimeStamp as String:
        gpsTimeFormatter.string(from: location.timestamp),
    ]

    if location.altitude.isFinite {
      metadata[kCGImagePropertyGPSAltitude as String] = abs(location.altitude)
      metadata[kCGImagePropertyGPSAltitudeRef as String] =
        location.altitude < 0 ? 1 : 0
    }

    return metadata
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    updateLocationCaptureState()
  }

  func locationManager(
    _ manager: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    updateLocationCaptureState()
  }

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last else {
      return
    }
    stateQueue.sync {
      _latestLocation = location
    }
  }

  private func shouldApplyStillNoiseReductionOnSessionQueue() -> Bool {
    guard let iso = currentCaptureISOOnSessionQueue() else {
      return false
    }
    return iso >= 100
  }

  private func storeLatestThumbnail(from image: CIImage) {
    let extent = image.extent
    guard extent.width > 0, extent.height > 0 else { return }
    let maxSide = max(extent.width, extent.height)
    let scale = maxSide > 180 ? 180 / maxSide : 1.0
    let thumb = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cg = ciContext.createCGImage(thumb, from: thumb.extent) else { return }
    let ui = UIImage(cgImage: cg)
    let data = ui.jpegData(compressionQuality: 0.74)
    stateQueue.sync {
      _latestThumbnailData = data
    }
  }

  @objc
  private func handleDeviceOrientationDidChange() {
    updateVideoOrientation()
  }

  @objc
  private func handlePreviewTapGesture(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    let tapPoint = recognizer.location(in: previewView)
    let previewBounds = currentPreviewBounds()
    sessionQueue.async {
      guard self.isConfigured else { return }
      guard let device = self.videoInput?.device else { return }
      let orientation = self.currentVideoOrientationForFocus()
      let focusPoint = self.deviceFocusPoint(
        fromLayerPoint: tapPoint,
        previewBounds: previewBounds,
        videoOrientation: orientation,
        cameraPosition: device.position
      )
      do {
        // Tap should clear AE/AF lock and resume auto focus + continuous exposure.
        try self.applyFocusAndExposure(
          to: device,
          point: focusPoint,
          lock: false
        )
      } catch {
        #if DEBUG
        print("⚠️ CameraViewController: tap focus failed: \(error.localizedDescription)")
        #endif
      }
    }
  }

  @objc
  private func handleFocusLock(_ recognizer: UILongPressGestureRecognizer) {
    guard recognizer.state == .began else { return }
    let pressPoint = recognizer.location(in: previewView)
    let previewBounds = currentPreviewBounds()
    sessionQueue.async {
      guard self.isConfigured else { return }
      guard let device = self.videoInput?.device else { return }
      let orientation = self.currentVideoOrientationForFocus()
      let focusPoint = self.deviceFocusPoint(
        fromLayerPoint: pressPoint,
        previewBounds: previewBounds,
        videoOrientation: orientation,
        cameraPosition: device.position
      )
      do {
        try self.applyFocusAndExposure(
          to: device,
          point: focusPoint,
          lock: true
        )
      } catch {
        #if DEBUG
        print("⚠️ CameraViewController: focus lock failed: \(error.localizedDescription)")
        #endif
      }
    }
  }

  @objc
  private func handlePreviewPinchGesture(_ recognizer: UIPinchGestureRecognizer) {
    switch recognizer.state {
    case .began:
      pinchZoomStartFactor = videoInput?.device.videoZoomFactor ?? 1.0
    case .changed, .ended:
      let targetZoom = pinchZoomStartFactor * recognizer.scale
      applyZoomFactor(targetZoom)
    default:
      break
    }
  }

  private func currentPreferredVideoOrientation() -> AVCaptureVideoOrientation {
    let interfaceOrientation: UIInterfaceOrientation
    if Thread.isMainThread {
      interfaceOrientation = previewView.window?.windowScene?.interfaceOrientation ?? .portrait
    } else {
      interfaceOrientation = DispatchQueue.main.sync {
        previewView.window?.windowScene?.interfaceOrientation ?? .portrait
      }
    }
    if let orientation = videoOrientation(for: interfaceOrientation) {
      return orientation
    }
    return .portrait
  }

  private func videoOrientation(for orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
    switch orientation {
    case .portrait:
      return .portrait
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return nil
    }
  }

  private func videoOrientation(for orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
    switch orientation {
    case .portrait:
      return .portrait
    case .landscapeLeft:
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    case .portraitUpsideDown:
      return .portraitUpsideDown
    default:
      return nil
    }
  }

  private func updateVideoOrientation() {
    let orientation = currentPreferredVideoOrientation()
    let previewBounds = currentPreviewBounds()
    if Thread.isMainThread {
      focusPointConversionLayer.frame = previewBounds
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.focusPointConversionLayer.frame = previewBounds
      }
    }
    sessionQueue.async {
      self.applyVideoOrientation(orientation)
    }
  }

  private func applyVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
    if let videoConnection = videoOutput.connection(with: .video),
       videoConnection.isVideoOrientationSupported
    {
      videoConnection.videoOrientation = orientation
    }
    if let photoConnection = photoOutput.connection(with: .video),
       photoConnection.isVideoOrientationSupported
    {
      photoConnection.videoOrientation = orientation
    }
    if let previewConnection = focusPointConversionLayer.connection,
       previewConnection.isVideoOrientationSupported
    {
      previewConnection.videoOrientation = orientation
      if previewConnection.isVideoMirroringSupported {
        previewConnection.automaticallyAdjustsVideoMirroring = false
        previewConnection.isVideoMirrored = (videoInput?.device.position == .front)
      }
    }
  }

  private func currentPreviewBounds() -> CGRect {
    if Thread.isMainThread {
      return previewView.bounds
    }
    return DispatchQueue.main.sync {
      previewView.bounds
    }
  }

  private func currentVideoOrientationForFocus() -> AVCaptureVideoOrientation {
    if let outputConnection = videoOutput.connection(with: .video),
       outputConnection.isVideoOrientationSupported
    {
      return outputConnection.videoOrientation
    }
    return currentPreferredVideoOrientation()
  }

  private func applyZoomFactor(_ requestedZoom: CGFloat) {
    sessionQueue.async {
      _ = self.applyZoomFactorOnSessionQueue(requestedZoom, emitUpdate: true)
    }
  }

  @discardableResult
  private func applyZoomFactorOnSessionQueue(
    _ requestedZoom: CGFloat,
    emitUpdate: Bool
  ) -> CGFloat? {
    guard let device = videoInput?.device else { return nil }
    let captureFormat = stateQueue.sync { _captureFormat }
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let clamped: CGFloat
    if captureFormat == .proRaw {
      minZoom = 1.0
      maxZoom = 1.0
      clamped = 1.0
    } else {
      minZoom = max(
        0.5,
        min(device.minAvailableVideoZoomFactor, device.activeFormat.videoMaxZoomFactor)
      )
      maxZoom = max(
        minZoom,
        min(device.maxAvailableVideoZoomFactor, device.activeFormat.videoMaxZoomFactor)
      )
      clamped = min(max(requestedZoom, minZoom), maxZoom)
    }

    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      if device.isRampingVideoZoom {
        device.cancelVideoZoomRamp()
      }
      let currentZoom = device.videoZoomFactor
      if abs(currentZoom - clamped) > 0.18 {
        device.ramp(toVideoZoomFactor: clamped, withRate: 18.0)
      } else {
        device.videoZoomFactor = clamped
      }
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: zoom update failed: \(error.localizedDescription)")
      #endif
      return nil
    }

    _ = refreshPhotoConfigurationOnSessionQueue(device: device)
    stateQueue.sync {
      _zoomFactor = Double(clamped)
      _minZoomFactor = Double(minZoom)
      _maxZoomFactor = Double(maxZoom)
    }
    if emitUpdate {
      emitZoomUpdate()
    }
    return clamped
  }

  private func emitZoomUpdate() {
    let payload = zoomPayload()
    DispatchQueue.main.async { [weak self] in
      self?.onZoomUpdated?(payload)
    }
  }

  private func cameraStatePayload(
    activeLensMode: CameraControllerLensMode,
    exposureBias: Double
  ) -> [String: Any] {
    let zoom = zoomPayload()
    return [
      "isReady": true,
      "supportsUltraWide": supportsUltraWide(),
      "supportsRawCapture": supportsRawCapture(),
      "supportsAppleProRAWCapture": supportsAppleProRAWCapture(),
      "activeLensMode": activeLensMode.rawValue,
      "isAeAfLocked": isAeAfLocked(),
      "lookStrength": lookStrength(),
      "exposureBias": exposureBias,
      "captureFormat": captureFormat().rawValue,
      "availableCaptureFormats": availableCaptureFormatsOnSessionQueue().map(\.rawValue),
      "zoomFactor": zoom["zoomFactor"] ?? 1.0,
      "minZoomFactor": zoom["minZoomFactor"] ?? 1.0,
      "maxZoomFactor": zoom["maxZoomFactor"] ?? 5.0,
      "megapixels": zoom["megapixels"] ?? megapixels(),
      "availablePhotoResolutions": zoom["availablePhotoResolutions"] ?? [],
      "selectedPhotoResolution": zoom["selectedPhotoResolution"] as Any,
      "supportsManualFocus": supportsManualFocus(),
      "focusDistance": focusDistance(),
      "isManualFocusActive": isManualFocusActive(),
    ]
  }

  private func zoomPayload() -> [String: Any] {
    return stateQueue.sync {
      [
        "zoomFactor": _zoomFactor,
        "minZoomFactor": _minZoomFactor,
        "maxZoomFactor": _maxZoomFactor,
        "megapixels": _megapixels,
        "availablePhotoResolutions": _availablePhotoResolutions.map(\.payload),
        "selectedPhotoResolution": _selectedPhotoResolution?.payload as Any,
      ]
    }
  }

  private func manualFocusPayload() -> [String: Any] {
    return stateQueue.sync {
      [
        "supportsManualFocus": _supportsManualFocus,
        "focusDistance": _focusDistance,
        "isManualFocusActive": _isManualFocusActive,
      ]
    }
  }

  @discardableResult
  private func refreshPhotoConfigurationOnSessionQueue(
    device: AVCaptureDevice? = nil,
    preferredResolution: CameraPhotoResolutionOption? = nil
  ) -> CameraPhotoResolutionOption? {
    let activeDevice = device ?? videoInput?.device
    let availableFormats = availableCaptureFormatsOnSessionQueue()
    let currentFormat = stateQueue.sync { _captureFormat }
    let activeFormat = resolveCaptureFormatOnSessionQueue(
      currentFormat,
      availableFormats: availableFormats
    )
    let availableResolutions = supportedPhotoResolutionsOnSessionQueue(
      device: activeDevice,
      captureFormat: activeFormat
    )
    let currentSelection = stateQueue.sync { _selectedPhotoResolution }
    let selectedResolution = resolvePhotoResolutionSelectionOnSessionQueue(
      availableResolutions: availableResolutions,
      preferred: preferredResolution ?? currentSelection,
      captureFormat: activeFormat
    )
    if #available(iOS 16.0, *),
      let selectedResolution
    {
      // Keep the selected resolution in state immediately, but only touch the
      // photo output once it is backed by a running video connection.
      applyPhotoOutputMaxDimensionsOnSessionQueue(
        selectedResolution.dimensions,
        device: activeDevice
      )
    }
    stateQueue.sync {
      _availablePhotoResolutions = availableResolutions
      _selectedPhotoResolution = selectedResolution
      _captureFormat = activeFormat
      _megapixels = selectedResolution?.megapixels
        ?? megapixels(from: currentMaxPhotoDimensions(device: activeDevice))
    }
    return selectedResolution
  }

  @available(iOS 16.0, *)
  private func applyPhotoOutputMaxDimensionsOnSessionQueue(
    _ dimensions: CMVideoDimensions,
    device: AVCaptureDevice?
  ) {
    guard dimensions.width > 0, dimensions.height > 0 else {
      return
    }
    guard canApplyPhotoOutputMaxDimensionsOnSessionQueue(device: device) else {
      return
    }
    photoOutput.maxPhotoDimensions = dimensions
  }

  @available(iOS 16.0, *)
  private func canApplyPhotoOutputMaxDimensionsOnSessionQueue(
    device: AVCaptureDevice?
  ) -> Bool {
    guard session.isRunning else {
      return false
    }
    guard let device else {
      return false
    }
    guard photoOutput.connection(with: .video) != nil else {
      return false
    }
    let activeDimensions = CMVideoFormatDescriptionGetDimensions(
      device.activeFormat.formatDescription
    )
    return activeDimensions.width > 0 && activeDimensions.height > 0
  }

  private func preferredWideDevice(
    from devices: [AVCaptureDevice],
    ranking preferredTypes: [AVCaptureDevice.DeviceType]
  ) -> AVCaptureDevice? {
    guard !devices.isEmpty else {
      return nil
    }
    return devices.max { left, right in
      isWideDevice(right, preferredOver: left, ranking: preferredTypes)
    }
  }

  private func isWideDevice(
    _ candidate: AVCaptureDevice,
    preferredOver current: AVCaptureDevice,
    ranking preferredTypes: [AVCaptureDevice.DeviceType]
  ) -> Bool {
    let candidateMegapixels = maximumSupportedPhotoMegapixels(for: candidate)
    let currentMegapixels = maximumSupportedPhotoMegapixels(for: current)
    if abs(candidateMegapixels - currentMegapixels) > 0.05 {
      return candidateMegapixels > currentMegapixels
    }
    let candidateRank = preferredTypes.firstIndex(of: candidate.deviceType) ?? Int.max
    let currentRank = preferredTypes.firstIndex(of: current.deviceType) ?? Int.max
    return candidateRank < currentRank
  }

  private func maximumSupportedPhotoMegapixels(for device: AVCaptureDevice) -> Double {
    if #available(iOS 16.0, *) {
      return device.formats.reduce(0.0) { currentMax, format in
        max(currentMax, maximumSupportedPhotoMegapixels(for: format))
      }
    }
    let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    return megapixels(from: dimensions)
  }

  @available(iOS 16.0, *)
  private func maximumSupportedPhotoMegapixels(for format: AVCaptureDevice.Format) -> Double {
    let supported = format.supportedMaxPhotoDimensions
    if supported.isEmpty {
      return megapixels(
        from: CMVideoFormatDescriptionGetDimensions(format.formatDescription)
      )
    }
    return supported.reduce(0.0) { currentMax, dimensions in
      max(currentMax, megapixels(from: dimensions))
    }
  }

  private func applyPreferredPhotoCaptureFormat(to device: AVCaptureDevice) {
    guard #available(iOS 16.0, *) else {
      return
    }
    guard let preferredFormat = preferredPhotoCaptureFormat(for: device) else {
      return
    }
    guard preferredFormat !== device.activeFormat else {
      return
    }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      device.activeFormat = preferredFormat
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: photo format selection failed: \(error.localizedDescription)")
      #endif
    }
  }

  @available(iOS 16.0, *)
  private func preferredPhotoCaptureFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
    guard !device.formats.isEmpty else {
      return nil
    }
    return device.formats.max { left, right in
      isPhotoCaptureFormat(right, preferredOver: left)
    }
  }

  @available(iOS 16.0, *)
  private func isPhotoCaptureFormat(
    _ candidate: AVCaptureDevice.Format,
    preferredOver current: AVCaptureDevice.Format
  ) -> Bool {
    let candidateMegapixels = maximumSupportedPhotoMegapixels(for: candidate)
    let currentMegapixels = maximumSupportedPhotoMegapixels(for: current)
    if abs(candidateMegapixels - currentMegapixels) > 0.05 {
      return candidateMegapixels > currentMegapixels
    }
    let candidateSupportsP3 = candidate.supportedColorSpaces.contains(.P3_D65)
    let currentSupportsP3 = current.supportedColorSpaces.contains(.P3_D65)
    if candidateSupportsP3 != currentSupportsP3 {
      return candidateSupportsP3
    }
    let candidateDimensions = CMVideoFormatDescriptionGetDimensions(candidate.formatDescription)
    let currentDimensions = CMVideoFormatDescriptionGetDimensions(current.formatDescription)
    if candidateDimensions.width != currentDimensions.width {
      return candidateDimensions.width > currentDimensions.width
    }
    return candidateDimensions.height > currentDimensions.height
  }

  private func appleProRAWPhotoPixelFormatTypeOnSessionQueue() -> OSType? {
    guard #available(iOS 14.3, *) else {
      return nil
    }
    return photoOutput.availableRawPhotoPixelFormatTypes.first(
      where: AVCapturePhotoOutput.isAppleProRAWPixelFormat
    )
  }

  private func standardRawPhotoPixelFormatTypeOnSessionQueue() -> OSType? {
    let rawTypes = photoOutput.availableRawPhotoPixelFormatTypes
    if #available(iOS 14.3, *) {
      if let bayerRAW = rawTypes.first(where: AVCapturePhotoOutput.isBayerRAWPixelFormat) {
        return bayerRAW
      }
    }
    return rawTypes.first
  }

  private func preferredRawPhotoPixelFormatTypeOnSessionQueue(
    for captureFormat: CameraControllerCaptureFormat
  ) -> OSType? {
    switch captureFormat {
    case .proRaw:
      return appleProRAWPhotoPixelFormatTypeOnSessionQueue() ??
        standardRawPhotoPixelFormatTypeOnSessionQueue()
    case .raw, .rawPlusHeic, .rawPlusJpg:
      return standardRawPhotoPixelFormatTypeOnSessionQueue() ??
        appleProRAWPhotoPixelFormatTypeOnSessionQueue()
    case .heic, .jpg:
      return standardRawPhotoPixelFormatTypeOnSessionQueue() ??
        appleProRAWPhotoPixelFormatTypeOnSessionQueue()
    }
  }

  private func availableCaptureFormatsOnSessionQueue() -> [CameraControllerCaptureFormat] {
    var formats: [CameraControllerCaptureFormat] = []
    let supportsHeic = photoOutput.availablePhotoCodecTypes.contains(.hevc)
    let supportsJpg = photoOutput.availablePhotoCodecTypes.contains(.jpeg)
    if supportsHeic {
      formats.append(.heic)
    }
    if supportsJpg || formats.isEmpty {
      formats.append(.jpg)
    }
    if supportsRawCapture() {
      formats.append(.raw)
    }
    if supportsAppleProRAWCapture() {
      formats.append(.proRaw)
    }
    return formats
  }

  private func defaultCaptureFormatOnSessionQueue() -> CameraControllerCaptureFormat {
    let availableFormats = availableCaptureFormatsOnSessionQueue()
    if availableFormats.contains(.heic) {
      return .heic
    }
    if availableFormats.contains(.jpg) {
      return .jpg
    }
    if availableFormats.contains(.rawPlusHeic) {
      return .rawPlusHeic
    }
    if availableFormats.contains(.rawPlusJpg) {
      return .rawPlusJpg
    }
    if availableFormats.contains(.raw) {
      return .raw
    }
    if availableFormats.contains(.proRaw) {
      return .proRaw
    }
    return .jpg
  }

  private func fallbackCaptureFormats(
    for preferredFormat: CameraControllerCaptureFormat
  ) -> [CameraControllerCaptureFormat] {
    switch preferredFormat {
    case .heic:
      return [.jpg]
    case .jpg:
      return [.heic]
    case .raw:
      return [.proRaw, .heic, .jpg, .rawPlusHeic, .rawPlusJpg]
    case .proRaw:
      return [.raw, .heic, .jpg]
    case .rawPlusHeic:
      return [.rawPlusJpg, .raw, .heic, .jpg]
    case .rawPlusJpg:
      return [.rawPlusHeic, .raw, .jpg, .heic]
    }
  }

  private func resolveCaptureFormatOnSessionQueue(
    _ preferredFormat: CameraControllerCaptureFormat,
    availableFormats: [CameraControllerCaptureFormat]
  ) -> CameraControllerCaptureFormat {
    if availableFormats.contains(preferredFormat) {
      return preferredFormat
    }
    for fallback in fallbackCaptureFormats(for: preferredFormat) {
      if availableFormats.contains(fallback) {
        return fallback
      }
    }
    return defaultCaptureFormatOnSessionQueue()
  }

  @discardableResult
  private func applyRequestedCaptureFormatOnSessionQueue(
    _ requestedFormat: CameraControllerCaptureFormat
  ) -> CameraControllerCaptureFormat {
    let activeFormat = resolveCaptureFormatOnSessionQueue(
      requestedFormat,
      availableFormats: availableCaptureFormatsOnSessionQueue()
    )
    stateQueue.sync {
      _captureFormat = activeFormat
    }
    return activeFormat
  }

  private func supportedPhotoResolutionsOnSessionQueue(
    device: AVCaptureDevice?,
    captureFormat: CameraControllerCaptureFormat
  ) -> [CameraPhotoResolutionOption] {
    if #available(iOS 16.0, *),
      let device
    {
      let unique = Set(
        device.activeFormat.supportedMaxPhotoDimensions.compactMap {
          CameraPhotoResolutionOption(dimensions: $0)
        }
      )
      if !unique.isEmpty {
        let sorted = unique.sorted {
          if abs($0.megapixels - $1.megapixels) > 0.0001 {
            return $0.megapixels < $1.megapixels
          }
          if $0.width != $1.width {
            return $0.width < $1.width
          }
          return $0.height < $1.height
        }
        return curatedPhotoResolutions(from: sorted, for: captureFormat)
      }
    }
    if let fallback = CameraPhotoResolutionOption(
      dimensions: currentMaxPhotoDimensions(device: device)
    ) {
      return curatedPhotoResolutions(from: [fallback], for: captureFormat)
    }
    return []
  }

  private func curatedPhotoResolutions(
    from availableResolutions: [CameraPhotoResolutionOption],
    for captureFormat: CameraControllerCaptureFormat
  ) -> [CameraPhotoResolutionOption] {
    guard !availableResolutions.isEmpty else { return [] }
    let targets = preferredResolutionTargets(for: captureFormat)
    var curated: [CameraPhotoResolutionOption] = []
    for target in targets {
      guard
        let candidate = bestResolutionOption(
          in: availableResolutions,
          targetMegapixels: target
        ),
        isResolution(candidate, approximately: target)
      else {
        continue
      }
      if !curated.contains(candidate) {
        curated.append(candidate)
      }
    }

    if curated.isEmpty {
      switch captureFormat {
      case .proRaw:
        if let highest = availableResolutions.max(by: { $0.megapixels < $1.megapixels }) {
          curated = [highest]
        }
      case .raw, .rawPlusHeic, .rawPlusJpg:
        if let lowest = availableResolutions.min(by: { $0.megapixels < $1.megapixels }) {
          curated = [lowest]
        }
      case .heic, .jpg:
        if let lowest = availableResolutions.min(by: { $0.megapixels < $1.megapixels }) {
          curated.append(lowest)
        }
        if let highest24ish = bestResolutionOption(in: availableResolutions, targetMegapixels: 24),
          isResolution(highest24ish, approximately: 24),
          !curated.contains(highest24ish)
        {
          curated.append(highest24ish)
        }
      }
    }

    if curated.isEmpty {
      return availableResolutions
    }
    return curated.sorted {
      if abs($0.megapixels - $1.megapixels) > 0.0001 {
        return $0.megapixels < $1.megapixels
      }
      if $0.width != $1.width {
        return $0.width < $1.width
      }
      return $0.height < $1.height
    }
  }

  private func preferredResolutionTargets(
    for captureFormat: CameraControllerCaptureFormat
  ) -> [Double] {
    switch captureFormat {
    case .raw, .rawPlusHeic, .rawPlusJpg:
      return [12]
    case .proRaw:
      return [48]
    case .heic, .jpg:
      return [12, 24]
    }
  }

  private func bestResolutionOption(
    in availableResolutions: [CameraPhotoResolutionOption],
    targetMegapixels: Double
  ) -> CameraPhotoResolutionOption? {
    availableResolutions.min { left, right in
      let leftDelta = abs(left.megapixels - targetMegapixels)
      let rightDelta = abs(right.megapixels - targetMegapixels)
      if abs(leftDelta - rightDelta) > 0.0001 {
        return leftDelta < rightDelta
      }
      return left.megapixels < right.megapixels
    }
  }

  private func isResolution(
    _ resolution: CameraPhotoResolutionOption,
    approximately targetMegapixels: Double
  ) -> Bool {
    let tolerance: Double
    switch targetMegapixels {
    case 40...:
      tolerance = 8.0
    case 18...:
      tolerance = 4.0
    default:
      tolerance = 2.0
    }
    return abs(resolution.megapixels - targetMegapixels) <= tolerance
  }

  private func resolvePhotoResolutionSelectionOnSessionQueue(
    availableResolutions: [CameraPhotoResolutionOption],
    preferred: CameraPhotoResolutionOption?,
    captureFormat: CameraControllerCaptureFormat
  ) -> CameraPhotoResolutionOption? {
    guard !availableResolutions.isEmpty else { return nil }
    if let preferred,
      availableResolutions.contains(preferred)
    {
      return preferred
    }
    if #available(iOS 16.0, *),
      let currentOutputResolution = CameraPhotoResolutionOption(
        dimensions: photoOutput.maxPhotoDimensions
      ),
      availableResolutions.contains(currentOutputResolution)
    {
      return currentOutputResolution
    }
    switch captureFormat {
    case .proRaw:
      return availableResolutions.max(by: { $0.megapixels < $1.megapixels })
    case .raw, .rawPlusHeic, .rawPlusJpg:
      return availableResolutions.min(by: { $0.megapixels < $1.megapixels })
    case .heic, .jpg:
      return availableResolutions.max(by: { $0.megapixels < $1.megapixels }) ??
        availableResolutions.first
    }
  }

  private func currentMaxPhotoDimensions(device: AVCaptureDevice?) -> CMVideoDimensions {
    if #available(iOS 16.0, *) {
      let maxDimensions = photoOutput.maxPhotoDimensions
      if maxDimensions.width > 0, maxDimensions.height > 0 {
        return maxDimensions
      }
    }
    if let device {
      let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
      if dimensions.width > 0, dimensions.height > 0 {
        return dimensions
      }
    }
    return CMVideoDimensions(width: 4000, height: 3000)
  }

  private func megapixels(from dimensions: CMVideoDimensions) -> Double {
    let width = max(Double(dimensions.width), 1)
    let height = max(Double(dimensions.height), 1)
    let mp = (width * height) / 1_000_000.0
    return max(0.1, mp)
  }

  private func deviceFocusPoint(
    fromNormalizedPreviewPoint normalizedPoint: CGPoint,
    previewBounds: CGRect,
    videoOrientation: AVCaptureVideoOrientation,
    cameraPosition: AVCaptureDevice.Position
  ) -> CGPoint {
    let layerPoint = CGPoint(
      x: normalizedPoint.x * max(previewBounds.width, 1),
      y: normalizedPoint.y * max(previewBounds.height, 1)
    )
    return deviceFocusPoint(
      fromLayerPoint: layerPoint,
      previewBounds: previewBounds,
      videoOrientation: videoOrientation,
      cameraPosition: cameraPosition
    )
  }

  private func deviceFocusPoint(
    fromLayerPoint layerPoint: CGPoint,
    previewBounds: CGRect,
    videoOrientation: AVCaptureVideoOrientation,
    cameraPosition: AVCaptureDevice.Position
  ) -> CGPoint {
    let safeBounds: CGRect
    if previewBounds.width > 0 && previewBounds.height > 0 {
      safeBounds = previewBounds
    } else {
      safeBounds = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    focusPointConversionLayer.frame = safeBounds
    if let connection = focusPointConversionLayer.connection {
      if connection.isVideoOrientationSupported {
        connection.videoOrientation = videoOrientation
      }
      if connection.isVideoMirroringSupported {
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = (cameraPosition == .front)
      }
    }
    let clampedLayerPoint = CGPoint(
      x: min(max(layerPoint.x, 0), safeBounds.width),
      y: min(max(layerPoint.y, 0), safeBounds.height)
    )
    let devicePoint = focusPointConversionLayer.captureDevicePointConverted(
      fromLayerPoint: clampedLayerPoint
    )
    return CGPoint(
      x: min(max(devicePoint.x, 0.0), 1.0),
      y: min(max(devicePoint.y, 0.0), 1.0)
    )
  }

  private func applyFocusAndExposure(
    to device: AVCaptureDevice,
    point: CGPoint,
    lock: Bool
  ) throws {
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }

    if device.isFocusPointOfInterestSupported {
      device.focusPointOfInterest = point
    }
    if device.isExposurePointOfInterestSupported {
      device.exposurePointOfInterest = point
    }

    if lock {
      if device.isFocusModeSupported(.locked) {
        device.focusMode = .locked
      }
      if device.isExposureModeSupported(.locked) {
        device.exposureMode = .locked
      }
    } else {
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      } else if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
    }

    device.isSubjectAreaChangeMonitoringEnabled = !lock
    stateQueue.sync {
      _isAeAfLocked = lock
      _focusDistance = Double(device.lensPosition)
      _isManualFocusActive = false
    }
  }

  private func applyDefaultAutoFocusAndExposure(to device: AVCaptureDevice) {
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
        device.whiteBalanceMode = .continuousAutoWhiteBalance
      }
      device.isSubjectAreaChangeMonitoringEnabled = true
      stateQueue.sync {
        _isAeAfLocked = false
        _focusDistance = Double(device.lensPosition)
        _isManualFocusActive = false
        _supportsManualFocus = device.isFocusModeSupported(.locked)
      }
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: default AF/AE setup failed: \(error.localizedDescription)")
      #endif
    }
  }

  private func applyPreferredCaptureColorSpace(to device: AVCaptureDevice) {
    guard device.activeFormat.supportedColorSpaces.contains(.P3_D65) else {
      return
    }
    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      device.activeColorSpace = .P3_D65
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: color space setup failed: \(error.localizedDescription)")
      #endif
    }
  }

  private func lockExposureForCaptureIfNeeded() {
    let shouldLockExposure = stateQueue.sync { !_isAeAfLocked }
    guard shouldLockExposure else {
      stateQueue.sync {
        _didTemporarilyLockExposureForCapture = false
      }
      return
    }
    guard let device = videoInput?.device else {
      stateQueue.sync {
        _didTemporarilyLockExposureForCapture = false
      }
      return
    }

    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      guard device.isExposureModeSupported(.locked) else {
        stateQueue.sync {
          _didTemporarilyLockExposureForCapture = false
        }
        return
      }
      device.exposureMode = .locked
      stateQueue.sync {
        _didTemporarilyLockExposureForCapture = true
      }
    } catch {
      stateQueue.sync {
        _didTemporarilyLockExposureForCapture = false
      }
      #if DEBUG
      print("⚠️ CameraViewController: pre-capture exposure lock failed: \(error.localizedDescription)")
      #endif
    }
  }

  private func restoreExposureAfterCaptureIfNeeded() {
    let shouldRestore = stateQueue.sync { _didTemporarilyLockExposureForCapture }
    guard shouldRestore else { return }
    defer {
      stateQueue.sync {
        _didTemporarilyLockExposureForCapture = false
      }
    }
    guard let device = videoInput?.device else { return }

    do {
      try device.lockForConfiguration()
      defer { device.unlockForConfiguration() }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: exposure restore failed: \(error.localizedDescription)")
      #endif
    }
  }

  private func ciImageOrientation(
    for videoOrientation: AVCaptureVideoOrientation,
    cameraPosition: AVCaptureDevice.Position
  ) -> CGImagePropertyOrientation {
    switch (videoOrientation, cameraPosition) {
    case (.portrait, .front):
      return .leftMirrored
    case (.portraitUpsideDown, .front):
      return .rightMirrored
    case (.landscapeRight, .front):
      return .upMirrored
    case (.landscapeLeft, .front):
      return .downMirrored
    case (.portrait, _):
      return .right
    case (.portraitUpsideDown, _):
      return .left
    case (.landscapeRight, _):
      return .down
    case (.landscapeLeft, _):
      return .up
    @unknown default:
      return .right
    }
  }

  private func normalizedMetadata(from data: Data) -> [String: Any] {
    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
    else {
      return [:]
    }
    return properties
  }

  private func normalizedMetadataFromDictionary(
    _ metadata: [AnyHashable: Any]
  ) -> [String: Any] {
    var output: [String: Any] = [:]
    for (key, value) in metadata {
      if let stringKey = key as? String {
        output[stringKey] = value
      } else {
        output[String(describing: key)] = value
      }
    }
    return output
  }

  private func writeTempCapture(data: Data, fileExtension: String) -> String? {
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(tempCapturePrefix)\(UUID().uuidString)")
      .appendingPathExtension(fileExtension)
    do {
      try data.write(to: fileURL, options: [.atomic])
      return fileURL.path
    } catch {
      return nil
    }
  }

  private func resetRawPlusProcessedBuffers() {
    rawPlusProcessedRawData = nil
    rawPlusProcessedProcessedData = nil
    rawPlusProcessedProcessedMetadata = nil
  }

  private func cleanupExpiredTempCaptures() {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let cutoff = Date().addingTimeInterval(-tempCaptureMaxAgeSeconds)
    let keys: Set<URLResourceKey> = [
      .isRegularFileKey,
      .creationDateKey,
      .contentModificationDateKey,
      .nameKey,
    ]

    guard
      let urls = try? fileManager.contentsOfDirectory(
        at: tempDirectory,
        includingPropertiesForKeys: Array(keys),
        options: [.skipsHiddenFiles]
      )
    else {
      return
    }

    for url in urls where url.lastPathComponent.hasPrefix(tempCapturePrefix) {
      guard let values = try? url.resourceValues(forKeys: keys) else { continue }
      if values.isRegularFile == false { continue }
      guard
        let fileDate = values.contentModificationDate ?? values.creationDate,
        fileDate < cutoff
      else {
        continue
      }
      do {
        try fileManager.removeItem(at: url)
      } catch {
        #if DEBUG
        print("⚠️ CameraViewController: temp cleanup failed for \(url.lastPathComponent): \(error.localizedDescription)")
        #endif
      }
    }
  }

  private func triggerShutterHaptic() {
    DispatchQueue.main.async {
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      if #available(iOS 13.0, *) {
        generator.impactOccurred(intensity: 0.8)
      } else {
        generator.impactOccurred()
      }
    }
  }

  // MARK: - Histogram Pipeline

  private func maybeDispatchHistogram(from image: CIImage) {
    let now = CFAbsoluteTimeGetCurrent()
    let shouldCompute = stateQueue.sync { () -> Bool in
      guard onHistogramUpdated != nil else { return false }
      guard previewProcessingMode.shouldComputeHistogram else { return false }
      guard !histogramIsComputing else { return false }
      guard (now - histogramLastDispatchTime) >= histogramUpdateInterval else {
        return false
      }
      histogramIsComputing = true
      histogramLastDispatchTime = now
      return true
    }

    guard shouldCompute else { return }
    let histogramImage = image
    histogramQueue.async { [weak self] in
      guard let self else { return }
      let start = CFAbsoluteTimeGetCurrent()
      let values = self.computeLuminanceHistogram(from: histogramImage)
      let elapsed = CFAbsoluteTimeGetCurrent() - start
      self.stateQueue.sync {
        self.recordHistogramProcessingTime(elapsed)
        self.histogramIsComputing = false
      }
      guard let values else { return }
      DispatchQueue.main.async { [weak self] in
        self?.onHistogramUpdated?(values)
      }
    }
  }

  private func computeLuminanceHistogram(from image: CIImage) -> [Double]? {
    let extent = image.extent.integral
    guard extent.width > 0, extent.height > 0 else { return nil }

    let scale = min(1.0, histogramDownsampleWidth / extent.width)
    let downsampled: CIImage
    if scale < 0.999 {
      let filter = CIFilter(name: "CILanczosScaleTransform")
      filter?.setValue(image, forKey: kCIInputImageKey)
      filter?.setValue(scale, forKey: kCIInputScaleKey)
      filter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
      downsampled = filter?.outputImage ?? image.transformed(
        by: CGAffineTransform(scaleX: scale, y: scale)
      )
    } else {
      downsampled = image
    }

    guard let histogramFilter = CIFilter(name: "CIAreaHistogram") else {
      return nil
    }
    histogramFilter.setValue(downsampled, forKey: kCIInputImageKey)
    histogramFilter.setValue(
      CIVector(cgRect: downsampled.extent),
      forKey: kCIInputExtentKey
    )
    histogramFilter.setValue(histogramBinCount, forKey: "inputCount")
    histogramFilter.setValue(1.0, forKey: "inputScale")

    guard let histogramImage = histogramFilter.outputImage else { return nil }

    var bitmap = [Float](repeating: 0, count: histogramBinCount * 4)
    ciContext.render(
      histogramImage,
      toBitmap: &bitmap,
      rowBytes: histogramBinCount * MemoryLayout<Float>.size * 4,
      bounds: CGRect(x: 0, y: 0, width: histogramBinCount, height: 1),
      format: .RGBAf,
      colorSpace: nil
    )

    var bins = [Double](repeating: 0, count: histogramBinCount)
    var maxValue = 0.0
    for index in 0..<histogramBinCount {
      let offset = index * 4
      let r = Double(bitmap[offset])
      let g = Double(bitmap[offset + 1])
      let b = Double(bitmap[offset + 2])
      let luminance = max(0.0, 0.2126 * r + 0.7152 * g + 0.0722 * b)
      bins[index] = luminance
      if luminance > maxValue {
        maxValue = luminance
      }
    }

    let contrastEstimate = estimateSceneContrast(from: bins)
    let highlightClipping = estimateHighlightClipping(from: bins)
    stateQueue.sync {
      sceneContrastEstimate = contrastEstimate
      highlightClippingEstimate = highlightClipping
    }
    updateHighlightProtectionIfNeeded(highlightClipping: highlightClipping)

    guard maxValue > 0 else { return bins }
    let inv = 1.0 / maxValue
    for index in 0..<bins.count {
      let normalized = bins[index] * inv
      bins[index] = pow(normalized, 0.8)
    }
    return bins
  }

  private func estimateSceneContrast(from bins: [Double]) -> Double {
    guard !bins.isEmpty else { return 0.0 }
    let total = bins.reduce(0.0, +)
    guard total > 0 else { return 0.0 }

    let lowTarget = total * 0.05
    let highTarget = total * 0.95
    var cumulative = 0.0
    var lowIndex = 0
    var highIndex = bins.count - 1

    for index in bins.indices {
      cumulative += bins[index]
      if cumulative >= lowTarget {
        lowIndex = index
        break
      }
    }

    cumulative = 0.0
    for index in bins.indices {
      cumulative += bins[index]
      if cumulative >= highTarget {
        highIndex = index
        break
      }
    }

    let span = max(0, highIndex - lowIndex)
    let normalized = Double(span) / Double(max(1, bins.count - 1))
    return min(1.0, max(0.0, normalized))
  }

  private func estimateHighlightClipping(from bins: [Double]) -> Double {
    guard bins.count >= 4 else { return 0.0 }
    let total = bins.reduce(0.0, +)
    guard total > 0 else { return 0.0 }
    let highlightBins = bins.suffix(4)
    let weightedHighlightEnergy = highlightBins.enumerated().reduce(0.0) { partial, item in
      let weight = 0.7 + (Double(item.offset) * 0.15)
      return partial + (item.element * weight)
    }
    return weightedHighlightEnergy / total
  }

  private func updatePreviewFrameInterval(now: CFAbsoluteTime) {
    if previewLastFrameTimestamp > 0 {
      let delta = now - previewLastFrameTimestamp
      if delta > 0 {
        if previewFrameIntervalEMA == 0 {
          previewFrameIntervalEMA = delta
        } else {
          let alpha = 0.2
          previewFrameIntervalEMA =
            ((1.0 - alpha) * previewFrameIntervalEMA) + (alpha * delta)
        }
      }
    }
    previewLastFrameTimestamp = now
    _ = updatePreviewProcessingModeOnStateQueue()
  }

  private func applyExposureBias(
    _ requestedBias: Double,
    to device: AVCaptureDevice
  ) throws -> Double {
    let minBias = Double(device.minExposureTargetBias)
    let maxBias = Double(device.maxExposureTargetBias)
    let clamped = min(max(requestedBias, minBias), maxBias)
    let protectionBias = stateQueue.sync { autoExposureProtectionBias }
    let effectiveBias = min(max(clamped + protectionBias, minBias), maxBias)
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }
    device.setExposureTargetBias(Float(effectiveBias), completionHandler: nil)
    stateQueue.sync {
      _exposureBias = clamped
    }
    return clamped
  }

  private func recordHistogramProcessingTime(_ elapsed: TimeInterval) {
    let alpha = 0.2
    if histogramComputeEMA == 0 {
      histogramComputeEMA = elapsed
    } else {
      histogramComputeEMA =
        ((1.0 - alpha) * histogramComputeEMA) + (alpha * elapsed)
    }

    var adaptive = histogramComputeEMA * 8.0
    if previewFrameIntervalEMA > 0 {
      let previewFPS = 1.0 / previewFrameIntervalEMA
      if previewFPS < previewFpsThrottleThreshold {
        let penalty = previewFpsThrottleThreshold / max(previewFPS, 1.0)
        adaptive = max(adaptive, histogramMinInterval * penalty)
      }
    }
    _ = updatePreviewProcessingModeOnStateQueue()
    histogramUpdateInterval = min(
      histogramMaxInterval,
      max(histogramMinInterval, adaptive)
    )
    if previewProcessingMode == .reduced {
      histogramUpdateInterval = max(histogramUpdateInterval, previewReducedHistogramInterval)
    }
  }

  private func resolvedLensMode(
    for requestedLensMode: CameraControllerLensMode,
    captureFormat: CameraControllerCaptureFormat
  ) -> CameraControllerLensMode {
    if captureFormat == .proRaw {
      return .wide
    }
    return requestedLensMode
  }

  private func updatePreviewProcessingModeOnStateQueue() -> LumaPreviewProcessingMode {
    let fps = previewFrameIntervalEMA > 0 ? (1.0 / previewFrameIntervalEMA) : 60.0
    if previewProcessingMode == .reduced, histogramComputeEMA > 0 {
      histogramComputeEMA *= 0.985
    }
    switch previewProcessingMode {
    case .standard:
      if fps < previewFpsThrottleThreshold || histogramComputeEMA > previewHistogramCostThreshold {
        previewProcessingMode = .reduced
      }
    case .reduced:
      if fps > previewFpsRecoveryThreshold &&
        histogramComputeEMA < (previewHistogramCostThreshold * 0.75)
      {
        previewProcessingMode = .standard
      }
    }
    return previewProcessingMode
  }

  private func updateHighlightProtectionIfNeeded(highlightClipping: Double) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      guard self.isConfigured, let device = self.videoInput?.device else { return }
      let targetBias = self.targetHighlightProtectionBias(for: highlightClipping)
      let now = CFAbsoluteTimeGetCurrent()
      let shouldApply = self.stateQueue.sync { () -> Bool in
        let delta = abs(targetBias - self.autoExposureProtectionBias)
        guard delta >= 0.03 else { return false }
        guard
          (now - self.lastHighlightProtectionAdjustmentTime) >=
            self.highlightProtectionMinimumUpdateInterval
        else {
          return false
        }
        self.lastHighlightProtectionAdjustmentTime = now
        return true
      }
      guard shouldApply else { return }
      _ = try? self.applyHighlightProtectionBias(targetBias, to: device)
    }
  }

  private func targetHighlightProtectionBias(for highlightClipping: Double) -> Double {
    let currentProtection = stateQueue.sync { autoExposureProtectionBias }
    if highlightClipping <= highlightClippingRecoveryThreshold {
      return 0.0
    }
    if highlightClipping <= highlightClippingThreshold {
      return currentProtection * 0.65
    }
    let normalized = clampUnit(
      (highlightClipping - highlightClippingThreshold) / 0.12
    )
    let reduction = 0.06 + (normalized * (highlightProtectionMaximumBias - 0.06))
    return -reduction
  }

  private func applyHighlightProtectionBias(
    _ bias: Double,
    to device: AVCaptureDevice
  ) throws -> Double {
    let minBias = Double(device.minExposureTargetBias)
    let maxBias = Double(device.maxExposureTargetBias)
    let userBias = stateQueue.sync { _exposureBias }
    let clampedProtection = max(-highlightProtectionMaximumBias, min(0.0, bias))
    let effectiveBias = min(max(userBias + clampedProtection, minBias), maxBias)
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }
    device.setExposureTargetBias(Float(effectiveBias), completionHandler: nil)
    stateQueue.sync {
      autoExposureProtectionBias = clampedProtection
    }
    return effectiveBias
  }

  private func clampUnit(_ value: Double) -> Double {
    min(1.0, max(0.0, value))
  }

  private func finishCapture(_ captureResult: Result<[String: Any], Error>) {
    resetRawPlusProcessedBuffers()
    let completion = stateQueue.sync { () -> ((Result<[String: Any], Error>) -> Void)? in
      let callback = captureCompletion
      captureCompletion = nil
      return callback
    }
    guard let completion else { return }
    DispatchQueue.main.async {
      completion(captureResult)
    }
  }
}
