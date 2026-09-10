//
//  ScanCoordinatorView.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// Full-screen coordinator orchestrating the 3-step capture (Front, Left, Right) and analysis.
@MainActor
public struct ScanCoordinatorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel: ScanViewModel
    @StateObject private var cameraController: CameraController
    @State private var isCapturing: Bool = false

    public init(viewModel: ScanViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _cameraController = StateObject(wrappedValue: CameraController())
    }

    public var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch viewModel.currentStep {
            case .front, .left, .right:
                captureScreen
            case .processing:
                ScanProcessingView(statusText: viewModel.analysisStatusText)
            case .result:
                ScanResultView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Capture View (Steps 1, 2, 3)

    private var captureScreen: some View {
        VStack(spacing: 0) {
            // Header with Close Button and Progress Indicator
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(Color(uiColor: .systemGray6))
                        .clipShape(Circle())
                }

                Spacer()

                // Step indicator e.g. "Step 1 of 3"
                Text("Step \(viewModel.currentStep.rawValue + 1) of 3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Capsule())

                Spacer()

                // Retake button if previous photos exist
                if viewModel.currentStep != .front {
                    Button("Retake") {
                        viewModel.retakeCurrent()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                } else {
                    Spacer().frame(width: 38)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Step Title & Instructions
            VStack(spacing: 4) {
                Text(viewModel.currentStep.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.currentViewAngle.instruction)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 8)

            // Camera Viewport with Oval Face Guide
            ZStack {
                CameraPreviewView(cameraController: cameraController)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                // Oval face positioning guide overlay
                facePositioningGuide

                // Simulator hint overlay
                #if targetEnvironment(simulator)
                VStack {
                    Spacer()
                    Text("Simulator Mode: Tap shutter to capture simulated scan photo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.bottom, 16)
                }
                #endif
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            // Shutter Button Bar
            HStack {
                Spacer()

                Button(action: {
                    triggerCapture()
                }) {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.textPrimary, lineWidth: 4)
                            .frame(width: 76, height: 76)

                        Circle()
                            .fill(AppTheme.textPrimary)
                            .frame(width: 62, height: 62)
                            .scaleEffect(isCapturing ? 0.85 : 1.0)
                    }
                }
                .disabled(isCapturing)
                .accessibilityLabel("Capture Photo")

                Spacer()
            }
            .padding(.vertical, 20)
        }
    }

    private var facePositioningGuide: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * 0.72
            let height = proxy.size.height * 0.68

            ZStack {
                // Dashed face oval
                Ellipse()
                    .stroke(
                        Color.white.opacity(0.85),
                        style: StrokeStyle(lineWidth: 2.5, dash: [8, 6])
                    )
                    .frame(width: width, height: height)

                // Guidance icon
                if viewModel.currentStep == .left {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 24)
                        Spacer()
                    }
                } else if viewModel.currentStep == .right {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.trailing, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func triggerCapture() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isCapturing = true
        }

        cameraController.capturePhoto { image in
            isCapturing = false
            if let image = image {
                viewModel.handleCapturedImage(image)
            } else {
                viewModel.errorMessage = "Failed to capture photo. Please try again."
            }
        }
    }
}
