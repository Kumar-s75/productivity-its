//
//  Project.swift
//  Pulse
//
//  Core project model with health tracking
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String
    var projectDescription: String
    var createdAt: Date
    var lastTouchedAt: Date
    var colorHex: String
    var iconName: String
    
    // Health & Status
    var status: ProjectStatus
    var currentStreak: Int
    var longestStreak: Int
    var totalActiveDays: Int
    
    // Integrations (optional URLs/identifiers)
    var githubRepoURL: String?
    var testFlightAppID: String?
    var vercelProjectID: String?
    var figmaFileURL: String?
    var linearTeamID: String?
    var notionPageID: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PulseEntry.project)
    var pulseEntries: [PulseEntry]?
    
    @Relationship(deleteRule: .cascade, inverse: \ContextSnapshot.project)
    var contextSnapshots: [ContextSnapshot]?
    
    @Relationship(deleteRule: .cascade, inverse: \Milestone.project)
    var milestones: [Milestone]?
    
    // Archive data (populated when archived)
    var archivedAt: Date?
    var archiveReason: ArchiveReason?
    var postMortem: String?
    var lessonsLearned: String?
    
    // MARK: - Computed Properties
    
    var daysSinceLastTouch: Int {
        Calendar.current.dateComponents([.day], from: lastTouchedAt, to: Date()).day ?? 0
    }
    
    var healthLevel: HealthLevel {
        switch daysSinceLastTouch {
        case 0...2: return .healthy
        case 3...6: return .needsAttention
        case 7...13: return .critical
        case 14...29: return .dying
        default: return .dead
        }
    }
    
    var isArchived: Bool {
        archivedAt != nil
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    var latestContextSnapshot: ContextSnapshot? {
        contextSnapshots?
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    var pulseIntensity: Double {
        switch healthLevel {
        case .healthy: return 1.0
        case .needsAttention: return 0.7
        case .critical: return 0.4
        case .dying: return 0.2
        case .dead: return 0.05
        }
    }
    
    var pulseSpeed: Double {
        switch healthLevel {
        case .healthy: return 1.0
        case .needsAttention: return 1.5
        case .critical: return 2.5
        case .dying: return 4.0
        case .dead: return 8.0
        }
    }
    
    var totalTouches: Int {
        pulseEntries?.count ?? 0
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        description: String = "",
        colorHex: String = "#3B82F6",
        iconName: String = "folder.fill"
    ) {
        self.id = UUID()
        self.name = name
        self.projectDescription = description
        self.createdAt = Date()
        self.lastTouchedAt = Date()
        self.colorHex = colorHex
        self.iconName = iconName
        self.status = .active
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalActiveDays = 0
        self.pulseEntries = []
        self.contextSnapshots = []
        self.milestones = []
    }
    
    // MARK: - Methods
    
    func touch() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastTouchDay = calendar.startOfDay(for: lastTouchedAt)
        
        // Update streak
        if lastTouchDay == calendar.date(byAdding: .day, value: -1, to: today) {
            // Consecutive day - increment streak
            currentStreak += 1
        } else if lastTouchDay != today {
            // Streak broken
            currentStreak = 1
        }
        // If same day, don't change streak
        
        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Update total active days
        if lastTouchDay != today {
            totalActiveDays += 1
        }
        
        lastTouchedAt = Date()
    }
    
    func archive(reason: ArchiveReason, postMortem: String? = nil, lessons: String? = nil) {
        archivedAt = Date()
        archiveReason = reason
        self.postMortem = postMortem
        lessonsLearned = lessons
        status = .archived
    }
    
    func revive() {
        archivedAt = nil
        archiveReason = nil
        postMortem = nil
        lessonsLearned = nil
        status = .active
        currentStreak = 0
        touch()
    }
}

// MARK: - Supporting Types

enum ProjectStatus: String, Codable, CaseIterable {
    case active = "Active"
    case hibernating = "Hibernating"
    case archived = "Archived"
    
    var icon: String {
        switch self {
        case .active: return "bolt.fill"
        case .hibernating: return "moon.zzz.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

enum HealthLevel: String, CaseIterable {
    case healthy = "Healthy"
    case needsAttention = "Needs Attention"
    case critical = "Critical"
    case dying = "Dying"
    case dead = "Dead"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .critical: return .orange
        case .dying: return .red
        case .dead: return .gray
        }
    }
    
    var glowColor: Color {
        switch self {
        case .healthy: return .green.opacity(0.6)
        case .needsAttention: return .yellow.opacity(0.5)
        case .critical: return .orange.opacity(0.4)
        case .dying: return .red.opacity(0.3)
        case .dead: return .gray.opacity(0.1)
        }
    }
    
    var description: String {
        switch self {
        case .healthy: return "Strong pulse • Last touched recently"
        case .needsAttention: return "Slowing down • Needs some love"
        case .critical: return "Fading • Time to check in"
        case .dying: return "Almost gone • Intervene now"
        case .dead: return "Flatlined • Consider archiving"
        }
    }
}

enum ArchiveReason: String, Codable, CaseIterable {
    case completed = "Completed"
    case shipped = "Shipped"
    case killed = "Killed"
    case hibernating = "Hibernating"
    case merged = "Merged into another project"
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .shipped: return "shippingbox.fill"
        case .killed: return "xmark.circle.fill"
        case .hibernating: return "moon.zzz.fill"
        case .merged: return "arrow.triangle.merge"
        }
    }
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .shipped: return .mint
        case .killed: return .red
        case .hibernating: return .blue
        case .merged: return .purple
        }
    }
}
