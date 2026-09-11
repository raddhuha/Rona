//
//  CameraPreviewView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
@preconcurrency import AVFoundation
import Vision
import Combine

/// Real-time status of face alignment within the on-screen circle guide.
public enum FaceAlignmentStatus: Equatable {
    case noFace
    case notInCircle
    case lookStraight
    case turnRight
    case turnLeft
    case aligned

    public func userGuidance(for angle: ScanViewAngle) -> String {
        switch self {
        case .noFace:
            return "Position your face inside the circle"
        case .notInCircle:
            return "Align your face inside the circle"
        case .lookStraight:
            return "Look straight ahead"
        case .turnRight:
            return "Turn your face to the right"
        case .turnLeft:
            return "Turn your face to the left"
        case .aligned:
            return "Hold still — capturing..."
        }
    }
}

/// Custom UIView whose backing layer is AVCaptureVideoPreviewLayer.
public final class PreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

/// Handles AVCaptureSession camera preview with real-time video preview and simulated fallback.
public struct CameraPreviewView: UIViewControllerRepresentable {
    @ObservedObject public var cameraController: CameraController

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
    }

    public func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(cameraController: cameraController)
    }

    public func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.updatePreviewSession()
    }

    public static func dismantleUIViewController(_ uiViewController: CameraViewController, coordinator: ()) {
        uiViewController.dismantle()
    }
}

public final class CameraViewController: UIViewController {
    private let cameraController: CameraController
    private var previewView: PreviewUIView!
    private var placeholderImageView: UIImageView?

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func loadView() {
        previewView = PreviewUIView()
        previewView.backgroundColor = .black
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        view = previewView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        updatePreviewSession()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismantle()
    }

    public func dismantle() {
        if previewView?.videoPreviewLayer.session != nil {
            previewView?.videoPreviewLayer.session = nil
        }
        cameraController.teardownHardwareSession()
    }

    public func stop() {
        dismantle()
    }

    public func updatePreviewSession() {
        if let session = cameraController.captureSession {
            if previewView.videoPreviewLayer.session !== session {
                previewView.videoPreviewLayer.session = session
            }
            if let connection = previewView.videoPreviewLayer.connection {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = (cameraController.currentPosition == .front)
                }
            }
            placeholderImageView?.removeFromSuperview()
            placeholderImageView = nil
        } else if !cameraController.isHardwareAvailable {
            showPlaceholder()
        }
    }

    private func showPlaceholder() {
        guard placeholderImageView == nil else { return }
        let iv = UIImageView(image: cameraController.generateSimulatedFacePhoto())
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: view.topAnchor),
            iv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            iv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        placeholderImageView = iv
    }
}

/// Controller managing live camera permissions, capture session, real-time face alignment, and photo capture.
@MainActor
public final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @Published public var isSessionRunning: Bool = false
    @Published public var isHardwareAvailable: Bool = true
    @Published public var currentPosition: AVCaptureDevice.Position = .front
    @Published public var currentScanAngle: ScanViewAngle = .front

    @Published public var alignmentStatus: FaceAlignmentStatus = .noFace
    @Published public var isAligned: Bool = false

    public var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var captureCompletion: ((UIImage?) -> Void)?

    private let videoProcessingQueue = DispatchQueue(label: "com.rona.faceProcessingQueue", qos: .userInteractive)
    nonisolated(unsafe) private var isAnalyzingFrame = false

    public override init() {
        super.init()
        checkPermissions()
    }

    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession(for: currentPosition)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession(for: self?.currentPosition ?? .front)
                    } else {
                        self?.isHardwareAvailable = false
                    }
                }
            }
        default:
            isHardwareAvailable = false
        }
    }

    public func switchCamera() {
        let newPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
        currentPosition = newPosition
        setupSession(for: newPosition)
    }

    public func setupSession(for position: AVCaptureDevice.Position) {
        // Stop existing session cleanly
        if let existingSession = captureSession {
            DispatchQueue.global(qos: .userInitiated).async {
                existingSession.stopRunning()
            }
            self.captureSession = nil
            self.photoOutput = nil
            self.videoDataOutput = nil
            self.isSessionRunning = false
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video) else {
            isHardwareAvailable = false
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            isHardwareAvailable = false
            return
        }

        let photoOut = AVCapturePhotoOutput()
        let videoOut = AVCaptureVideoDataOutput()
        videoOut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOut.alwaysDiscardsLateVideoFrames = true
        videoOut.setSampleBufferDelegate(self, queue: videoProcessingQueue)

        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(photoOut) {
            session.addOutput(photoOut)
        }
        if session.canAddOutput(videoOut) {
            session.addOutput(videoOut)
        }

        // Configure video orientation and mirroring on photo and video connections
        if let photoConnection = photoOut.connection(with: .video) {
            if photoConnection.isVideoOrientationSupported {
                photoConnection.videoOrientation = .portrait
            }
            if photoConnection.isVideoMirroringSupported {
                photoConnection.automaticallyAdjustsVideoMirroring = false
                photoConnection.isVideoMirrored = (position == .front)
            }
        }

        if let videoConnection = videoOut.connection(with: .video) {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = .portrait
            }
            if videoConnection.isVideoMirroringSupported {
                videoConnection.automaticallyAdjustsVideoMirroring = false
                videoConnection.isVideoMirrored = (position == .front)
            }
        }

        session.commitConfiguration()

        do {
            try device.lockForConfiguration()
            if position == .front {
                // Physical TrueDepth front camera has a ~23mm ultra-wide field of view (~0.7x).
                // Zooming to 1.33x yields the standard 1x normal selfie camera framing (matching Apple's native Camera app).
                let targetZoom: CGFloat = 1.33
                let clamped = max(device.minAvailableVideoZoomFactor, min(targetZoom, device.maxAvailableVideoZoomFactor))
                device.videoZoomFactor = clamped
            } else {
                let targetZoom: CGFloat = 1.0
                let clamped = max(device.minAvailableVideoZoomFactor, min(targetZoom, device.maxAvailableVideoZoomFactor))
                device.videoZoomFactor = clamped
            }
            device.unlockForConfiguration()
        } catch {
            print("Could not lock camera device for zoom configuration: \(error)")
        }

        self.captureSession = session
        self.photoOutput = photoOut
        self.videoDataOutput = videoOut
        self.isHardwareAvailable = true

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = session.isRunning
            }
        }
    }

    public func startSession() {
        guard let session = captureSession else {
            setupSession(for: currentPosition)
            return
        }
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoProcessingQueue)
        guard !session.isRunning else {
            self.isSessionRunning = true
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = session.isRunning
            }
        }
    }

    /// Safely detaches delegates and stops the hardware capture session asynchronously
    /// without mutating any @Published properties.
    /// Safe to call during SwiftUI dismantle / deinit lifecycles to prevent exclusivity violations.
    public func teardownHardwareSession() {
        videoDataOutput?.setSampleBufferDelegate(nil, queue: nil)
        guard let session = captureSession else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    public func stopSession() {
        teardownHardwareSession()
        self.isSessionRunning = false
        self.isAligned = false
        self.alignmentStatus = .noFace
    }

    deinit {
        if let session = captureSession {
            DispatchQueue.global(qos: .userInitiated).async {
                if session.isRunning {
                    session.stopRunning()
                }
            }
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    public nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isAnalyzingFrame else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        isAnalyzingFrame = true

        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNFaceObservation] ?? []
            let primaryFace = observations.first

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.processDetectedFace(primaryFace)
                self.isAnalyzingFrame = false
            }
        } catch {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.alignmentStatus = .noFace
                self.isAligned = false
                self.isAnalyzingFrame = false
            }
        }
    }

    private func processDetectedFace(_ face: VNFaceObservation?) {
        guard let face = face else {
            self.alignmentStatus = .noFace
            self.isAligned = false
            return
        }

        // Vision coordinates: (0,0) is bottom-left, (1,1) is top-right.
        // Convert to standard UI normalized coordinates: (0,0) is top-left.
        let box = face.boundingBox
        let uiX = box.origin.x
        let uiY = 1.0 - box.origin.y - box.height
        let uiW = box.width
        let uiH = box.height

        let faceCenterX = uiX + uiW / 2.0
        let faceCenterY = uiY + uiH / 2.0

        // Yaw angle in degrees (head rotation left/right around vertical axis)
        let yawRadians = face.yaw?.doubleValue ?? 0.0
        let yawDegrees = yawRadians * 180.0 / .pi

        // Circle Alignment Check:
        // When video fills the circle view with .resizeAspectFill, the center of the circle
        // is at (0.5, 0.5) in the camera frame.
        let dx = abs(faceCenterX - 0.5)
        let dy = abs(faceCenterY - 0.5)
        let isCenteredInCircle = (dx <= 0.18) && (dy <= 0.20)

        // Check if face size reasonably fits inside the circle (not spilling far outside or tiny dot)
        let fitsCircle = (uiH >= 0.26 && uiH <= 0.78) && (uiW >= 0.22 && uiW <= 0.72)

        guard isCenteredInCircle && fitsCircle else {
            self.alignmentStatus = .notInCircle
            self.isAligned = false
            return
        }

        // Step-specific pose check:
        // Front: look straight ahead into the circle
        // Right: user turned head to the right
        // Left: user turned head to the left
        switch currentScanAngle {
        case .front:
            if abs(yawDegrees) > 16.0 {
                self.alignmentStatus = .lookStraight
                self.isAligned = false
            } else {
                self.alignmentStatus = .aligned
                self.isAligned = true
            }

        case .right:
            if yawDegrees > 14.0 || (face.yaw != nil && yawDegrees > 12.0) {
                self.alignmentStatus = .aligned
                self.isAligned = true
            } else {
                self.alignmentStatus = .turnRight
                self.isAligned = false
            }

        case .left:
            if yawDegrees < -14.0 || (face.yaw != nil && yawDegrees < -12.0) {
                self.alignmentStatus = .aligned
                self.isAligned = true
            } else {
                self.alignmentStatus = .turnLeft
                self.isAligned = false
            }
        }
    }

    // MARK: - Photo Capture

    public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let output = photoOutput, isSessionRunning else {
            // Provide simulated capture fallback for simulator or camera-less testing
            completion(generateSimulatedFacePhoto())
            return
        }

        self.captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let originalImage = UIImage(data: data) else {
            Task { @MainActor in
                self.captureCompletion?(nil)
            }
            return
        }

        Task { @MainActor in
            let uprightImage = originalImage.normalizedUpOrientation()
            let finalImage: UIImage
            if self.currentPosition == .front {
                finalImage = self.cropToNormalZoom(image: uprightImage, zoomFactor: 1.33)
            } else {
                finalImage = uprightImage
            }
            self.captureCompletion?(finalImage)
        }
    }

    /// Crops the captured photo so it matches the 1.33x normal camera field of view.
    private func cropToNormalZoom(image: UIImage, zoomFactor: CGFloat) -> UIImage {
        guard zoomFactor > 1.0, let cgImage = image.cgImage else { return image }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let cropW = width / zoomFactor
        let cropH = height / zoomFactor
        let cropX = (width - cropW) / 2.0
        let cropY = (height - cropH) / 2.0
        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        guard let croppedCg = cgImage.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: croppedCg, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Generates a clean synthetic face image for simulator testing.
    public func generateSimulatedFacePhoto() -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext

            // Background
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.94, green: 0.88, blue: 0.82, alpha: 1.0).setFill()
            ctx.fill(rect)

            let faceOval = CGRect(x: 120, y: 150, width: 360, height: 500)
            UIColor(red: 0.97, green: 0.91, blue: 0.85, alpha: 1.0).setFill()
            ctx.cgContext.fillEllipse(in: faceOval)

            UIColor(red: 0.80, green: 0.70, blue: 0.65, alpha: 0.5).setStroke()
            ctx.cgContext.setLineWidth(2.0)
            ctx.cgContext.strokeEllipse(in: faceOval)
        }
    }
}

// MARK: - UIImage Orientation Helper

extension UIImage {
    /// Normalizes image orientation to .up so all downstream CoreML/Vision and UI operations work consistently.
    public func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}
