//
//  ScanCoordinatorView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine
import AudioToolbox

/// Full-screen coordinator orchestrating the 3-step capture (Front, Right, Left)
/// with circular face alignment ring and automatic capture.
@MainActor
public struct ScanCoordinatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ScanViewModel
    @StateObject private var cameraController: CameraController

    @State private var alignmentProgress: CGFloat = 0.0
    @State private var isStepCompleted: Bool = false
    @State private var isCapturing: Bool = false
    @State private var autoCaptureTimer: Timer?

    public init(viewModel: ScanViewModel? = nil) {
        let vm = viewModel ?? ScanViewModel(
            acneDetector: AppContainer.preview.acneDetector,
            scoreCalculator: AppContainer.preview.scoreCalculator,
            insightGenerator: AppContainer.preview.insightGenerator,
            scanRepository: AppContainer.preview.scanRepository,
            imageStorage: AppContainer.preview.imageStorage
        )
        _viewModel = StateObject(wrappedValue: vm)
        _cameraController = StateObject(wrappedValue: CameraController())
    }

    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch viewModel.currentStep {
            case .front, .right, .left:
                captureScreen
            case .processing:
                ScanProcessingView(statusText: viewModel.analysisStatusText)
            case .result:
                ScanResultView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.light)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-testScanResult") {
                if viewModel.sessionResult == nil {
                    let photo = cameraController.generateSimulatedFacePhoto()
                    viewModel.frontImage = photo
                    viewModel.rightImage = photo
                    viewModel.leftImage = photo
                    viewModel.createImmediateScanResult()
                    viewModel.currentStep = .result
                }
            }
            #endif
        }
    }

    // MARK: - Capture Screen (Steps 1, 2, 3)

    private var captureScreen: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            topNavigationBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Spacer()

            // Center Circular Viewport with Face Guide and Alignment Progress Ring
            circleFaceViewport
                .onTapGesture {
                    // Tapping circle instantly completes alignment for convenience/testing
                    if !isStepCompleted && !isCapturing {
                        triggerAutoCapture()
                    }
                }

            Spacer()

            // Instructions / Completion State below Circle
            instructionSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Step Counter at Bottom
            stepCounterSection
                .padding(.bottom, 28)
        }
        .onAppear {
            cameraController.currentScanAngle = viewModel.currentViewAngle
            startAlignmentTracking()
        }
        .onChange(of: viewModel.currentStep) { _ in
            cameraController.currentScanAngle = viewModel.currentViewAngle
            startAlignmentTracking()
        }
        .onDisappear {
            stopAlignmentTimer()
        }
    }

    // MARK: - Navigation Bar

    private var topNavigationBar: some View {
        ZStack {
            // Centered Title
            Text("Scan")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            // Leading Circular Back Button and Trailing Camera Switch Button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scan_back_button")

                Spacer()

                Button(action: {
                    cameraController.switchCamera()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("scan_switch_camera_button")
            }
        }
    }

    // MARK: - Circular Face Viewport

    private var circleFaceViewport: some View {
        let circleDiameter: CGFloat = 300

        return ZStack {
            // Live Camera Preview clipped to Circle with smooth frosted blur on completion
            CameraPreviewView(cameraController: cameraController)
                .frame(width: circleDiameter, height: circleDiameter)
                .blur(radius: isStepCompleted ? 20 : 0)
                .clipShape(Circle())

            if !isStepCompleted {
                // Dashed gray circle border (unaligned guide track)
                Circle()
                    .stroke(
                        Color(uiColor: .systemGray4).opacity(0.85),
                        style: StrokeStyle(lineWidth: 3.5, dash: [8, 6])
                    )
                    .frame(width: circleDiameter, height: circleDiameter)

                // Animated Green Progress Ring (tracing clockwise from 12 o'clock)
                Circle()
                    .trim(from: 0.0, to: alignmentProgress)
                    .stroke(
                        Color(red: 0.0, green: 0.85, blue: 0.1),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: circleDiameter, height: circleDiameter)
                    .animation(.linear(duration: 0.05), value: alignmentProgress)
            } else {
                // Completed State: Solid green outline
                Circle()
                    .stroke(Color(red: 0.0, green: 0.85, blue: 0.1), lineWidth: 4.5)
                    .frame(width: circleDiameter, height: circleDiameter)
            }
        }
        .frame(width: circleDiameter, height: circleDiameter)
    }

    // MARK: - Instruction Section

    private var instructionSection: some View {
        VStack(spacing: 6) {
            if isStepCompleted {
                HStack(spacing: 8) {
                    Text(viewModel.stepCompletionText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.1))

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.1))
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                Text(viewModel.stepTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(dynamicSubtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(cameraController.isAligned ? Color(red: 0.0, green: 0.75, blue: 0.1) : AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.2), value: dynamicSubtitle)
            }
        }
        .frame(height: 64)
        .animation(.easeInOut(duration: 0.25), value: isStepCompleted)
    }

    private var dynamicSubtitle: String {
        if cameraController.isHardwareAvailable && cameraController.isSessionRunning {
            switch cameraController.alignmentStatus {
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
        return viewModel.stepSubtitle
    }

    // MARK: - Step Counter Section

    private var stepCounterSection: some View {
        Text(viewModel.stepCounterText)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .opacity(isStepCompleted ? 0 : 1)
            .animation(.easeInOut(duration: 0.2), value: isStepCompleted)
    }

    // MARK: - Alignment & Auto-Capture Logic

    private func startAlignmentTracking() {
        stopAlignmentTimer()
        alignmentProgress = 0.0
        isStepCompleted = false
        isCapturing = false

        // Gated auto-capture timer:
        // When aligned with the circle, green countdown progresses smoothly over ~1.5 seconds.
        // If face moves out of alignment (outside circle, wrong pose), countdown pauses and rewinds.
        autoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard !self.isCapturing && !self.isStepCompleted else { return }

                let isAligned = self.cameraController.isAligned || (!self.cameraController.isHardwareAvailable)

                if isAligned {
                    if self.alignmentProgress < 1.0 {
                        self.alignmentProgress = min(self.alignmentProgress + 0.035, 1.0)
                    }

                    if self.alignmentProgress >= 1.0 {
                        self.stopAlignmentTimer()
                        self.triggerAutoCapture()
                    }
                } else {
                    // Face is not aligned inside circle: countdown does not proceed
                    if self.alignmentProgress > 0 {
                        self.alignmentProgress = max(self.alignmentProgress - 0.06, 0.0)
                    }
                }
            }
        }
    }

    private func stopAlignmentTimer() {
        autoCaptureTimer?.invalidate()
        autoCaptureTimer = nil
    }

    private func triggerAutoCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        alignmentProgress = 1.0

        // Haptic feedback upon alignment capture
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1108) // Camera shutter sound

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            isStepCompleted = true
        }

        cameraController.capturePhoto { capturedImage in
            let photo = capturedImage ?? cameraController.generateSimulatedFacePhoto()

            // Pause 0.75 seconds to display "Front side Complete ✅" before advancing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                viewModel.handleCapturedImage(photo)
            }
        }
    }
}

#Preview {
    ScanCoordinatorView()
        .environmentObject(AppRouter())
}

