//
//  StorageService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation
import FirebaseStorage
import UIKit

final class StorageService {
    static let shared = StorageService()
    private init() {}

    private let storage = Storage.storage()

    /// Upload a meal image for the current user.
    /// Returns a download URL string.
    func uploadMealImage(
        userId: String,
        image: UIImage,
        for date: Date = Date()
    ) async throws -> String {
        // Convert UIImage -> JPEG data
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(
                domain: "StorageService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"]
            )
        }

        // e.g. users/{uid}/meals/2025-11-21/meal_1732212345.jpg
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateId = dateFormatter.string(from: date)

        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "meal_\(timestamp).jpg"

        let path = "users/\(userId)/meals/\(dateId)/\(fileName)"
        let ref = storage.reference(withPath: path)

        // Upload using continuation (works with all Firebase Storage SDK versions)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            _ = ref.putData(data, metadata: nil) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        // Get download URL using continuation
        let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "StorageService",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]
                    ))
                }
            }
        }
        
        return url.absoluteString
    }
}

