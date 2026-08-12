//
//  ContextSnapshot.swift
//  Pulse
//
//  Captures where you left off on a project
//

import Foundation
import SwiftData

@Model
final class ContextSnapshot {
    
    // MARK: - Properties
    
    var id: UUID
    var createdAt: Date
    var content: String
    var snapshotType: SnapshotType
    
    // Optional voice note reference
    var audioFilePath: String?
    var transcription: String?
    
    // Relationship
    var project: Project?
    
    // MARK: - Computed Properties
    
    var isVoiceNote: Bool {
        audioFilePath != nil
    }
    
    var displayContent: String {
        if let transcription = transcription, !transcription.isEmpty {
            return transcription
        }
        return content
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Initialization
    
    init(
        content: String,
        type: SnapshotType = .manual,
        audioFilePath: String? = nil,
        transcription: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.content = content
        self.snapshotType = type
        self.audioFilePath = audioFilePath
        self.transcription = transcription
    }
}

// MARK: - Snapshot Type

enum SnapshotType: String, Codable, CaseIterable {
    case manual = "Manual"
    case voiceNote = "Voice Note"
    case autoSaved = "Auto-saved"
    case exitPrompt = "Exit Prompt"
    
    var icon: String {
        switch self {
        case .manual: return "pencil.circle.fill"
        case .voiceNote: return "mic.circle.fill"
        case .autoSaved: return "arrow.clockwise.circle.fill"
        case .exitPrompt: return "door.right.hand.open"
        }
    }
}
