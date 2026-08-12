//
//  MoodEntry.swift
//  Pulse
//
//  Mood tracking data model
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Mood Entry Model

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var moodRaw: String
    var energyLevel: Int
    var note: String?
    var projectIDs: [UUID]
    
    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
    
    init(
        mood: Mood,
        energyLevel: Int = 3,
        note: String? = nil,
        projectIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.date = Date()
        self.moodRaw = mood.rawValue
        self.energyLevel = energyLevel
        self.note = note
        self.projectIDs = projectIDs
    }
}

// MARK: - Mood Enum

enum Mood: String, CaseIterable {
    case great
    case good
    case neutral
    case stressed
    case down
    
    var emoji: String {
        switch self {
        case .great: return "🤩"
        case .good: return "😊"
        case .neutral: return "😐"
        case .stressed: return "😰"
        case .down: return "😔"
        }
    }
    
    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .neutral: return "Okay"
        case .stressed: return "Stressed"
        case .down: return "Down"
        }
    }
    
    var color: Color {
        switch self {
        case .great: return .green
        case .good: return .cyan
        case .neutral: return .gray
        case .stressed: return .orange
        case .down: return .purple
        }
    }
    
    var numericValue: Int {
        switch self {
        case .great: return 5
        case .good: return 4
        case .neutral: return 3
        case .stressed: return 2
        case .down: return 1
        }
    }
    
    var description: String {
        switch self {
        case .great: return "Feeling amazing and energized"
        case .good: return "Feeling positive and content"
        case .neutral: return "Neither good nor bad"
        case .stressed: return "Feeling overwhelmed or anxious"
        case .down: return "Feeling low or unmotivated"
        }
    }
}
