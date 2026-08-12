//
//  QuickCapture.swift
//  Pulse
//
//  Quick capture model for thoughts, ideas, tasks, notes
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Quick Capture Model

@Model
final class QuickCapture {
    var id: UUID
    var content: String
    var typeRaw: String
    var linkedProjectID: UUID?
    var createdAt: Date
    var processedAt: Date?
    
    var type: CaptureType {
        get { CaptureType(rawValue: typeRaw) ?? .thought }
        set { typeRaw = newValue.rawValue }
    }
    
    var isProcessed: Bool {
        processedAt != nil
    }
    
    init(
        content: String,
        type: CaptureType,
        linkedProjectID: UUID? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.typeRaw = type.rawValue
        self.linkedProjectID = linkedProjectID
        self.createdAt = Date()
    }
    
    func markProcessed() {
        processedAt = Date()
    }
}

// MARK: - Capture Type

enum CaptureType: String, CaseIterable {
    case thought
    case idea
    case task
    case note
    
    var label: String {
        switch self {
        case .thought: return "Thought"
        case .idea: return "Idea"
        case .task: return "Task"
        case .note: return "Note"
        }
    }
    
    var icon: String {
        switch self {
        case .thought: return "bubble.left.fill"
        case .idea: return "lightbulb.fill"
        case .task: return "checkmark.circle.fill"
        case .note: return "note.text"
        }
    }
    
    var color: Color {
        switch self {
        case .thought: return .purple
        case .idea: return .yellow
        case .task: return .green
        case .note: return .blue
        }
    }
    
    var placeholder: String {
        switch self {
        case .thought: return "What's on your mind?"
        case .idea: return "Capture your brilliant idea..."
        case .task: return "What needs to get done?"
        case .note: return "Write a note..."
        }
    }
}
