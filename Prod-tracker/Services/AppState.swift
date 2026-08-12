//
//  AppState.swift
//  Pulse
//
//  Global application state
//

import Foundation
import SwiftUI
import Combine

// MARK: - Tab Selection

enum AppTab: String, CaseIterable {
    case pulse = "Pulse"
    case focus = "Focus"
    case map = "Map"
    case archive = "Archive"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .pulse: return "heart.fill"
        case .focus: return "target"
        case .map: return "chart.bar.fill"
        case .archive: return "archivebox.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

final class AppState: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppState()
    
    // MARK: - Published Properties
    
    @Published var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: Keys.onboardingComplete)
        }
    }
    
    @Published var selectedTab: AppTab = .pulse
    @Published var selectedProjectID: UUID?
    @Published var showingProjectDetail: Bool = false
    @Published var showingQuickCapture: Bool = false
    @Published var showingIntervention: Bool = false
    @Published var interventionProjectID: UUID?
    @Published var showingTodos: Bool = false
    @Published var showingAchievements: Bool = false
    @Published var showingSearch: Bool = false
    @Published var searchQuery: String = ""
    
    // New feature sheets
    @Published var showingMoodCheckIn: Bool = false
    @Published var showingHabitStack: Bool = false
    @Published var showingInbox: Bool = false
    @Published var showingVoicePulse: Bool = false
    @Published var showingStats: Bool = false
    @Published var showingFocusTimer: Bool = false
    @Published var showingYearInReview: Bool = false
    @Published var showingProjectCompare: Bool = false
    @Published var appTheme: AppTheme {
        didSet {
            CurrentTheme.shared.theme = appTheme
            UserDefaults.standard.set(appTheme.id, forKey: Keys.appTheme)
        }
    }

    @Published var showingGitHub: Bool = false
    @Published var showingVercel: Bool = false
    @Published var showingTestFlight: Bool = false
    @Published var showingGoDaddy: Bool = false

    // GitHub
    @Published var githubToken: String {
        didSet { UserDefaults.standard.set(githubToken, forKey: Keys.githubToken) }
    }
    @Published var githubUsername: String {
        didSet { UserDefaults.standard.set(githubUsername, forKey: Keys.githubUsername) }
    }

    // Vercel
    @Published var vercelToken: String {
        didSet { UserDefaults.standard.set(vercelToken, forKey: Keys.vercelToken) }
    }

    // App Store Connect (TestFlight)
    @Published var ascIssuerID: String {
        didSet { UserDefaults.standard.set(ascIssuerID, forKey: Keys.ascIssuerID) }
    }
    @Published var ascKeyID: String {
        didSet { UserDefaults.standard.set(ascKeyID, forKey: Keys.ascKeyID) }
    }
    @Published var ascPrivateKey: String {
        didSet { UserDefaults.standard.set(ascPrivateKey, forKey: Keys.ascPrivateKey) }
    }

    // GoDaddy
    @Published var godaddyAPIKey: String {
        didSet { UserDefaults.standard.set(godaddyAPIKey, forKey: Keys.godaddyAPIKey) }
    }
    @Published var godaddyAPISecret: String {
        didSet { UserDefaults.standard.set(godaddyAPISecret, forKey: Keys.godaddyAPISecret) }
    }
    
    // Settings
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled)
        }
    }
    
    @Published var dailyFocusReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyFocusReminderTime, forKey: Keys.dailyFocusTime)
        }
    }
    
    @Published var morningReminderTime: Date {
        didSet {
            UserDefaults.standard.set(morningReminderTime, forKey: Keys.morningReminderTime)
        }
    }
    
    @Published var eveningReminderTime: Date {
        didSet {
            UserDefaults.standard.set(eveningReminderTime, forKey: Keys.eveningReminderTime)
        }
    }
    
    @Published var weeklyReviewDay: Int {
        didSet {
            UserDefaults.standard.set(weeklyReviewDay, forKey: Keys.weeklyReviewDay)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }
    
    @Published var morningReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(morningReminderEnabled, forKey: Keys.morningReminderEnabled)
        }
    }
    
    @Published var eveningReflectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(eveningReflectionEnabled, forKey: Keys.eveningReflectionEnabled)
        }
    }
    
    @Published var selectedAppIcon: String {
        didSet {
            UserDefaults.standard.set(selectedAppIcon, forKey: Keys.selectedAppIcon)
        }
    }
    
    // MARK: - Private Keys
    
    private enum Keys {
        static let onboardingComplete = "pulse.onboardingComplete"
        static let hapticsEnabled = "pulse.hapticsEnabled"
        static let dailyFocusTime = "pulse.dailyFocusTime"
        static let morningReminderTime = "pulse.morningReminderTime"
        static let eveningReminderTime = "pulse.eveningReminderTime"
        static let weeklyReviewDay = "pulse.weeklyReviewDay"
        static let notificationsEnabled = "pulse.notificationsEnabled"
        static let morningReminderEnabled = "pulse.morningReminderEnabled"
        static let eveningReflectionEnabled = "pulse.eveningReflectionEnabled"
        static let selectedAppIcon = "pulse.selectedAppIcon"
        static let appTheme = "pulse.appTheme"
        static let githubToken = "pulse.githubToken"
        static let githubUsername = "pulse.githubUsername"
        static let vercelToken = "pulse.vercelToken"
        static let ascIssuerID = "pulse.ascIssuerID"
        static let ascKeyID = "pulse.ascKeyID"
        static let ascPrivateKey = "pulse.ascPrivateKey"
        static let godaddyAPIKey = "pulse.godaddyAPIKey"
        static let godaddyAPISecret = "pulse.godaddyAPISecret"
    }
    
    // MARK: - Initialization
    
    private init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Keys.onboardingComplete)
        self.hapticsEnabled = UserDefaults.standard.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        self.notificationsEnabled = UserDefaults.standard.object(forKey: Keys.notificationsEnabled) as? Bool ?? false
        self.morningReminderEnabled = UserDefaults.standard.object(forKey: Keys.morningReminderEnabled) as? Bool ?? false
        self.eveningReflectionEnabled = UserDefaults.standard.object(forKey: Keys.eveningReflectionEnabled) as? Bool ?? false
        self.selectedAppIcon = UserDefaults.standard.string(forKey: Keys.selectedAppIcon) ?? "AppIcon"
        
        // Default to 9 AM for daily focus
        let defaultMorningTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.dailyFocusReminderTime = UserDefaults.standard.object(forKey: Keys.dailyFocusTime) as? Date ?? defaultMorningTime
        self.morningReminderTime = UserDefaults.standard.object(forKey: Keys.morningReminderTime) as? Date ?? defaultMorningTime
        
        // Default to 8 PM for evening reflection
        let defaultEveningTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        self.eveningReminderTime = UserDefaults.standard.object(forKey: Keys.eveningReminderTime) as? Date ?? defaultEveningTime
        
        // Default to Sunday (1) for weekly review
        self.weeklyReviewDay = UserDefaults.standard.object(forKey: Keys.weeklyReviewDay) as? Int ?? 1

        // Theme
        let themeID = UserDefaults.standard.string(forKey: Keys.appTheme) ?? "midnight"
        self.appTheme = AppTheme.all.first { $0.id == themeID } ?? .midnight

        // GitHub
        self.githubToken    = UserDefaults.standard.string(forKey: Keys.githubToken)    ?? ""
        self.githubUsername = UserDefaults.standard.string(forKey: Keys.githubUsername) ?? ""

        // Vercel
        self.vercelToken = UserDefaults.standard.string(forKey: Keys.vercelToken) ?? ""

        // App Store Connect
        self.ascIssuerID   = UserDefaults.standard.string(forKey: Keys.ascIssuerID)   ?? ""
        self.ascKeyID      = UserDefaults.standard.string(forKey: Keys.ascKeyID)      ?? ""
        self.ascPrivateKey = UserDefaults.standard.string(forKey: Keys.ascPrivateKey) ?? ""

        // GoDaddy
        self.godaddyAPIKey    = UserDefaults.standard.string(forKey: Keys.godaddyAPIKey)    ?? ""
        self.godaddyAPISecret = UserDefaults.standard.string(forKey: Keys.godaddyAPISecret) ?? ""
    }
    
    // MARK: - Methods
    
    func selectProject(_ project: Project) {
        selectedProjectID = project.id
        showingProjectDetail = true
    }
    
    func triggerIntervention(for project: Project) {
        interventionProjectID = project.id
        showingIntervention = true
    }
    
    func dismissIntervention() {
        showingIntervention = false
        interventionProjectID = nil
    }
    
    func openQuickCapture() {
        showingQuickCapture = true
    }
    
    func openTodos() {
        showingTodos = true
    }
    
    func openAchievements() {
        showingAchievements = true
    }
    
    func openSearch() {
        showingSearch = true
        searchQuery = ""
    }
    
    func navigateToProject(_ projectID: UUID) {
        selectedProjectID = projectID
        selectedTab = .pulse
        showingProjectDetail = true
    }
}
