//
//  StatsView.swift
//  Pulse
//
//  Beautiful analytics and insights dashboard
//

import SwiftUI
import SwiftData

struct StatsView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query private var projects: [Project]
    @Query private var pulseEntries: [PulseEntry]
    @Query private var todos: [Todo]
    
    // MARK: - State
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var animateCharts = false
    
    // MARK: - Computed
    
    private var activeProjects: [Project] {
        projects.filter { $0.archivedAt == nil }
    }
    
    private var completedProjects: [Project] {
        projects.filter {
            $0.archivedAt != nil &&
            ($0.archiveReason == .completed || $0.archiveReason == .shipped)
        }
    }
    
    private var totalPulses: Int {
        pulseEntries.count
    }
    
    private var totalTodosCompleted: Int {
        todos.filter { $0.completedAt != nil }.count
    }
    
    private var longestStreak: Int {
        projects.map { $0.longestStreak }.max() ?? 0
    }
    
    private var currentStreak: Int {
        projects.map { $0.currentStreak }.max() ?? 0
    }
    
    private var averageHealthScore: Double {
        guard !activeProjects.isEmpty else { return 0 }
        
        let total = activeProjects.reduce(0.0) { partialResult, project in
            partialResult + healthScore(for: project)
        }
        
        return total / Double(activeProjects.count)
    }
    
    private var weeklyActivity: [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            
            let dayEntries = pulseEntries.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            
            let dayTodos = todos.filter {
                guard let completedAt = $0.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }
            
            return DayActivity(
                date: date,
                pulseCount: dayEntries.count,
                todoCount: dayTodos.count,
                totalIntensity: dayEntries.count + dayTodos.count
            )
        }
    }
    
    private var projectHealthDistribution: [HealthDistribution] {
        let grouped = Dictionary(grouping: activeProjects) { $0.healthLevel }
        return HealthLevel.allCases.map { level in
            HealthDistribution(
                level: level,
                count: grouped[level]?.count ?? 0
            )
        }
    }
    
    // MARK: - Helpers
    
    private func healthScore(for project: Project) -> Double {
        switch project.healthLevel {
        case .healthy:
            return 1.0
        case .needsAttention:
            return 0.75
        case .critical:
            return 0.5
        case .dying:
            return 0.25
        case .dead:
            return 0.0
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        overviewSection
                        weeklyActivitySection
                        healthDistributionSection
                        topProjectsSection
                        funFactsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateCharts = true
                }
            }
        }
    }
    
    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 14)
                    .frame(width: 148, height: 148)

                // Glow shadow ring
                Circle()
                    .trim(from: 0, to: animateCharts ? CGFloat(averageHealthScore) : 0)
                    .stroke(
                        AngularGradient(colors: [.pulseGreen, .pulseYellow], center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 148, height: 148)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .opacity(0.6)

                // Main arc
                Circle()
                    .trim(from: 0, to: animateCharts ? CGFloat(averageHealthScore) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [.pulseGreen, .pulseYellow, .pulseRed],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 148, height: 148)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(averageHealthScore * 100))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Health")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.vertical, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStatCard(
                    icon: "folder.fill",
                    value: "\(activeProjects.count)",
                    label: "Active",
                    color: .pulseAccent
                )
                
                QuickStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(completedProjects.count)",
                    label: "Shipped",
                    color: .pulseGreen
                )
                
                QuickStatCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Streak",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "heart.fill",
                    value: "\(totalPulses)",
                    label: "Pulses",
                    color: .pink
                )
                
                QuickStatCard(
                    icon: "checkmark.square.fill",
                    value: "\(totalTodosCompleted)",
                    label: "Tasks",
                    color: .cyan
                )
                
                QuickStatCard(
                    icon: "trophy.fill",
                    value: "\(longestStreak)",
                    label: "Best",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Weekly Activity Section
    
    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyActivity, id: \.date) { day in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.pulseAccent, .pulseAccent.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: animateCharts ? CGFloat(max(day.totalIntensity * 8, 4)) : 0)
                        
                        Text(day.dayLabel)
                            .font(.system(size: 11))
                            .foregroundColor(day.isToday ? .pulseAccent : .white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Health Distribution Section
    
    private var healthDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Health")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(projectHealthDistribution, id: \.level) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.level.color)
                            .frame(width: 12, height: 12)
                        
                        Text(item.level.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.level.color)
                                    .frame(
                                        width: animateCharts
                                        ? geometry.size.width * item.percentage(of: activeProjects.count)
                                        : 0
                                    )
                            }
                        }
                        .frame(width: 100, height: 8)
                        
                        Text("\(item.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Top Projects Section
    
    private var topProjectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Performers")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            if activeProjects.isEmpty {
                Text("No projects yet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(activeProjects.sorted { $0.currentStreak > $1.currentStreak }.prefix(3))) { project in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(project.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: project.iconName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(project.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("\(project.currentStreak) day streak")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(project.healthLevel.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(project.healthLevel.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(project.healthLevel.color)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Fun Facts Section
    
    private var funFactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fun Facts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                FunFactCard(
                    emoji: "🔥",
                    fact: "Your longest streak was \(longestStreak) days",
                    color: .orange
                )
                
                FunFactCard(
                    emoji: "💪",
                    fact: "You've logged \(totalPulses) work sessions",
                    color: .blue
                )
                
                if let mostActive = activeProjects.max(by: {
                    ($0.pulseEntries?.count ?? 0) < ($1.pulseEntries?.count ?? 0)
                }) {
                    FunFactCard(
                        emoji: "⭐",
                        fact: "\(mostActive.name) is your most active project",
                        color: .yellow
                    )
                }
                
                FunFactCard(
                    emoji: "✅",
                    fact: "You've completed \(totalTodosCompleted) tasks",
                    color: .green
                )
            }
        }
    }
}

// MARK: - Supporting Types

struct DayActivity {
    let date: Date
    let pulseCount: Int
    let todoCount: Int
    let totalIntensity: Int
    
    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct HealthDistribution {
    let level: HealthLevel
    let count: Int
    
    func percentage(of total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(count) / CGFloat(total)
    }
}

enum TimeRange: CaseIterable {
    case week
    case month
    case year
    case allTime
    
    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        case .allTime: return "All Time"
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.4), radius: 6)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Fun Fact Card

struct FunFactCard: View {
    let emoji: String
    let fact: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
            
            Text(fact)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .modelContainer(for: [Project.self, PulseEntry.self, Todo.self])
        .environmentObject(HapticEngine.shared)
}
