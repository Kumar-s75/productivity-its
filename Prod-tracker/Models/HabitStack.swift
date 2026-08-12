//
//  HabitStack.swift
//  Pulse
//
//  Habit stacking model - chain habits together
//

import Foundation
import SwiftData

@Model
final class HabitStack {
    var id: UUID
    var title: String
    var icon: String
    var estimatedMinutes: Int?
    var triggerText: String?
    var linkedProjectID: UUID?
    var sortOrder: Int
    var createdAt: Date
    var lastCompletedAt: Date?
    var completionCount: Int
    var completionHistory: [Date]
    
    // Computed streak
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // If not completed today, start from yesterday
        if let last = lastCompletedAt, !calendar.isDateInToday(last) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        for date in completionHistory.sorted(by: >) {
            let completionDay = calendar.startOfDay(for: date)
            if completionDay == checkDate {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if completionDay < checkDate {
                break
            }
        }
        
        return streak
    }
    
    init(
        title: String,
        icon: String = "circle.fill",
        estimatedMinutes: Int? = nil,
        triggerText: String? = nil,
        linkedProjectID: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.icon = icon
        self.estimatedMinutes = estimatedMinutes
        self.triggerText = triggerText
        self.linkedProjectID = linkedProjectID
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.completionCount = 0
        self.completionHistory = []
    }
    
    func complete() {
        let now = Date()
        lastCompletedAt = now
        completionCount += 1
        
        // Only add to history if not already completed today
        let calendar = Calendar.current
        if !completionHistory.contains(where: { calendar.isDate($0, inSameDayAs: now) }) {
            completionHistory.append(now)
        }
    }
}
