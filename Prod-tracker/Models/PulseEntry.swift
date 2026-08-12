//
//  PulseEntry.swift
//  Pulse
//
//  Tracks daily activity/pulse for a project
//

import Foundation
import SwiftData

@Model
final class PulseEntry {
    
    // MARK: - Properties
    
    var id: UUID
    var date: Date
    var intensityLevel: Int // 1-5 scale of how much work was done
    var notes: String?
    var durationMinutes: Int?
    
    // Relationship
    var project: Project?
    
    // MARK: - Computed Properties
    
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(
        date: Date = Date(),
        intensityLevel: Int = 3,
        notes: String? = nil,
        durationMinutes: Int? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.intensityLevel = min(max(intensityLevel, 1), 5)
        self.notes = notes
        self.durationMinutes = durationMinutes
    }
}

// MARK: - Extensions

extension PulseEntry {
    
    var intensityDescription: String {
        switch intensityLevel {
        case 1: return "Light touch"
        case 2: return "Minor work"
        case 3: return "Solid session"
        case 4: return "Deep work"
        case 5: return "Major push"
        default: return "Unknown"
        }
    }
    
    var intensityEmoji: String {
        switch intensityLevel {
        case 1: return "💨"
        case 2: return "⚡"
        case 3: return "🔥"
        case 4: return "💪"
        case 5: return "🚀"
        default: return "❓"
        }
    }
}
