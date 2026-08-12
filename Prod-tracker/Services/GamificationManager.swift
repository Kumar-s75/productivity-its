//
//  GamificationManager.swift
//  Pulse
//
//  XP system, levels, badges, and gamification elements
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Gamification Manager

@MainActor
final class GamificationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = GamificationManager()
    
    // MARK: - Published
    
    @Published var currentXP: Int = 0
    @Published var currentLevel: Int = 1
    @Published var showLevelUp = false
    @Published var showXPGain = false
    @Published var lastXPGain: Int = 0
    @Published var unlockedBadges: Set<Badge> = []
    
    // MARK: - XP Rewards
    
    enum XPAction {
        case touchProject          // 10 XP
        case completeTodo          // 15 XP
        case completeMilestone     // 50 XP
        case maintainStreak(Int)   // 5 XP per day
        case shipProject           // 200 XP
        case completeHabit         // 10 XP
        case dailyLogin            // 5 XP
        case completeRitual        // 20 XP
        case focusSession(Int)     // 1 XP per minute
        case moodCheckIn           // 5 XP
        
        var xpValue: Int {
            switch self {
            case .touchProject: return 10
            case .completeTodo: return 15
            case .completeMilestone: return 50
            case .maintainStreak(let days): return 5 * days
            case .shipProject: return 200
            case .completeHabit: return 10
            case .dailyLogin: return 5
            case .completeRitual: return 20
            case .focusSession(let minutes): return minutes
            case .moodCheckIn: return 5
            }
        }
        
        var description: String {
            switch self {
            case .touchProject: return "Touched project"
            case .completeTodo: return "Completed task"
            case .completeMilestone: return "Milestone achieved"
            case .maintainStreak(let days): return "\(days) day streak"
            case .shipProject: return "Project shipped!"
            case .completeHabit: return "Habit completed"
            case .dailyLogin: return "Daily check-in"
            case .completeRitual: return "Ritual completed"
            case .focusSession(let minutes): return "\(minutes) min focus"
            case .moodCheckIn: return "Mood logged"
            }
        }
    }
    
    // MARK: - Level System
    
    static func xpForLevel(_ level: Int) -> Int {
        // Exponential growth: 100, 250, 500, 850, 1300, etc.
        return Int(100 * pow(1.5, Double(level - 1)))
    }
    
    static func totalXPForLevel(_ level: Int) -> Int {
        (1..<level).reduce(0) { $0 + xpForLevel($1) }
    }
    
    var xpForCurrentLevel: Int {
        Self.xpForLevel(currentLevel)
    }
    
    var xpProgressInCurrentLevel: Int {
        currentXP - Self.totalXPForLevel(currentLevel)
    }
    
    var levelProgress: Double {
        Double(xpProgressInCurrentLevel) / Double(xpForCurrentLevel)
    }
    
    var levelTitle: String {
        switch currentLevel {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...20: return "Journeyman"
        case 21...35: return "Expert"
        case 36...50: return "Master"
        case 51...75: return "Grandmaster"
        case 76...100: return "Legend"
        default: return "Mythic"
        }
    }
    
    // MARK: - Methods
    
    func awardXP(for action: XPAction) {
        let xp = action.xpValue
        lastXPGain = xp
        currentXP += xp
        
        // Check for level up
        while currentXP >= Self.totalXPForLevel(currentLevel + 1) {
            currentLevel += 1
            showLevelUp = true
        }
        
        showXPGain = true
        
        // Auto-hide XP notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showXPGain = false
        }
        
        // Save to UserDefaults
        saveProgress()
        
        // Check for badge unlocks
        checkBadgeUnlocks()
    }
    
    func loadProgress() {
        currentXP = UserDefaults.standard.integer(forKey: "pulse_current_xp")
        currentLevel = max(1, UserDefaults.standard.integer(forKey: "pulse_current_level"))
        
        if let badgeData = UserDefaults.standard.data(forKey: "pulse_unlocked_badges"),
           let badges = try? JSONDecoder().decode([Badge].self, from: badgeData) {
            unlockedBadges = Set(badges)
        }
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(currentXP, forKey: "pulse_current_xp")
        UserDefaults.standard.set(currentLevel, forKey: "pulse_current_level")
        
        if let badgeData = try? JSONEncoder().encode(Array(unlockedBadges)) {
            UserDefaults.standard.set(badgeData, forKey: "pulse_unlocked_badges")
        }
    }
    
    private func checkBadgeUnlocks() {
        // Level-based badges
        if currentLevel >= 5 && !unlockedBadges.contains(.apprentice) {
            unlockBadge(.apprentice)
        }
        if currentLevel >= 10 && !unlockedBadges.contains(.journeyman) {
            unlockBadge(.journeyman)
        }
        if currentLevel >= 25 && !unlockedBadges.contains(.expert) {
            unlockBadge(.expert)
        }
        if currentLevel >= 50 && !unlockedBadges.contains(.master) {
            unlockBadge(.master)
        }
    }
    
    func unlockBadge(_ badge: Badge) {
        guard !unlockedBadges.contains(badge) else { return }
        unlockedBadges.insert(badge)
        saveProgress()
    }
}

// MARK: - Badge

enum Badge: String, Codable, CaseIterable {
    // Level badges
    case apprentice
    case journeyman
    case expert
    case master
    
    // Achievement badges
    case firstPulse
    case weekStreak
    case monthStreak
    case hundredDayStreak
    case firstShip
    case fiveShips
    case tenShips
    case earlyBird
    case nightOwl
    case weekendWarrior
    case focusMaster
    case habitFormer
    case zenMaster
    case collector
    case perfectWeek
    
    var title: String {
        switch self {
        case .apprentice: return "Apprentice"
        case .journeyman: return "Journeyman"
        case .expert: return "Expert"
        case .master: return "Master"
        case .firstPulse: return "First Heartbeat"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Monthly Master"
        case .hundredDayStreak: return "Century Club"
        case .firstShip: return "First Ship"
        case .fiveShips: return "Serial Shipper"
        case .tenShips: return "Legendary Builder"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        case .focusMaster: return "Focus Master"
        case .habitFormer: return "Habit Former"
        case .zenMaster: return "Zen Master"
        case .collector: return "Collector"
        case .perfectWeek: return "Perfect Week"
        }
    }
    
    var description: String {
        switch self {
        case .apprentice: return "Reach level 5"
        case .journeyman: return "Reach level 10"
        case .expert: return "Reach level 25"
        case .master: return "Reach level 50"
        case .firstPulse: return "Log your first pulse"
        case .weekStreak: return "Maintain a 7-day streak"
        case .monthStreak: return "Maintain a 30-day streak"
        case .hundredDayStreak: return "Maintain a 100-day streak"
        case .firstShip: return "Ship your first project"
        case .fiveShips: return "Ship 5 projects"
        case .tenShips: return "Ship 10 projects"
        case .earlyBird: return "Log a pulse before 7 AM"
        case .nightOwl: return "Log a pulse after 11 PM"
        case .weekendWarrior: return "Work on projects every weekend for a month"
        case .focusMaster: return "Complete 10 focus sessions"
        case .habitFormer: return "Complete habit stack for 30 days"
        case .zenMaster: return "Complete 50 rituals"
        case .collector: return "Have 10+ active projects"
        case .perfectWeek: return "Touch all projects every day for a week"
        }
    }
    
    var icon: String {
        switch self {
        case .apprentice: return "graduationcap.fill"
        case .journeyman: return "figure.walk"
        case .expert: return "star.fill"
        case .master: return "crown.fill"
        case .firstPulse: return "heart.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "flame.circle.fill"
        case .hundredDayStreak: return "100.circle.fill"
        case .firstShip: return "paperplane.fill"
        case .fiveShips: return "airplane"
        case .tenShips: return "rocket.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .weekendWarrior: return "calendar.badge.clock"
        case .focusMaster: return "brain.head.profile"
        case .habitFormer: return "link.circle.fill"
        case .zenMaster: return "sparkles"
        case .collector: return "square.stack.3d.up.fill"
        case .perfectWeek: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .apprentice: return .green
        case .journeyman: return .blue
        case .expert: return .purple
        case .master: return .yellow
        case .firstPulse: return .red
        case .weekStreak, .monthStreak, .hundredDayStreak: return .orange
        case .firstShip, .fiveShips, .tenShips: return .cyan
        case .earlyBird: return .yellow
        case .nightOwl: return .indigo
        case .weekendWarrior: return .pink
        case .focusMaster: return .purple
        case .habitFormer: return .green
        case .zenMaster: return .mint
        case .collector: return .blue
        case .perfectWeek: return .green
        }
    }
    
    var rarity: BadgeRarity {
        switch self {
        case .firstPulse, .earlyBird, .nightOwl:
            return .common
        case .apprentice, .weekStreak, .firstShip, .weekendWarrior:
            return .uncommon
        case .journeyman, .monthStreak, .fiveShips, .focusMaster, .habitFormer, .collector:
            return .rare
        case .expert, .tenShips, .zenMaster, .perfectWeek:
            return .epic
        case .master, .hundredDayStreak:
            return .legendary
        }
    }
}

enum BadgeRarity: String {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - XP Notification View

struct XPNotificationView: View {
    let xp: Int
    let description: String
    
    @State private var appear = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(xp) XP")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .scaleEffect(appear ? 1 : 0.5)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appear = true
            }
        }
    }
}

// MARK: - Level Up View

struct LevelUpView: View {
    let level: Int
    let title: String
    let onDismiss: () -> Void
    
    @State private var animateRings = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // Animated rings
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(100 + i * 50), height: CGFloat(100 + i * 50))
                    .scaleEffect(animateRings ? 1.5 : 0.5)
                    .opacity(animateRings ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.2),
                        value: animateRings
                    )
            }
            
            VStack(spacing: 30) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .orange.opacity(0.5), radius: 30)
                    
                    VStack(spacing: 4) {
                        Text("LVL")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.5))
                        
                        Text("\(level)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                    }
                }
                .scaleEffect(showContent ? 1 : 0)
                
                // Title
                Text("LEVEL UP!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showContent ? 1 : 0)
                
                // New title
                Text("You are now a \(title)")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showContent ? 1 : 0)
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.top, 20)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            animateRings = true
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showContent = true
            }
        }
    }
}

// MARK: - Level Progress View

struct LevelProgressView: View {
    @ObservedObject var gamification = GamificationManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Level info
            HStack {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("\(gamification.currentLevel)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(gamification.levelTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(gamification.currentXP) XP total")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Next level
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next: Lvl \(gamification.currentLevel + 1)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("\(gamification.xpForCurrentLevel - gamification.xpProgressInCurrentLevel) XP")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * gamification.levelProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Badge Grid View

struct BadgeGridView: View {
    let unlockedBadges: Set<Badge>
    
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Badge.allCases, id: \.self) { badge in
                BadgeView(
                    badge: badge,
                    isUnlocked: unlockedBadges.contains(badge)
                )
            }
        }
    }
}

struct BadgeView: View {
    let badge: Badge
    let isUnlocked: Bool
    
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? badge.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isUnlocked ? badge.color : .white.opacity(0.2))
                }
                
                Text(badge.title)
                    .font(.system(size: 10))
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.3))
                    .lineLimit(1)
            }
        }
        .sheet(isPresented: $showDetail) {
            BadgeDetailView(badge: badge, isUnlocked: isUnlocked)
                .presentationDetents([.medium])
        }
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let isUnlocked: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.pulseBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? badge.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 40))
                        .foregroundColor(isUnlocked ? badge.color : .white.opacity(0.2))
                }
                
                // Title
                Text(badge.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Rarity
                Text(badge.rarity.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(badge.rarity.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(badge.rarity.color.opacity(0.2))
                    )
                
                // Description
                Text(badge.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Status
                if isUnlocked {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Unlocked!")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 16, weight: .medium))
                } else {
                    Text("Keep going to unlock this badge")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}
