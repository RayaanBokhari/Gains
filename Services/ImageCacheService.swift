//
//  ImageCacheService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation
import UIKit
import SwiftUI

/// Service for caching images locally to avoid re-downloading
final class ImageCacheService {
    static let shared = ImageCacheService()
    private init() {
        setupCache()
    }
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MealImages", isDirectory: true)
    }
    
    /// Setup cache with memory limits
    private func setupCache() {
        cache.countLimit = 100 // Max 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// Get cached image from memory or disk
    func getImage(for urlString: String) -> UIImage? {
        // Check memory cache first
        if let image = cache.object(forKey: urlString as NSString) {
            return image
        }
        
        // Check disk cache
        if let image = loadFromDisk(urlString: urlString) {
            // Store in memory cache for faster access
            cache.setObject(image, forKey: urlString as NSString)
            return image
        }
        
        return nil
    }
    
    /// Cache image to both memory and disk
    func cacheImage(_ image: UIImage, for urlString: String) {
        // Store in memory cache
        cache.setObject(image, forKey: urlString as NSString)
        
        // Store on disk asynchronously
        Task {
            await saveToDisk(image: image, urlString: urlString)
        }
    }
    
    /// Load image from disk cache
    private func loadFromDisk(urlString: String) -> UIImage? {
        guard let fileName = fileName(for: urlString),
              let imageData = try? Data(contentsOf: cacheDirectory.appendingPathComponent(fileName)),
              let image = UIImage(data: imageData) else {
            return nil
        }
        return image
    }
    
    /// Save image to disk cache
    private func saveToDisk(image: UIImage, urlString: String) async {
        guard let fileName = fileName(for: urlString),
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try? imageData.write(to: fileURL)
    }
    
    /// Generate filename from URL string (using hash for uniqueness)
    private func fileName(for urlString: String) -> String? {
        // Use MD5 hash of URL as filename
        guard let data = urlString.data(using: .utf8) else { return nil }
        let hash = data.hashValue
        return "\(abs(hash)).jpg"
    }
    
    /// Clear all cached images
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        setupCache()
    }
    
    /// Get cache size on disk
    func getCacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
}

/// SwiftUI view that loads and caches images
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder() // Show placeholder on error
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else {
            isLoading = false
            return
        }
        
        let urlString = url.absoluteString
        
        // Check cache first
        if let cachedImage = ImageCacheService.shared.getImage(for: urlString) {
            await MainActor.run {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }
        
        // Download if not cached
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let downloadedImage = UIImage(data: data) {
                // Cache the image
                ImageCacheService.shared.cacheImage(downloadedImage, for: urlString)
                
                await MainActor.run {
                    self.image = downloadedImage
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to load image: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

/// Convenience initializer for common use case
extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: {
                AnyView(
                    Rectangle()
                        .fill(Color.gainsCardBackground)
                        .overlay(ProgressView().tint(.gainsPrimary))
                )
            }
        )
    }
}

