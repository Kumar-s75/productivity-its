//
//  Todo.swift
//  Pulse
//
//  Daily todo items, optionally linked to projects
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Todo {
    
    // MARK: - Properties
    
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var dueDate: Date?
    var completedAt: Date?
    var priority: TodoPriority
    var isCarriedOver: Bool
    var carriedOverCount: Int
    
    // Optional project link
    var linkedProjectID: UUID?
    
    // MARK: - Computed Properties
    
    var isCompleted: Bool {
        completedAt != nil
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }
    
    var dueDateDisplay: String {
        guard let dueDate = dueDate else { return "" }
        
        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(dueDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: dueDate)
        }
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        priority: TodoPriority = .medium,
        linkedProjectID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.dueDate = dueDate
        self.completedAt = nil
        self.priority = priority
        self.isCarriedOver = false
        self.carriedOverCount = 0
        self.linkedProjectID = linkedProjectID
    }
    
    // MARK: - Methods
    
    func complete() {
        completedAt = Date()
    }
    
    func uncomplete() {
        completedAt = nil
    }
    
    func carryOverToTomorrow() {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        dueDate = Calendar.current.startOfDay(for: tomorrow)
        isCarriedOver = true
        carriedOverCount += 1
    }
}

// MARK: - Todo Priority

enum TodoPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}
