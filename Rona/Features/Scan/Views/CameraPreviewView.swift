//
//  CameraPreviewView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
@preconcurrency import AVFoundation
import Combine

/// Handles AVCaptureSession camera preview with simulated fallback for iOS Simulator.
public struct CameraPreviewView: UIViewControllerRepresentable {
    @ObservedObject public var cameraController: CameraController

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
    }

    public func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(cameraController: cameraController)
    }

    public func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.updatePreviewLayer()
    }
}

public final class CameraViewController: UIViewController {
    private let cameraController: CameraController
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var placeholderImageView: UIImageView?

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let imageView = UIImageView(image: cameraController.generateSimulatedFacePhoto())
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        self.placeholderImageView = imageView

        updatePreviewLayer()
    }

    public func updatePreviewLayer() {
        if let session = cameraController.captureSession, cameraController.isSessionRunning {
            if previewLayer?.session !== session {
                previewLayer?.removeFromSuperlayer()
                let layer = AVCaptureVideoPreviewLayer(session: session)
                layer.videoGravity = .resizeAspectFill
                layer.frame = view.bounds
                view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
            }
            placeholderImageView?.isHidden = true
        } else {
            placeholderImageView?.isHidden = false
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

/// Controller managing camera permissions, capture session, and photo capture.
/// Strictly enforces the 1x Normal Camera perspective (avoiding 0.5x ultra-wide distortion).
@MainActor
public final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    public nonisolated let objectWillChange = ObservableObjectPublisher()

    @Published public var isCameraAuthorized: Bool = false
    @Published public var isSessionRunning: Bool = false
    @Published public var isHardwareAvailable: Bool = true
    @Published public var currentPosition: AVCaptureDevice.Position = .front

    public var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var activeDevice: AVCaptureDevice?
    private var captureCompletion: ((UIImage?) -> Void)?

    // 1x Normal zoom factor for front TrueDepth camera (which physically starts at ~0.7x/0.5x)
    private let frontNormalZoomFactor: CGFloat = 1.33

    public override init() {
        super.init()
        checkPermissions()
    }

    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupSession(for: currentPosition)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupSession(for: self?.currentPosition ?? .front)
                    } else {
                        self?.isHardwareAvailable = false
                    }
                }
            }
        default:
            isCameraAuthorized = false
            isHardwareAvailable = false
        }
    }

    public func switchCamera() {
        let newPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
        currentPosition = newPosition
        setupSession(for: newPosition)
    }

    public func setupSession(for position: AVCaptureDevice.Position) {
        // Stop any running session cleanly
        if let existingSession = captureSession {
            DispatchQueue.global(qos: .userInitiated).async {
                existingSession.stopRunning()
            }
            self.captureSession = nil
            self.photoOutput = nil
            self.activeDevice = nil
            self.isSessionRunning = false
        }

        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Strictly target the standard builtInWideAngleCamera (1x Normal Camera), NOT builtInUltraWideCamera (0.5x)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video) else {
            isHardwareAvailable = false
            return
        }

        // Configure normal 1x perspective
        configureNormalZoom(for: device, position: position)

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            isHardwareAvailable = false
            return
        }

        let output = AVCapturePhotoOutput()
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            self.activeDevice = device
            self.captureSession = session
            self.photoOutput = output
            self.isHardwareAvailable = true

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        } else {
            isHardwareAvailable = false
        }
    }

    /// Configures the optical zoom to 1x normal camera perspective (not 0.5x ultra-wide).
    private func configureNormalZoom(for device: AVCaptureDevice, position: AVCaptureDevice.Position) {
        do {
            try device.lockForConfiguration()
            if position == .front {
                // Front TrueDepth camera physically has a ~23mm ultra-wide field of view (~0.7x-0.5x).
                // Zooming to 1.33x yields the standard 1x normal selfie camera framing.
                let targetZoom = frontNormalZoomFactor
                let clamped = max(device.minAvailableVideoZoomFactor, min(targetZoom, device.maxAvailableVideoZoomFactor))
                device.videoZoomFactor = clamped
            } else {
                // Back Main camera is already 1x standard wide angle (24mm-26mm).
                // Ensure zoom factor is strictly 1.0 (not 0.5x ultra-wide).
                let targetZoom: CGFloat = 1.0
                let clamped = max(device.minAvailableVideoZoomFactor, min(targetZoom, device.maxAvailableVideoZoomFactor))
                device.videoZoomFactor = clamped
            }
            device.unlockForConfiguration()
        } catch {
            print("Could not lock camera device for zoom configuration: \(error)")
        }
    }

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

    public nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let originalImage = UIImage(data: data) else {
            Task { @MainActor in
                self.captureCompletion?(nil)
            }
            return
        }

        Task { @MainActor in
            // If front camera was framed at 1.33x normal zoom, crop output photo to match 1x normal perspective
            let finalImage: UIImage
            if self.currentPosition == .front {
                finalImage = self.cropToNormalZoom(image: originalImage, zoomFactor: self.frontNormalZoomFactor)
            } else {
                finalImage = originalImage
            }
            self.captureCompletion?(finalImage)
        }
    }

    /// Crops the captured photo so it matches the 1x normal camera field of view.
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
        if let face = UIImage(contentsOfFile: "/Users/raddhuha/Work/academy/C5/Rona/sample_face.png") {
            return face
        }
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
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
