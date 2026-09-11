//
//  ScanCoordinatorView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine
import AudioToolbox

/// Parametric shape tracing the perimeter of an oval / ellipse clockwise from 12 o'clock.
public struct OvalProgressShape: Shape {
    public var progress: CGFloat // 0.0 ... 1.0

    public var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0 else { return path }

        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2

        let clampedProgress = min(max(progress, 0.0), 1.0)
        let totalAngle = 2 * CGFloat.pi * clampedProgress
        let startAngle = -CGFloat.pi / 2
        let steps = max(Int(clampedProgress * 90), 6)

        for i in 0...steps {
            let t = startAngle + (totalAngle * CGFloat(i) / CGFloat(steps))
            let x = cx + rx * cos(t)
            let y = cy + ry * sin(t)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

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
        .onDisappear {
            stopAlignmentTimer()
            cameraController.teardownHardwareSession()
        }
    }

    // MARK: - Capture Screen (Steps 1, 2, 3)

    private var captureScreen: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            topNavigationBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

            Spacer()

            // Center Oval Viewport with Face Guide and Alignment Progress Ring
            ovalFaceViewport
                .contentShape(Ellipse())
                .onTapGesture {
                    // Tapping oval instantly completes alignment for convenience/testing
                    if !isStepCompleted && !isCapturing {
                        triggerAutoCapture()
                    }
                }

            Spacer()

            // Instructions / Completion State below Oval
            instructionSection
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Step Counter at Bottom
            stepCounterSection
                .padding(.bottom, 24)
        }
        .onAppear {
            cameraController.currentScanAngle = viewModel.currentViewAngle
            cameraController.startSession()
            startAlignmentTracking()
        }
        .onChange(of: viewModel.currentStep) { newStep in
            if newStep == .processing || newStep == .result {
                stopAlignmentTimer()
                cameraController.teardownHardwareSession()
            } else {
                cameraController.currentScanAngle = viewModel.currentViewAngle
                cameraController.startSession()
                startAlignmentTracking()
            }
        }
        .onDisappear {
            stopAlignmentTimer()
            cameraController.teardownHardwareSession()
        }
    }

    // MARK: - Navigation Bar

    private var topNavigationBar: some View {
        ZStack {
            // Centered Title
            Text("Scan")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            // Leading Circular Back Button
            HStack {
                Button(action: {
                    stopAlignmentTimer()
                    cameraController.teardownHardwareSession()
                    router.dismissScanFlow()
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
            }
        }
    }

    // MARK: - Oval Face Viewport

    private var ovalFaceViewport: some View {
        let ovalWidth: CGFloat = 280
        let ovalHeight: CGFloat = 380
        let vividGreen = Color(red: 0.0, green: 0.85, blue: 0.08)
        let darkDashedGray = Color(red: 0.42, green: 0.42, blue: 0.42)

        return ZStack {
            // Live Camera Preview clipped to Ellipse with frosted blur on completion
            CameraPreviewView(cameraController: cameraController)
                .frame(width: ovalWidth, height: ovalHeight)
                .blur(radius: isStepCompleted ? 18 : 0)
                .clipShape(Ellipse())

            if !isStepCompleted {
                // Dashed dark gray ellipse border (unaligned guide track)
                Ellipse()
                    .stroke(
                        darkDashedGray,
                        style: StrokeStyle(lineWidth: 3.5, dash: [6, 6])
                    )
                    .frame(width: ovalWidth, height: ovalHeight)

                // Animated Green Progress Stroke (tracing clockwise from 12 o'clock)
                OvalProgressShape(progress: alignmentProgress)
                    .stroke(
                        vividGreen,
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .butt)
                    )
                    .frame(width: ovalWidth, height: ovalHeight)
                    .animation(.linear(duration: 0.05), value: alignmentProgress)
            } else {
                // Completed State: Solid green outline
                Ellipse()
                    .stroke(vividGreen, lineWidth: 4.5)
                    .frame(width: ovalWidth, height: ovalHeight)
            }
        }
        .frame(width: ovalWidth, height: ovalHeight)
    }

    // MARK: - Instruction Section

    private var instructionSection: some View {
        let vividGreen = Color(red: 0.0, green: 0.85, blue: 0.08)

        return VStack(spacing: 8) {
            if isStepCompleted {
                HStack(spacing: 8) {
                    Text(viewModel.stepCompletionText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(vividGreen)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(vividGreen)
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                Text(viewModel.stepTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(viewModel.stepSubtitle)
                    .font(.system(size: 14.5, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }
        }
        .frame(height: 72)
        .animation(.easeInOut(duration: 0.25), value: isStepCompleted)
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

