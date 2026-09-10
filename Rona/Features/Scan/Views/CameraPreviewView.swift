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
    public let cameraController: CameraController

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
    }

    public func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(cameraController: cameraController)
    }

    public func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

public final class CameraViewController: UIViewController {
    private let cameraController: CameraController
    private var previewLayer: AVCaptureVideoPreviewLayer?

    public init(cameraController: CameraController) {
        self.cameraController = cameraController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        if let session = cameraController.captureSession {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
            self.previewLayer = layer
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

/// Controller managing camera permissions, capture session, and photo capture.
@MainActor
public final class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    public nonisolated let objectWillChange = ObservableObjectPublisher()

    @Published public var isCameraAuthorized: Bool = false
    @Published public var isSessionRunning: Bool = false
    @Published public var isHardwareAvailable: Bool = true

    public var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureCompletion: ((UIImage?) -> Void)?

    public override init() {
        super.init()
        checkPermissions()
    }

    public func checkPermissions() {
        #if targetEnvironment(simulator)
        isHardwareAvailable = false
        isCameraAuthorized = true
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            isCameraAuthorized = false
        }
        #endif
    }

    public func setupSession() {
        #if !targetEnvironment(simulator)
        guard captureSession == nil else { return }
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Front-facing camera for skin selfies
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            isHardwareAvailable = false
            return
        }

        let output = AVCapturePhotoOutput()
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            self.captureSession = session
            self.photoOutput = output

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        } else {
            isHardwareAvailable = false
        }
        #endif
    }

    public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        #if targetEnvironment(simulator)
        // Provide simulated capture on Simulator
        completion(generateSimulatedFacePhoto())
        #else
        guard let output = photoOutput else {
            completion(generateSimulatedFacePhoto())
            return
        }

        self.captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
        #endif
    }

    public nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in
                self.captureCompletion?(nil)
            }
            return
        }

        Task { @MainActor in
            self.captureCompletion?(image)
        }
    }

    /// Generates a clean synthetic face image for simulator testing.
    public func generateSimulatedFacePhoto() -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Soft skin tone gradient background
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.94, green: 0.88, blue: 0.82, alpha: 1.0).setFill()
            ctx.fill(rect)

            // Face contour oval
            let faceOval = CGRect(x: 120, y: 150, width: 360, height: 500)
            UIColor(red: 0.97, green: 0.91, blue: 0.85, alpha: 1.0).setFill()
            ctx.cgContext.fillEllipse(in: faceOval)

            // Subtle simulated feature marks
            UIColor(red: 0.80, green: 0.70, blue: 0.65, alpha: 0.5).setStroke()
            ctx.cgContext.setLineWidth(2.0)
            ctx.cgContext.strokeEllipse(in: faceOval)
        }
    }
}
