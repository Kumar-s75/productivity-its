//
//  Achievement.swift
//  Pulse
//
//  Achievements and badges for gamification
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Achievement {
    
    // MARK: - Properties
    
    var id: UUID
    var type: AchievementType
    var unlockedAt: Date?
    var progress: Int
    
    // MARK: - Computed Properties
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    var progressPercentage: Double {
        Double(progress) / Double(type.requirement)
    }
    
    // MARK: - Initialization
    
    init(type: AchievementType) {
        self.id = UUID()
        self.type = type
        self.unlockedAt = nil
        self.progress = 0
    }
    
    // MARK: - Methods
    
    func unlock() {
        if unlockedAt == nil {
            unlockedAt = Date()
        }
    }
    
    func updateProgress(_ newProgress: Int) {
        progress = newProgress
        if progress >= type.requirement && unlockedAt == nil {
            unlock()
        }
    }
}

// MARK: - Achievement Type

enum AchievementType: String, Codable, CaseIterable {
    // Streak achievements
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak14 = "streak_14"
    case streak30 = "streak_30"
    case streak100 = "streak_100"
    
    // Project achievements
    case firstProject = "first_project"
    case fiveProjects = "five_projects"
    case tenProjects = "ten_projects"
    
    // Shipping achievements
    case firstShip = "first_ship"
    case fiveShips = "five_ships"
    case tenShips = "ten_ships"
    
    // Todo achievements
    case firstTodo = "first_todo"
    case hundredTodos = "hundred_todos"
    case todoStreak7 = "todo_streak_7"
    
    // Special achievements
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"
    case weekendWarrior = "weekend_warrior"
    case reviver = "reviver"
    case mercyKill = "mercy_kill"
    
    var name: String {
        switch self {
        case .streak3: return "Getting Started"
        case .streak7: return "On a Roll"
        case .streak14: return "Two Week Streak"
        case .streak30: return "Monthly Master"
        case .streak100: return "Legendary"
        case .firstProject: return "First Breath"
        case .fiveProjects: return "Project Collector"
        case .tenProjects: return "Portfolio Builder"
        case .firstShip: return "First Ship"
        case .fiveShips: return "Serial Shipper"
        case .tenShips: return "Shipping Machine"
        case .firstTodo: return "Task Taker"
        case .hundredTodos: return "Productivity Pro"
        case .todoStreak7: return "Todo Champion"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .weekendWarrior: return "Weekend Warrior"
        case .reviver: return "Project Reviver"
        case .mercyKill: return "Mercy Kill"
        }
    }
    
    var description: String {
        switch self {
        case .streak3: return "Maintain a 3-day streak"
        case .streak7: return "Maintain a 7-day streak"
        case .streak14: return "Maintain a 14-day streak"
        case .streak30: return "Maintain a 30-day streak"
        case .streak100: return "Maintain a 100-day streak"
        case .firstProject: return "Create your first project"
        case .fiveProjects: return "Create 5 projects"
        case .tenProjects: return "Create 10 projects"
        case .firstShip: return "Complete your first project"
        case .fiveShips: return "Complete 5 projects"
        case .tenShips: return "Complete 10 projects"
        case .firstTodo: return "Complete your first todo"
        case .hundredTodos: return "Complete 100 todos"
        case .todoStreak7: return "Complete todos for 7 days straight"
        case .nightOwl: return "Work on a project after midnight"
        case .earlyBird: return "Work on a project before 6 AM"
        case .weekendWarrior: return "Work every weekend for a month"
        case .reviver: return "Revive a dying project"
        case .mercyKill: return "Kill your first project"
        }
    }
    
    var icon: String {
        switch self {
        case .streak3, .streak7, .streak14, .streak30, .streak100:
            return "flame.fill"
        case .firstProject, .fiveProjects, .tenProjects:
            return "folder.fill"
        case .firstShip, .fiveShips, .tenShips:
            return "paperplane.fill"
        case .firstTodo, .hundredTodos, .todoStreak7:
            return "checkmark.circle.fill"
        case .nightOwl:
            return "moon.fill"
        case .earlyBird:
            return "sunrise.fill"
        case .weekendWarrior:
            return "calendar.badge.clock"
        case .reviver:
            return "heart.circle.fill"
        case .mercyKill:
            return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .streak3: return .orange
        case .streak7: return .orange
        case .streak14: return .red
        case .streak30: return .purple
        case .streak100: return .yellow
        case .firstProject, .fiveProjects, .tenProjects: return .blue
        case .firstShip, .fiveShips, .tenShips: return .green
        case .firstTodo, .hundredTodos, .todoStreak7: return .cyan
        case .nightOwl: return .indigo
        case .earlyBird: return .yellow
        case .weekendWarrior: return .pink
        case .reviver: return .green
        case .mercyKill: return .red
        }
    }
    
    var requirement: Int {
        switch self {
        case .streak3: return 3
        case .streak7: return 7
        case .streak14: return 14
        case .streak30: return 30
        case .streak100: return 100
        case .firstProject, .firstShip, .firstTodo: return 1
        case .fiveProjects, .fiveShips: return 5
        case .tenProjects, .tenShips: return 10
        case .hundredTodos: return 100
        case .todoStreak7: return 7
        case .nightOwl, .earlyBird, .reviver, .mercyKill: return 1
        case .weekendWarrior: return 4
        }
    }
}
