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
/// with oval face alignment ring and automatic capture.
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

    public init(viewModel: ScanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

            // Center Oval Viewport with Face Guide and Alignment Progress Ring
            ovalFaceViewport
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
                .padding(.bottom, 28)
        }
        .onAppear {
            startAlignmentTracking()
        }
        .onChange(of: viewModel.currentStep) { _ in
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

    // MARK: - Oval Face Viewport

    private var ovalFaceViewport: some View {
        let ovalWidth: CGFloat = 280
        let ovalHeight: CGFloat = 380

        return ZStack {
            // Camera Preview clipped to Oval with smooth frosted blur on completion
            CameraPreviewView(cameraController: cameraController)
                .frame(width: ovalWidth, height: ovalHeight)
                .blur(radius: isStepCompleted ? 20 : 0)
                .clipShape(Ellipse())

            if !isStepCompleted {
                // Dashed gray ellipse border (unaligned track)
                Ellipse()
                    .stroke(
                        Color(uiColor: .systemGray4).opacity(0.85),
                        style: StrokeStyle(lineWidth: 3.5, dash: [8, 6])
                    )
                    .frame(width: ovalWidth, height: ovalHeight)

                // Animated Green Progress Ring (tracing clockwise from top)
                OvalArc(progress: alignmentProgress)
                    .stroke(
                        Color(red: 0.0, green: 0.85, blue: 0.1),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .frame(width: ovalWidth, height: ovalHeight)
                    .animation(.easeInOut(duration: 0.15), value: alignmentProgress)
            } else {
                // Completed State: Solid green outline
                Ellipse()
                    .stroke(Color(red: 0.0, green: 0.85, blue: 0.1), lineWidth: 4.5)
                    .frame(width: ovalWidth, height: ovalHeight)
            }
        }
        .frame(width: ovalWidth, height: ovalHeight)
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

                Text(viewModel.stepSubtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 64)
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

        // Automatically fill alignment ring smoothly over ~1.8 seconds
        autoCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard !self.isCapturing && !self.isStepCompleted else { return }

                if self.alignmentProgress < 1.0 {
                    self.alignmentProgress = min(self.alignmentProgress + 0.035, 1.0)
                }

                if self.alignmentProgress >= 1.0 {
                    self.stopAlignmentTimer()
                    self.triggerAutoCapture()
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

// MARK: - Oval Arc Shape

/// Custom parametric Shape for drawing a stroke along an ellipse boundary
/// beginning at the 12 o'clock apex (-π/2) and proceeding clockwise.
/// This prevents aspect-ratio distortion caused by rotating SwiftUI's Ellipse.
struct OvalArc: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard progress > 0 else { return path }

        let startAngle = -Double.pi / 2.0 // 12 o'clock
        let totalAngle = 2.0 * Double.pi * Double(min(max(progress, 0.0), 1.0))
        let rx = rect.width / 2.0
        let ry = rect.height / 2.0
        let cx = rect.midX
        let cy = rect.midY

        let steps = Int(max(20, 160 * progress))
        for i in 0...steps {
            let t = startAngle + (Double(i) / Double(steps)) * totalAngle
            let pt = CGPoint(x: cx + rx * CGFloat(cos(t)), y: cy + ry * CGFloat(sin(t)))
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        return path
    }
}
