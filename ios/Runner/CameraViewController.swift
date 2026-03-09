import AVFoundation
import CoreImage
import ImageIO
import Photos
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
  case jpg
  case raw
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

final class CameraPreviewContainerView: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

final class CameraViewController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
  let previewView = CameraPreviewContainerView()

  private let previewImageView = UIImageView()
  private let focusPointConversionLayer = AVCaptureVideoPreviewLayer()
  private let session = AVCaptureSession()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let photoOutput = AVCapturePhotoOutput()

  private let sessionQueue = DispatchQueue(label: "com.luma.camera.session", qos: .userInitiated)
  private let previewQueue = DispatchQueue(label: "com.luma.camera.preview", qos: .userInitiated)
  private let stateQueue = DispatchQueue(label: "com.luma.camera.state")

  private let ciContext: CIContext
  private let lutLoader = LumaLUTLoader.shared
  private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
  private let previewHighlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
  private let previewColorControlsFilter = CIFilter(name: "CIColorControls")

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
  private var _captureFormat: CameraControllerCaptureFormat = .jpg
  private var _captureVideoOrientation: AVCaptureVideoOrientation = .portrait
  private var _captureCameraPosition: AVCaptureDevice.Position = .back
  private var _captureFormatForCurrentPhoto: CameraControllerCaptureFormat = .jpg
  private var _didTemporarilyLockExposureForCapture = false
  private var _latestThumbnailData: Data?
  var onHistogramUpdated: (([Double]) -> Void)?
  private let tempCapturePrefix = "luma_capture_"
  private let tempCaptureMaxAgeSeconds: TimeInterval = 24 * 60 * 60
  private let histogramQueue = DispatchQueue(
    label: "com.luma.camera.histogram",
    qos: .utility
  )
  private let histogramBinCount = 64
  private let histogramDownsampleWidth: CGFloat = 128
  private let histogramMinInterval: TimeInterval = 0.1
  private let histogramMaxInterval: TimeInterval = 0.35
  private let previewFpsThrottleThreshold = 24.0
  private var histogramUpdateInterval: TimeInterval = 0.1
  private var histogramLastDispatchTime: CFAbsoluteTime = 0
  private var histogramIsComputing = false
  private var histogramComputeEMA: TimeInterval = 0
  private var previewFrameIntervalEMA: TimeInterval = 0
  private var previewLastFrameTimestamp: CFAbsoluteTime = 0
  private var pinchZoomStartFactor: CGFloat = 1.0

  override init() {
    ciContext = CIContext(options: [
      .useSoftwareRenderer: false,
      .cacheIntermediates: true,
      .workingColorSpace: sRGB,
      .outputColorSpace: sRGB,
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
      if let device = self.videoInput?.device {
        self.applyDefaultAutoFocusAndExposure(to: device)
      }
      if !self.session.isRunning {
        self.session.startRunning()
      }
      DispatchQueue.main.async {
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
      }
      self.onHistogramUpdated = nil
    }
    DispatchQueue.main.async {
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
      let active: CameraControllerCaptureFormat
      if format == .raw, !self.supportsRawCapture() {
        active = .jpg
      } else {
        active = format
      }
      self.stateQueue.sync {
        self._captureFormat = active
      }
      DispatchQueue.main.async {
        completion(.success(active))
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
    _ = mode
    sessionQueue.async {
      guard self.isConfigured else {
        DispatchQueue.main.async {
          completion(.failure(CameraControllerError.sessionNotConfigured))
        }
        return
      }
      let active = self.stateQueue.sync { self._lensMode }
      DispatchQueue.main.async {
        completion(.success(active))
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
      let settings = self.makePhotoSettings()
      self.photoOutput.capturePhoto(with: settings, delegate: self)
    }
  }

  func latestThumbnail() -> Data? {
    return stateQueue.sync { _latestThumbnailData }
  }

  func supportsUltraWide() -> Bool {
    return availableDevice(for: .ultraWide) != nil
  }

  func supportsRawCapture() -> Bool {
    return !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty
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

  // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

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
      var image = CIImage(cvPixelBuffer: pixelBuffer)
      image = applyPreviewToneMapping(image)
      let shouldApplyColorControls = stateQueue.sync { () -> Bool in
        guard previewFrameIntervalEMA > 0 else { return true }
        let fps = 1.0 / previewFrameIntervalEMA
        return fps >= previewFpsThrottleThreshold
      }
      image = applyPreviewColorControls(
        image,
        applyEnhancement: shouldApplyColorControls
      )
      image = LumaFilmSimulation.apply(
        simulationId: simulationState.0,
        to: image,
        intensity: simulationState.1,
        strength: simulationState.2,
        lutLoader: lutLoader
      )

      maybeDispatchHistogram(from: image)

      guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
        isRenderingFrame = false
        return
      }

      let frameImage = UIImage(cgImage: cgImage)
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
    if let error {
      sessionQueue.async {
        self.restoreExposureAfterCaptureIfNeeded()
        self.finishCapture(.failure(error))
      }
      return
    }
    guard let photoData = photo.fileDataRepresentation() else {
      sessionQueue.async {
        self.restoreExposureAfterCaptureIfNeeded()
        self.finishCapture(.failure(CameraControllerError.photoDataUnavailable))
      }
      return
    }

    let captureState = stateQueue.sync {
      (
        _simulationId,
        _simulationIntensity,
        _lookStrength,
        _captureVideoOrientation,
        _captureCameraPosition,
        _captureFormatForCurrentPhoto
      )
    }
    let sourceMetadata = normalizedMetadata(from: photoData)
    sessionQueue.async {
      autoreleasepool {
        self.restoreExposureAfterCaptureIfNeeded()
        let captureOrientation = self.ciImageOrientation(
          for: captureState.3,
          cameraPosition: captureState.4
        )

        if captureState.5 == .raw {
          let orientedImage = CIImage(
            data: photoData,
            options: [.applyOrientationProperty: false]
          )?.oriented(captureOrientation)
          guard let tempPath = self.writeTempCapture(data: photoData, fileExtension: "dng") else {
            self.finishCapture(.failure(CameraControllerError.photoEncodingFailed))
            return
          }
          let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)
          if let orientedImage {
            self.storeLatestThumbnail(from: orientedImage)
          }
          self.saveCaptureToPhotos(data: photoData, uti: "com.adobe.raw-image") { saveResult in
            let localIdentifier: String?
            switch saveResult {
            case .success(let id):
              localIdentifier = id
            case .failure(let error):
              #if DEBUG
              print("⚠️ CameraViewController: save RAW to Photos failed, using temp file: \(error.localizedDescription)")
              #endif
              localIdentifier = nil
            }
            let payload: [String: Any] = [
              "localIdentifier": localIdentifier as Any,
              "filePath": tempPath,
              "simulationId": captureState.0,
              "lookStrength": captureState.2,
              "mimeType": "image/x-adobe-dng",
              "width": orientedImage.map { Int($0.extent.width.rounded()) } as Any,
              "height": orientedImage.map { Int($0.extent.height.rounded()) } as Any,
              "captureFormat": CameraControllerCaptureFormat.raw.rawValue,
              "capturedAt": capturedAtMs,
              "savedAtMs": capturedAtMs
            ]
            self.finishCapture(.success(payload))
          }
          return
        }

        guard
          let ciImage = CIImage(
            data: photoData,
            options: [.applyOrientationProperty: false]
          )
        else {
          self.finishCapture(.failure(CameraControllerError.photoDataUnavailable))
          return
        }
        let orientedImage = ciImage.oriented(captureOrientation)
        let toneMappedImage = self.applyCaptureToneMapping(orientedImage)
        let colorAdjustedImage = self.applyCaptureColorControls(toneMappedImage)

        if captureState.0 == LumaFilmSimulation.defaultSimulationId {
          guard
            let encoded = self.encodeCaptureImage(
              colorAdjustedImage,
              sourceMetadata: sourceMetadata,
              captureFormat: captureState.5
            )
          else {
            self.finishCapture(.failure(CameraControllerError.photoEncodingFailed))
            return
          }
          guard
            let tempPath = self.writeTempCapture(
              data: encoded.data,
              fileExtension: encoded.fileExtension
            )
          else {
            self.finishCapture(.failure(CameraControllerError.photoEncodingFailed))
            return
          }
          let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)
          self.storeLatestThumbnail(from: colorAdjustedImage)
          self.saveCaptureToPhotos(data: encoded.data, uti: encoded.uti) { saveResult in
            let localIdentifier: String?
            switch saveResult {
            case .success(let id):
              localIdentifier = id
            case .failure(let error):
              #if DEBUG
              print("⚠️ CameraViewController: save tone-mapped photo to Photos failed, using temp file: \(error.localizedDescription)")
              #endif
              localIdentifier = nil
            }
            let payload: [String: Any] = [
              "localIdentifier": localIdentifier as Any,
              "filePath": tempPath,
              "simulationId": captureState.0,
              "lookStrength": captureState.2,
              "mimeType": encoded.mimeType,
              "width": Int(colorAdjustedImage.extent.width.rounded()),
              "height": Int(colorAdjustedImage.extent.height.rounded()),
              "captureFormat": CameraControllerCaptureFormat.jpg.rawValue,
              "capturedAt": capturedAtMs,
              "savedAtMs": capturedAtMs
            ]
            self.finishCapture(.success(payload))
          }
          return
        }

        let processed = LumaFilmSimulation.apply(
          simulationId: captureState.0,
          to: colorAdjustedImage,
          intensity: captureState.1,
          strength: captureState.2,
          lutLoader: self.lutLoader
        )

        guard
          let encoded = self.encodeCaptureImage(
            processed,
            sourceMetadata: sourceMetadata,
            captureFormat: captureState.5
          )
        else {
          self.finishCapture(.failure(CameraControllerError.photoEncodingFailed))
          return
        }

        guard
          let tempPath = self.writeTempCapture(
            data: encoded.data,
            fileExtension: encoded.fileExtension
          )
        else {
          self.finishCapture(.failure(CameraControllerError.photoEncodingFailed))
          return
        }

        let capturedAtMs = Int(Date().timeIntervalSince1970 * 1000)
        self.storeLatestThumbnail(from: processed)
        self.saveCaptureToPhotos(data: encoded.data, uti: encoded.uti) { saveResult in
          let localIdentifier: String?
          switch saveResult {
          case .success(let id):
            localIdentifier = id
          case .failure(let error):
            #if DEBUG
            print("⚠️ CameraViewController: save to Photos failed, using temp file: \(error.localizedDescription)")
            #endif
            localIdentifier = nil
          }
          let payload: [String: Any] = [
            "localIdentifier": localIdentifier as Any,
            "filePath": tempPath,
            "simulationId": captureState.0,
            "lookStrength": captureState.2,
            "mimeType": encoded.mimeType,
            "width": Int(processed.extent.width.rounded()),
            "height": Int(processed.extent.height.rounded()),
            "captureFormat": CameraControllerCaptureFormat.jpg.rawValue,
            "capturedAt": capturedAtMs,
            "savedAtMs": capturedAtMs
          ]
          self.finishCapture(.success(payload))
        }
      }
    }
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

  private func configureSession(completion: @escaping (Result<[String: Any], Error>) -> Void) {
    sessionQueue.async {
      self.cleanupExpiredTempCaptures()
      if self.isConfigured {
        let payload: [String: Any] = [
          "isReady": true,
          "supportsUltraWide": self.supportsUltraWide(),
          "supportsRawCapture": self.supportsRawCapture(),
          "activeLensMode": self.activeLensMode().rawValue,
          "isAeAfLocked": self.isAeAfLocked(),
          "lookStrength": self.lookStrength(),
          "exposureBias": self.exposureBias(),
          "captureFormat": self.captureFormat().rawValue,
        ]
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

        if self.session.canSetSessionPreset(.photo) {
          self.session.sessionPreset = .photo
        } else {
          self.session.sessionPreset = .high
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard self.session.canAddInput(input) else {
          throw CameraControllerError.configurationFailed("Could not add camera input.")
        }
        self.session.addInput(input)
        self.videoInput = input
        self.applyDefaultAutoFocusAndExposure(to: device)
        let appliedExposure =
          (try? self.applyExposureBias(self.exposureBias(), to: device))
          ?? self.exposureBias()

        guard self.session.canAddOutput(self.photoOutput) else {
          throw CameraControllerError.configurationFailed("Could not add photo output.")
        }
        self.session.addOutput(self.photoOutput)
        self.photoOutput.isHighResolutionCaptureEnabled = true
        if #available(iOS 13.0, *) {
          self.photoOutput.maxPhotoQualityPrioritization = .quality
        }

        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.videoSettings = [
          kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        ]
        self.videoOutput.setSampleBufferDelegate(self, queue: self.previewQueue)

        guard self.session.canAddOutput(self.videoOutput) else {
          throw CameraControllerError.configurationFailed("Could not add video output.")
        }
        self.session.addOutput(self.videoOutput)

        self.updateVideoOrientation()
        didBeginConfiguration = false
        self.session.commitConfiguration()
        self.stateQueue.sync {
          self._lensMode = .wide
          self._isAeAfLocked = false
        }
        self.isConfigured = true

        let payload: [String: Any] = [
          "isReady": true,
          "supportsUltraWide": self.supportsUltraWide(),
          "supportsRawCapture": self.supportsRawCapture(),
          "activeLensMode": CameraControllerLensMode.wide.rawValue,
          "isAeAfLocked": self.isAeAfLocked(),
          "lookStrength": self.lookStrength(),
          "exposureBias": appliedExposure,
          "captureFormat": self.captureFormat().rawValue,
        ]
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

    for type in preferredTypes {
      if let matched = discovery.devices.first(where: { $0.deviceType == type }) {
        return matched
      }
    }
    return discovery.devices.first
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
    let requestedBias = stateQueue.sync { _exposureBias }
    _ = try? applyExposureBias(requestedBias, to: device)
    applyDefaultAutoFocusAndExposure(to: device)

    updateVideoOrientation()
    session.commitConfiguration()
  }

  private func makePhotoSettings() -> AVCapturePhotoSettings {
    let requestedFormat = stateQueue.sync { _captureFormat }
    var activeFormat: CameraControllerCaptureFormat = .jpg
    var settings = AVCapturePhotoSettings()
    if requestedFormat == .raw,
       let rawType = photoOutput.availableRawPhotoPixelFormatTypes.first
    {
      settings = AVCapturePhotoSettings(rawPixelFormatType: rawType)
      activeFormat = .raw
    } else if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
      settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
      activeFormat = .jpg
    } else if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
      settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
      activeFormat = .jpg
    }
    settings.isHighResolutionPhotoEnabled = true
    if #available(iOS 13.0, *) {
      settings.photoQualityPrioritization = .quality
    }
    if photoOutput.isStillImageStabilizationSupported {
      settings.isAutoStillImageStabilizationEnabled = true
    }
    if photoOutput.isVirtualDeviceFusionSupported {
      settings.isAutoVirtualDeviceFusionEnabled = true
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

    let targets: [(uti: String, fileExtension: String, mimeType: String)]
    switch captureFormat {
    case .jpg:
      if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
        targets = [
          ("public.heic", "heic", "image/heic"),
          ("public.jpeg", "jpg", "image/jpeg"),
        ]
      } else {
        targets = [("public.jpeg", "jpg", "image/jpeg")]
      }
    case .raw:
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

  private func applyCaptureToneMapping(_ image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIHighlightShadowAdjust") else {
      return image
    }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(0.7, forKey: "inputShadowAmount")
    filter.setValue(0.25, forKey: "inputHighlightAmount")
    return filter.outputImage ?? image
  }

  private func applyCaptureColorControls(_ image: CIImage) -> CIImage {
    guard let colorFilter = CIFilter(name: "CIColorControls") else {
      return image
    }
    colorFilter.setValue(image, forKey: kCIInputImageKey)
    colorFilter.setValue(1.05, forKey: kCIInputSaturationKey)
    colorFilter.setValue(1.02, forKey: kCIInputContrastKey)
    return colorFilter.outputImage ?? image
  }

  private func applyPreviewToneMapping(_ image: CIImage) -> CIImage {
    guard let filter = previewHighlightShadowFilter else {
      return image
    }
    filter.setValue(image, forKey: kCIInputImageKey)
    // Subtle neutral tone mapping to better match polished camera previews.
    filter.setValue(0.58, forKey: "inputShadowAmount")
    filter.setValue(0.18, forKey: "inputHighlightAmount")
    return filter.outputImage ?? image
  }

  private func applyPreviewColorControls(
    _ image: CIImage,
    applyEnhancement: Bool
  ) -> CIImage {
    guard applyEnhancement, let filter = previewColorControlsFilter else {
      return image
    }
    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(1.03, forKey: kCIInputSaturationKey)
    filter.setValue(1.04, forKey: kCIInputContrastKey)
    return filter.outputImage ?? image
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
      guard self.isConfigured else { return }
      guard let device = self.videoInput?.device else { return }
      let maxZoom = device.activeFormat.videoMaxZoomFactor
      let clamped = min(max(requestedZoom, 1.0), maxZoom)
      do {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        device.videoZoomFactor = clamped
      } catch {
        #if DEBUG
        print("⚠️ CameraViewController: zoom update failed: \(error.localizedDescription)")
        #endif
      }
    }
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
    let wasLocked = stateQueue.sync { _isAeAfLocked }
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
      if wasLocked {
        if device.isFocusModeSupported(.continuousAutoFocus) {
          device.focusMode = .continuousAutoFocus
        } else if device.isFocusModeSupported(.autoFocus) {
          device.focusMode = .autoFocus
        }
      } else if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      } else if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
    }

    device.isSubjectAreaChangeMonitoringEnabled = !lock
    stateQueue.sync {
      _isAeAfLocked = lock
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
      }
    } catch {
      #if DEBUG
      print("⚠️ CameraViewController: default AF/AE setup failed: \(error.localizedDescription)")
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

  private func saveCaptureToPhotos(
    data: Data,
    uti: String,
    completion: @escaping (Result<String?, Error>) -> Void
  ) {
    requestPhotoLibraryAddAccess { accessResult in
      switch accessResult {
      case .failure(let error):
        completion(.failure(error))
      case .success:
        var localIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
          let request = PHAssetCreationRequest.forAsset()
          let options = PHAssetResourceCreationOptions()
          options.uniformTypeIdentifier = uti
          request.addResource(with: .photo, data: data, options: options)
          localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler: { success, error in
          if let error {
            completion(.failure(error))
            return
          }
          if success {
            completion(.success(localIdentifier))
          } else {
            completion(.failure(CameraControllerError.photoLibraryDenied))
          }
        })
      }
    }
  }

  private func requestPhotoLibraryAddAccess(completion: @escaping (Result<Void, Error>) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          completion(.success(()))
        } else {
          completion(.failure(CameraControllerError.photoLibraryDenied))
        }
      }
      return
    }

    PHPhotoLibrary.requestAuthorization { status in
      if status == .authorized {
        completion(.success(()))
      } else {
        completion(.failure(CameraControllerError.photoLibraryDenied))
      }
    }
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

  private func maybeDispatchHistogram(from image: CIImage) {
    let now = CFAbsoluteTimeGetCurrent()
    let shouldCompute = stateQueue.sync { () -> Bool in
      guard onHistogramUpdated != nil else { return false }
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

    guard maxValue > 0 else { return bins }
    let inv = 1.0 / maxValue
    for index in 0..<bins.count {
      let normalized = bins[index] * inv
      bins[index] = pow(normalized, 0.8)
    }
    return bins
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
  }

  private func applyExposureBias(
    _ requestedBias: Double,
    to device: AVCaptureDevice
  ) throws -> Double {
    let minBias = Double(device.minExposureTargetBias)
    let maxBias = Double(device.maxExposureTargetBias)
    let clamped = min(max(requestedBias, minBias), maxBias)
    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }
    device.setExposureTargetBias(Float(clamped), completionHandler: nil)
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
    histogramUpdateInterval = min(
      histogramMaxInterval,
      max(histogramMinInterval, adaptive)
    )
  }

  private func finishCapture(_ captureResult: Result<[String: Any], Error>) {
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
