//
//  SummaryProgressCard.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI

/// Smooth cubic sparkline curve drawing progress across time.
public struct SmoothSparklineShape: Shape {
    public let normalizedPoints: [CGPoint] // x: 0...1, y: 0...1 (0 = bottom, 1 = top)

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        guard normalizedPoints.count > 1 else { return path }

        // Convert normalized coordinates to rect coordinates (inverted Y for SwiftUI)
        let points = normalizedPoints.map { pt in
            CGPoint(
                x: rect.minX + pt.x * rect.width,
                y: rect.maxY - pt.y * rect.height
            )
        }

        path.move(to: points[0])

        for i in 0..<points.count - 1 {
            let p0 = i > 0 ? points[i - 1] : points[i]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = i + 2 < points.count ? points[i + 2] : p2

            // Catmull-Rom to Cubic Bézier conversion
            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        return path
    }
}

/// "How you've been doing" progress card with smooth 30-day sparkline and score indicator matching the reference design.
public struct SummaryProgressCard: View {
    public let headline: String
    public let currentScore: Int
    public let points: [CGPoint]

    public init(
        headline: String = "You've made steady progress this last 30 days — whatever you're doing, it's working!",
        currentScore: Int = 80,
        points: [CGPoint] = Self.defaultPoints
    ) {
        self.headline = headline
        self.currentScore = currentScore
        self.points = points.isEmpty ? Self.defaultPoints : points
    }

    public static var defaultPoints: [CGPoint] {
        // Realistic progression curve matching reference screenshot:
        // Starts around 0.20, climbs to ~0.65, dips to ~0.35, then ascends to 0.85 (score 80)
        [
            CGPoint(x: 0.08, y: 0.22),
            CGPoint(x: 0.16, y: 0.26),
            CGPoint(x: 0.23, y: 0.44),
            CGPoint(x: 0.30, y: 0.65),
            CGPoint(x: 0.37, y: 0.60),
            CGPoint(x: 0.45, y: 0.40),
            CGPoint(x: 0.52, y: 0.46),
            CGPoint(x: 0.58, y: 0.24),
            CGPoint(x: 0.65, y: 0.32),
            CGPoint(x: 0.72, y: 0.21),
            CGPoint(x: 0.80, y: 0.30),
            CGPoint(x: 0.88, y: 0.18),
            CGPoint(x: 0.95, y: 0.58),
            CGPoint(x: 0.98, y: 0.82)
        ]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top row: headline + chevron
            HStack(alignment: .top, spacing: 12) {
                Text(headline)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: .systemGray3))
                    .padding(.top, 2)
            }

            // Chart area
            VStack(spacing: 8) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    ZStack(alignment: .topLeading) {
                        // Smooth sparkline curve
                        SmoothSparklineShape(normalizedPoints: points)
                            .stroke(
                                Color(uiColor: .systemGray).opacity(0.85),
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
                            )

                        // Score label floating right above the curve's endpoint
                        if let lastPoint = points.last {
                            let endX = lastPoint.x * w
                            let endY = (1.0 - lastPoint.y) * h

                            Text("\(currentScore)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(uiColor: .darkGray))
                                .position(x: endX - 4, y: max(endY - 14, 8))
                        }
                    }
                }
                .frame(height: 90)
                .padding(.top, 6)

                // Baseline horizontal axis
                Rectangle()
                    .fill(Color(uiColor: .systemGray4).opacity(0.8))
                    .frame(height: 1)

                // X-Axis Labels: "30 days ago" and "Today"
                HStack {
                    Text("30 days ago")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    Spacer()

                    Text("Today")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(uiColor: .systemGray4).opacity(0.5), lineWidth: 1)
        )
    }
}
