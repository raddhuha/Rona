//
//  RecordDetailViewModel.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import SwiftUI
import Combine

/// ViewModel managing a single scan record's detailed breakdown and deletion.
@MainActor
public final class RecordDetailViewModel: ObservableObject {
    public let recordId: UUID

    @Published public var record: ScanRecord?
    @Published public var previousRecord: ScanRecord?
    @Published public var frontImage: UIImage?
    @Published public var leftImage: UIImage?
    @Published public var rightImage: UIImage?
    @Published public var selectedAngle: ScanViewAngle = .front
    @Published public var showBoundingBoxes: Bool = true
    @Published public var showDeleteConfirmation: Bool = false
    @Published public var isDeleted: Bool = false

    private let scanRepository: ScanRepositoryProtocol
    private let imageStorage: ImageStorageProtocol

    public init(
        recordId: UUID,
        scanRepository: ScanRepositoryProtocol,
        imageStorage: ImageStorageProtocol
    ) {
        self.recordId = recordId
        self.scanRepository = scanRepository
        self.imageStorage = imageStorage
    }

    public func loadRecord() async {
        do {
            if let found = try await scanRepository.fetchById(recordId) {
                record = found
                frontImage = imageStorage.loadImage(fromPath: found.frontImagePath)
                leftImage = imageStorage.loadImage(fromPath: found.leftImagePath)
                rightImage = imageStorage.loadImage(fromPath: found.rightImagePath)
                previousRecord = try await scanRepository.getPreviousRecord(before: found.date)
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

    public func currentImage(for angle: ScanViewAngle) -> UIImage? {
        switch angle {
        case .front: return frontImage
        case .left: return leftImage
        case .right: return rightImage
        }
    }

    public func currentDetections(for angle: ScanViewAngle) -> [AcneDetection] {
        guard let record = record else { return [] }
        return record.detections(for: angle).map { $0.toDomain() }
    }
}
