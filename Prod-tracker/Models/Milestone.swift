//
//  Milestone.swift
//  Pulse
//
//  Tracks project milestones and achievements
//

import Foundation
import SwiftData

@Model
final class Milestone {
    
    // MARK: - Properties
    
    var id: UUID
    var title: String
    var milestoneDescription: String?
    var createdAt: Date
    var completedAt: Date?
    var isCompleted: Bool
    var priority: MilestonePriority
    
    // Relationship
    var project: Project?
    
    // MARK: - Computed Properties
    
    var isPending: Bool {
        !isCompleted
    }
    
    var daysToComplete: Int? {
        guard let completedAt = completedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: createdAt, to: completedAt).day
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        description: String? = nil,
        priority: MilestonePriority = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.milestoneDescription = description
        self.createdAt = Date()
        self.isCompleted = false
        self.priority = priority
    }
    
    // MARK: - Methods
    
    func complete() {
        isCompleted = true
        completedAt = Date()
    }
    
    func reopen() {
        isCompleted = false
        completedAt = nil
    }
}

// MARK: - Milestone Priority

enum MilestonePriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .critical: return "exclamationmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#6B7280"
        case .medium: return "#3B82F6"
        case .high: return "#F59E0B"
        case .critical: return "#EF4444"
        }
    }
}
