//
//  ImageUtilities.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import UIKit

extension UIImage {
    /// Converts UIImage to base64 string with compression
    /// - Parameter compressionQuality: JPEG compression quality (0.0 - 1.0). Default is 0.7
    /// - Returns: Base64 encoded string with data URI prefix, or nil if conversion fails
    func toBase64(compressionQuality: CGFloat = 0.7) -> String? {
        // Resize image if it's too large (max 2048px on longest side for API efficiency)
        let resizedImage = self.resized(maxDimension: 2048)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        let base64String = imageData.base64EncodedString()
        return "data:image/jpeg;base64,\(base64String)"
    }
    
    /// Resizes image to fit within a maximum dimension while maintaining aspect ratio
    private func resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        
        // If already smaller than max, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

