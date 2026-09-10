//
//  LocalFileImageStorage.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit

/// Production implementation of `ImageStorageProtocol` storing JPEG photos locally on disk.
///
/// Images are kept off the SwiftData database to prevent SQLite file bloat and memory pressure.
public final class LocalFileImageStorage: ImageStorageProtocol, @unchecked Sendable {
    private let fileManager = FileManager.default
    private let storageDirectory: URL

    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let scansDirectory = appSupport.appendingPathComponent("RonaScans", isDirectory: true)

        if !fileManager.fileExists(atPath: scansDirectory.path) {
            try? fileManager.createDirectory(at: scansDirectory, withIntermediateDirectories: true)
        }
        self.storageDirectory = scansDirectory
    }

    public func saveImage(_ image: UIImage, named filename: String) throws -> String {
        let fileURL = storageDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(
                domain: "LocalFileImageStorage",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to compress UIImage to JPEG."]
            )
        }

        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    public func loadImage(fromPath path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        // On iOS, container UUIDs change across installs, so resolve filename in current storageDirectory
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let localURL = storageDirectory.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: localURL.path) {
            return UIImage(contentsOfFile: localURL.path)
        }
        if fileManager.fileExists(atPath: path) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }

    public func deleteImage(atPath path: String) {
        guard !path.isEmpty else { return }
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let localURL = storageDirectory.appendingPathComponent(filename)

        try? fileManager.removeItem(at: localURL)
        if localURL.path != path {
            try? fileManager.removeItem(atPath: path)
        }
    }
}
