//
//  AcneDetectorProtocol.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit

/// Protocol abstracting the machine learning object detection engine.
///
/// Views and ViewModels interact exclusively through this interface,
/// keeping UI code completely decoupled from Core ML, Vision, or YOLO models.
public protocol AcneDetectorProtocol: Sendable {
    /// Detects acne lesions in a facial photo for the given view angle.
    ///
    /// - Parameters:
    ///   - image: The captured facial photo (`UIImage`).
    ///   - view: The perspective being scanned (`front`, `left`, `right`).
    /// - Returns: An array of `AcneDetection` structs with normalized bounding boxes and classifications.
    func detect(in image: UIImage, view: ScanViewAngle) async throws -> [AcneDetection]
}
