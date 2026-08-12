//
//  DailyFocus.swift
//  Pulse
//
//  Tracks which 3 projects get focus each day
//

import Foundation
import SwiftData

@Model
final class DailyFocus {
    
    // MARK: - Properties
    
    var id: UUID
    var date: Date
    var projectIDs: [UUID]
    var completedProjectIDs: [UUID]
    var reflectionNote: String?
    
    // MARK: - Computed Properties
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var completionPercentage: Double {
        guard !projectIDs.isEmpty else { return 0 }
        return Double(completedProjectIDs.count) / Double(projectIDs.count)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(projectIDs: [UUID] = []) {
        self.id = UUID()
        self.date = Date()
        self.projectIDs = projectIDs
        self.completedProjectIDs = []
    }
    
    // MARK: - Methods
    
    func markCompleted(projectID: UUID) {
        if !completedProjectIDs.contains(projectID) && projectIDs.contains(projectID) {
            completedProjectIDs.append(projectID)
        }
    }
    
    func markIncomplete(projectID: UUID) {
        completedProjectIDs.removeAll { $0 == projectID }
    }
    
    func isCompleted(projectID: UUID) -> Bool {
        completedProjectIDs.contains(projectID)
    }
}
