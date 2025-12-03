//
//  ChatStorageService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

actor ChatStorageService {
    static let shared = ChatStorageService()
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChatHistory")
    }
    
    private init() {
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Conversation Management
    
    func saveConversation(_ conversation: ChatConversation) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(conversation.id.uuidString).json")
        let data = try JSONEncoder().encode(conversation)
        try data.write(to: fileURL)
    }
    
    func loadConversation(id: UUID) throws -> ChatConversation? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ChatConversation.self, from: data)
    }
    
    func loadAllConversations() throws -> [ChatConversation] {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        return files.compactMap { url -> ChatConversation? in
            guard url.pathExtension == "json" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(ChatConversation.self, from: data)
        }.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func deleteConversation(id: UUID) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
    }
    
    func clearAllConversations() throws {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }
    }
}

