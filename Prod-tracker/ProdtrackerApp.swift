//
//  PulseApp.swift
//  Pulse
//
//  Your projects are alive. This app lets you feel their heartbeat.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - NSUserActivity Extension

extension NSUserActivity {
    static let viewProjectActivityType = "com.pulse.viewProject"
}

@main
struct PulseApp: App {
    
    // MARK: - Properties
    
    let modelContainer: ModelContainer
    
    @StateObject private var hapticEngine = HapticEngine.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var soundManager = SoundManager.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Initialization
    
    init() {
        do {
            let schema = Schema([
                Project.self,
                PulseEntry.self,
                ContextSnapshot.self,
                Milestone.self,
                DailyFocus.self,
                Todo.self,
                Tag.self,
                Achievement.self,
                MoodEntry.self,
                HabitStack.self,
                QuickCapture.self,
                VoicePulse.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Configure appearance
        configureAppearance()
        
        // Load gamification progress
        GamificationManager.shared.loadProgress()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environmentObject(hapticEngine)
            .environmentObject(appState)
            .environmentObject(notificationManager)
            .environmentObject(soundManager)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onContinueUserActivity(NSUserActivity.viewProjectActivityType) { activity in
                handleSpotlightActivity(activity)
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.pulseBackground)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.pulseBackground.opacity(0.95))
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    // MARK: - Deep Links
    
    private func handleDeepLink(_ url: URL) {
        // Handle pulse://project/UUID
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "pulse" else { return }
        
        let state = AppState.shared
        switch components.host {
        case "project":
            if let projectID = components.path.dropFirst().description.isEmpty ? nil : UUID(uuidString: String(components.path.dropFirst())) {
                state.selectedProjectID = projectID
                state.selectedTab = .pulse
            }
        case "daily":
            state.selectedTab = .focus
        case "todos":
            state.showingTodos = true
        default:
            break
        }
    }
    
    // MARK: - Spotlight Activity
    
    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        guard let userInfo = activity.userInfo,
              let projectIDString = userInfo["projectID"] as? String,
              let projectID = UUID(uuidString: projectIDString) else { return }
        
        let state = AppState.shared
        state.selectedProjectID = projectID
        state.selectedTab = .pulse
    }
    
    // MARK: - Scene Phase
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            notificationManager.checkAuthorizationStatus()
        case .inactive:
            break
        case .background:
            // App going to background - good time to schedule notifications
            break
        @unknown default:
            break
        }
    }
}
