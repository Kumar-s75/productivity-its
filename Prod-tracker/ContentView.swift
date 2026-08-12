//
//  ContentView.swift
//  Pulse
//
//  Main navigation container
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationManager: NotificationManager
    
    // MARK: - State
    
    @State private var showingDailyFocus: Bool = false
    @State private var hasCompletedDailyFocus: Bool = false
    @State private var showConfetti: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            BackgroundView()
                .ignoresSafeArea()
            
            // Main content
            TabView(selection: $appState.selectedTab) {
                
                // Heartbeat Home
                PulseHomeView()
                    .tabItem {
                        Label(AppTab.pulse.rawValue, systemImage: AppTab.pulse.icon)
                    }
                    .tag(AppTab.pulse)
                
                // Daily Three
                DailyThreeView()
                    .tabItem {
                        Label(AppTab.focus.rawValue, systemImage: AppTab.focus.icon)
                    }
                    .tag(AppTab.focus)
                
                // Weekly Pulse Map
                PulseMapView()
                    .tabItem {
                        Label(AppTab.map.rawValue, systemImage: AppTab.map.icon)
                    }
                    .tag(AppTab.map)
                
                // Archive / Graveyard
                ArchiveView()
                    .tabItem {
                        Label(AppTab.archive.rawValue, systemImage: AppTab.archive.icon)
                    }
                    .tag(AppTab.archive)
                
                // Settings
                SettingsView()
                    .tabItem {
                        Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
                    }
                    .tag(AppTab.settings)
            }
            .tint(.white)
            .onAppear {
                configureTabBarAppearance()
                checkDailyFocus()
                setupNotifications()
            }
            
            // Daily Focus Overlay
            if showingDailyFocus && !hasCompletedDailyFocus {
                DailyFocusOverlay(
                    isPresented: $showingDailyFocus,
                    onComplete: {
                        hasCompletedDailyFocus = true
                        hapticEngine.playSuccess()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .confetti(isActive: $showConfetti, intensity: .medium)
        // Search sheet
        .sheet(isPresented: $appState.showingSearch) {
            SearchView()
        }
        // Todos sheet
        .sheet(isPresented: $appState.showingTodos) {
            TodoListView()
        }
        // Achievements sheet
        .sheet(isPresented: $appState.showingAchievements) {
            AchievementsView()
        }
        // Quick capture sheet
        .sheet(isPresented: $appState.showingQuickCapture) {
            QuickCaptureView()
        }
        // Intervention sheet
        .sheet(isPresented: $appState.showingIntervention) {
            if let projectID = appState.interventionProjectID {
                InterventionSheetWrapper(projectID: projectID)
            }
        }
        // Mood check-in sheet
        .sheet(isPresented: $appState.showingMoodCheckIn) {
            MoodCheckInView()
        }
        // Habit stack sheet
        .sheet(isPresented: $appState.showingHabitStack) {
            HabitStackView()
        }
        // Inbox sheet
        .sheet(isPresented: $appState.showingInbox) {
            InboxView()
        }
        // Voice pulse sheet
        .sheet(isPresented: $appState.showingVoicePulse) {
            VoicePulseView()
        }
        // Stats sheet
        .sheet(isPresented: $appState.showingStats) {
            StatsView()
        }
        // Focus timer sheet
        .sheet(isPresented: $appState.showingFocusTimer) {
            FocusTimerView()
        }
        // Year in review sheet
        .sheet(isPresented: $appState.showingYearInReview) {
            YearInReviewView()
        }
        // Project compare sheet
        .sheet(isPresented: $appState.showingProjectCompare) {
            ProjectCompareView()
        }
        // GitHub sheet
        .sheet(isPresented: $appState.showingGitHub) {
            GitHubView()
        }
        // Vercel sheet
        .sheet(isPresented: $appState.showingVercel) {
            VercelView()
        }
        // TestFlight sheet
        .sheet(isPresented: $appState.showingTestFlight) {
            TestFlightView()
        }
        // GoDaddy sheet
        .sheet(isPresented: $appState.showingGoDaddy) {
            GoDaddyView()
        }
    }
    
    // MARK: - Methods
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func checkDailyFocus() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DailyFocus>(
            predicate: #Predicate { focus in
                focus.date >= today
            }
        )
        
        do {
            let todaysFocus = try modelContext.fetch(descriptor)
            hasCompletedDailyFocus = !todaysFocus.isEmpty
            showingDailyFocus = todaysFocus.isEmpty
        } catch {
            showingDailyFocus = true
        }
    }
    
    private func setupNotifications() {
        Task {
            let granted = await notificationManager.requestAuthorization()
            if granted {
                notificationManager.registerNotificationCategories()
                
                // Cancel existing notifications first
                notificationManager.cancelAllNotifications()
                
                // Only schedule if user has enabled them
                if appState.notificationsEnabled {
                    if appState.morningReminderEnabled {
                        let hour = Calendar.current.component(.hour, from: appState.morningReminderTime)
                        let minute = Calendar.current.component(.minute, from: appState.morningReminderTime)
                        notificationManager.scheduleMorningReminder(hour: hour, minute: minute)
                    }
                    
                    if appState.eveningReflectionEnabled {
                        let hour = Calendar.current.component(.hour, from: appState.eveningReminderTime)
                        let minute = Calendar.current.component(.minute, from: appState.eveningReminderTime)
                        notificationManager.scheduleEveningReflection(hour: hour, minute: minute)
                    }
                }
            }
        }
    }
}

// MARK: - Intervention Sheet Wrapper

struct InterventionSheetWrapper: View {
    @Environment(\.modelContext) private var modelContext
    
    let projectID: UUID
    
    @Query private var projects: [Project]
    
    private var project: Project? {
        projects.first { $0.id == projectID }
    }
    
    var body: some View {
        if let project = project {
            InterventionSheet(project: project)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(HapticEngine.shared)
        .environmentObject(AppState.shared)
        .environmentObject(NotificationManager.shared)
        .modelContainer(for: [Project.self, PulseEntry.self, ContextSnapshot.self, Milestone.self, DailyFocus.self, Todo.self, Tag.self, Achievement.self, MoodEntry.self, HabitStack.self, QuickCapture.self, VoicePulse.self], inMemory: true)
}
