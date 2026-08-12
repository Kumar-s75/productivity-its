//
//  AchievementsView.swift
//  Pulse
//
//  Achievements and badges screen with beautiful animations
//
//  Display achievements and badges for gamification
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query private var achievements: [Achievement]
    
    // MARK: - State
    
    @State private var selectedCategory: AchievementCategory = .all
    @State private var showingAchievementDetail: Achievement?
    @State private var showConfetti = false
    
    // MARK: - Computed
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    private var totalCount: Int {
        AchievementType.allCases.count
    }
    
    private var filteredAchievements: [Achievement] {
        switch selectedCategory {
        case .all:
            return achievements.sorted { ($0.isUnlocked ? 0 : 1) < ($1.isUnlocked ? 0 : 1) }
        case .unlocked:
            return achievements.filter { $0.isUnlocked }
        case .locked:
            return achievements.filter { !$0.isUnlocked }
        case .streaks:
            return achievements.filter { 
                [.streak3, .streak7, .streak14, .streak30, .streak100].contains($0.type)
            }
        case .projects:
            return achievements.filter { 
                [.firstProject, .fiveProjects, .tenProjects, .firstShip, .fiveShips, .tenShips].contains($0.type)
            }
        case .special:
            return achievements.filter { 
                [.nightOwl, .earlyBird, .weekendWarrior, .reviver, .mercyKill].contains($0.type)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Category tabs
                    categoryTabs
                    
                    // Achievements grid
                    if filteredAchievements.isEmpty {
                        EmptyStateView(type: .noAchievements)
                    } else {
                        achievementsGrid
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                initializeAchievements()
            }
            .confetti(isActive: $showConfetti, intensity: .heavy)
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pulseYellow.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pulseYellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Progress text
            VStack(spacing: 6) {
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Achievements Unlocked")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.pulseYellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(unlockedCount) / CGFloat(max(totalCount, 1)), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.title,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                        hapticEngine.playTap()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Achievements Grid
    
    private var achievementsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredAchievements) { achievement in
                    AchievementCard(achievement: achievement)
                        .onTapGesture {
                            showingAchievementDetail = achievement
                            hapticEngine.playTap()
                        }
                }
            }
            .padding()
        }
        .sheet(item: $showingAchievementDetail) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }
    
    // MARK: - Initialize Achievements
    
    private func initializeAchievements() {
        // Create achievement records if they don't exist
        for type in AchievementType.allCases {
            if !achievements.contains(where: { $0.type == type }) {
                let achievement = Achievement(type: type)
                modelContext.insert(achievement)
            }
        }
    }
}

// MARK: - Achievement Category

enum AchievementCategory: CaseIterable {
    case all
    case unlocked
    case locked
    case streaks
    case projects
    case special
    
    var title: String {
        switch self {
        case .all: return "All"
        case .unlocked: return "Unlocked"
        case .locked: return "Locked"
        case .streaks: return "Streaks"
        case .projects: return "Projects"
        case .special: return "Special"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .unlocked: return "checkmark.seal"
        case .locked: return "lock"
        case .streaks: return "flame"
        case .projects: return "folder"
        case .special: return "star"
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.pulseAccent : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    
    @State private var animateGlow = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                // Glow for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [achievement.type.color.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateGlow ? 1.1 : 0.9)
                }
                
                Circle()
                    .fill(achievement.isUnlocked ? achievement.type.color.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 56, height: 56)
                
                Image(systemName: achievement.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? achievement.type.color : .white.opacity(0.3))
            }
            
            // Title
            Text(achievement.type.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress or date
            if achievement.isUnlocked {
                if let unlockedAt = achievement.unlockedAt {
                    Text(unlockedAt, style: .date)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                ProgressView(value: achievement.progressPercentage)
                    .tint(achievement.type.color)
                    .frame(width: 60)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(achievement.isUnlocked ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            achievement.isUnlocked ? achievement.type.color.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .opacity(achievement.isUnlocked ? 1 : 0.7)
        .onAppear {
            if achievement.isUnlocked {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let achievement: Achievement
    
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            Color.pulseBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding()
                
                Spacer()
                
                // Icon with glow
                ZStack {
                    if achievement.isUnlocked {
                        // Outer glow rings
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(achievement.type.color.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                                .frame(width: 140 + CGFloat(index * 30), height: 140 + CGFloat(index * 30))
                                .scaleEffect(animateIcon ? 1.1 : 0.95)
                                .animation(
                                    .easeInOut(duration: 1.5).delay(Double(index) * 0.15).repeatForever(autoreverses: true),
                                    value: animateIcon
                                )
                        }
                        
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [achievement.type.color.opacity(0.5), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.type.color.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    // Icon
                    Image(systemName: achievement.type.icon)
                        .font(.system(size: 50))
                        .foregroundColor(achievement.isUnlocked ? achievement.type.color : .white.opacity(0.3))
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                }
                
                // Title and description
                VStack(spacing: 12) {
                    Text(achievement.type.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(achievement.type.description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.pulseGreen)
                            Text("Unlocked")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.pulseGreen)
                        }
                        
                        if let unlockedAt = achievement.unlockedAt {
                            Text(unlockedAt, style: .date)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 10)
                } else {
                    VStack(spacing: 12) {
                        // Progress
                        VStack(spacing: 6) {
                            Text("\(achievement.progress) / \(achievement.type.requirement)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ProgressView(value: achievement.progressPercentage)
                                .tint(achievement.type.color)
                                .frame(width: 150)
                        }
                        
                        Text("Keep going!")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
        .modelContainer(for: Achievement.self)
        .environmentObject(HapticEngine.shared)
}
