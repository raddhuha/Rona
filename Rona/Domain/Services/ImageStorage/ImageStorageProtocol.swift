//
//  ImageStorageProtocol.swift
//  Rona
//
//  Created for Rona Acne Tracking App.
//

import UIKit

/// Protocol for saving and retrieving scan images on local storage.
public protocol ImageStorageProtocol: Sendable {
    /// Saves a UIImage locally and returns its relative or absolute path.
    func saveImage(_ image: UIImage, named filename: String) throws -> String

    /// Loads a UIImage from the specified path.
    func loadImage(fromPath path: String) -> UIImage?

    /// Deletes a file at the specified path if it exists.
    func deleteImage(atPath path: String)
}
