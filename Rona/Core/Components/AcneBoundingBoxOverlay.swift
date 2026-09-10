//
//  AcneBoundingBoxOverlay.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Overlays normalized bounding boxes and labels on top of a facial scan photo.
public struct AcneBoundingBoxOverlay: View {
    private let detections: [AcneDetection]
    private let showLabels: Bool
    private let showConfidence: Bool

    public init(
        detections: [AcneDetection],
        showLabels: Bool = true,
        showConfidence: Bool = false
    ) {
        self.detections = detections
        self.showLabels = showLabels
        self.showConfidence = showConfidence
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ForEach(detections) { detection in
                let rect = CGRect(
                    x: detection.boundingBox.origin.x * size.width,
                    y: detection.boundingBox.origin.y * size.height,
                    width: max(detection.boundingBox.size.width * size.width, 18),
                    height: max(detection.boundingBox.size.height * size.height, 18)
                )

                ZStack(alignment: .topLeading) {
                    // Lesion bounding box border
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(detection.acneType.visualColor, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(detection.acneType.visualColor.opacity(0.18))
                        )
                        .frame(width: rect.width, height: rect.height)

                    // Optional label pill
                    if showLabels {
                        HStack(spacing: 3) {
                            Text(detection.acneType.displayName)
                                .font(.system(size: 9, weight: .bold))

                            if showConfidence {
                                Text("\(Int(detection.confidence * 100))%")
                                    .font(.system(size: 8, weight: .regular))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(detection.acneType.visualColor)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .offset(y: -14)
                    }
                }
                .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}
