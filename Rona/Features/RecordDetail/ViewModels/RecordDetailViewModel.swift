//
//  RecordDetailViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine
import UIKit

/// The page sections in the record detail photo carousel.
public enum DetailPageKind: String, CaseIterable, Identifiable, Hashable {
    case fullFace = "fullFace"
    case forehead = "forehead"
    case rightCheek = "rightCheek"
    case leftCheek = "leftCheek"
    case nose = "nose"
    case chin = "chin"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fullFace: return "Full Face"
        case .forehead: return "Forehead"
        case .rightCheek: return "Right Cheek"
        case .leftCheek: return "Left Cheek"
        case .nose: return "Nose"
        case .chin: return "Chin"
        }
    }

    public var region: FacialRegion? {
        switch self {
        case .fullFace: return nil
        case .forehead: return .forehead
        case .rightCheek: return .rightCheek
        case .leftCheek: return .leftCheek
        case .nose: return .nose
        case .chin: return .chin
        }
    }
}

/// ViewModel managing a single scan record's detailed breakdown and deletion.
@MainActor
public final class RecordDetailViewModel: ObservableObject {
    public let recordId: UUID

    @Published public var record: ScanRecord?
    @Published public var previousRecord: ScanRecord?
    @Published public var frontImage: UIImage?
    @Published public var leftImage: UIImage?
    @Published public var rightImage: UIImage?
    @Published public var croppedImages: [DetailPageKind: UIImage] = [:]
    @Published public var selectedPage: DetailPageKind = .fullFace
    @Published public var showDeleteConfirmation: Bool = false
    @Published public var isDeleted: Bool = false

    private let scanRepository: ScanRepositoryProtocol
    private let imageStorage: ImageStorageProtocol

    public init(
        recordId: UUID,
        scanRepository: ScanRepositoryProtocol,
        imageStorage: ImageStorageProtocol,
        record: ScanRecord? = nil
    ) {
        self.recordId = recordId
        self.scanRepository = scanRepository
        self.imageStorage = imageStorage
        self.record = record

        if let rec = record {
            setupImages(for: rec)
        }
    }

    public func loadRecord() async {
        do {
            if let found = try await scanRepository.fetchById(recordId) {
                record = found
                frontImage = imageStorage.loadImage(fromPath: found.frontImagePath)
                leftImage = imageStorage.loadImage(fromPath: found.leftImagePath)
                rightImage = imageStorage.loadImage(fromPath: found.rightImagePath)
                previousRecord = try await scanRepository.getPreviousRecord(before: found.date)
                generateCroppedImages()
            }
        } catch {
            print("Failed to load record details: \(error)")
        }
    }

    public func deleteRecord() async {
        do {
            try await scanRepository.delete(id: recordId)
            isDeleted = true
        } catch {
            print("Failed to delete record: \(error)")
        }
    }

    public func image(for page: DetailPageKind) -> UIImage? {
        if let cached = croppedImages[page] {
            return cached
        }
        switch page {
        case .fullFace:
            return frontImage
        case .forehead, .nose, .chin:
            return croppedRegionImage(for: page, base: frontImage)
        case .rightCheek:
            return rightImage ?? croppedRegionImage(for: .rightCheek, base: frontImage)
        case .leftCheek:
            return leftImage ?? croppedRegionImage(for: .leftCheek, base: frontImage)
        }
    }

    public func generateCroppedImages() {
        guard let base = frontImage else { return }
        for page in DetailPageKind.allCases {
            if let cropped = croppedRegionImage(for: page, base: base) {
                croppedImages[page] = cropped
            }
        }
    }

    private func croppedRegionImage(for page: DetailPageKind, base: UIImage?) -> UIImage? {
        guard let base = base else { return nil }
        let rect: CGRect
        switch page {
        case .fullFace:
            return base
        case .forehead:
            rect = CGRect(x: 0.16, y: 0.08, width: 0.68, height: 0.30)
        case .rightCheek:
            if let right = rightImage {
                return right
            }
            rect = CGRect(x: 0.48, y: 0.34, width: 0.46, height: 0.38)
        case .leftCheek:
            if let left = leftImage {
                return left
            }
            rect = CGRect(x: 0.06, y: 0.34, width: 0.46, height: 0.38)
        case .nose:
            rect = CGRect(x: 0.28, y: 0.34, width: 0.44, height: 0.34)
        case .chin:
            rect = CGRect(x: 0.24, y: 0.64, width: 0.52, height: 0.32)
        }
        return base.cropped(to: rect)
    }

    private func setupImages(for record: ScanRecord) {
        frontImage = imageStorage.loadImage(fromPath: record.frontImagePath)
        leftImage = imageStorage.loadImage(fromPath: record.leftImagePath)
        rightImage = imageStorage.loadImage(fromPath: record.rightImagePath)
        generateCroppedImages()
    }

    public func countsByType(for page: DetailPageKind) -> [AcneType: Int] {
        guard let record = record else { return [:] }
        if let region = page.region {
            var counts: [AcneType: Int] = [:]
            for type in AcneType.allCases {
                counts[type] = 0
            }
            for d in record.detections where d.facialRegion == region {
                counts[d.acneType, default: 0] += 1
            }
            return counts
        } else {
            return record.countsByType
        }
    }

    public func totalAcneCount(for page: DetailPageKind) -> Int {
        guard let record = record else { return 0 }
        if let region = page.region {
            return record.detections.filter { $0.facialRegion == region }.count
        } else {
            return record.totalAcneCount
        }
    }
}

// MARK: - UIImage Normalized Cropping Helper

extension UIImage {
    /// Crops this image using normalized bounding coordinates (0.0 ... 1.0)
    public func cropped(to normalizedRect: CGRect) -> UIImage? {
        let currentSize = self.size
        guard currentSize.width > 0, currentSize.height > 0 else { return nil }

        let pixelRect = CGRect(
            x: max(0, normalizedRect.origin.x * currentSize.width),
            y: max(0, normalizedRect.origin.y * currentSize.height),
            width: min(currentSize.width, normalizedRect.size.width * currentSize.width),
            height: min(currentSize.height, normalizedRect.size.height * currentSize.height)
        )

        guard pixelRect.width > 0, pixelRect.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: pixelRect.size, format: format)
        return renderer.image { _ in
            self.draw(at: CGPoint(x: -pixelRect.origin.x, y: -pixelRect.origin.y))
        }
    }
}
