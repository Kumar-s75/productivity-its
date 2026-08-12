//
//  PulseMapView.swift
//  Pulse
//
//  Weekly pulse visualization - see where your energy went
//

import SwiftUI
import SwiftData

struct PulseMapView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<Project> { $0.archivedAt == nil },
        sort: [SortDescriptor(\Project.name)]
    )
    private var projects: [Project]
    
    @Query(sort: [SortDescriptor(\PulseEntry.date, order: .reverse)])
    private var allEntries: [PulseEntry]
    
    // MARK: - State
    
    @State private var selectedWeekOffset: Int = 0
    @State private var selectedProject: Project?
    
    // MARK: - Computed
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6 + (selectedWeekOffset * 7), to: today)!
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: weekStart)
        }
    }
    
    private var weekDayLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return weekDates.map { formatter.string(from: $0) }
    }
    
    private var weekDateLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return weekDates.map { formatter.string(from: $0) }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Week Navigation
                    weekNavigationHeader
                    
                    // Summary Stats
                    weekSummarySection
                    
                    // Pulse Grid
                    pulseGridSection
                    
                    // Project Breakdown
                    projectBreakdownSection
                    
                    // Insights
                    insightsSection
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Pulse Map")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Week Navigation
    
    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedWeekOffset -= 1
                }
                hapticEngine.playTap()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(weekRangeText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if selectedWeekOffset == 0 {
                    Text("This Week")
                        .font(.system(size: 12))
                        .foregroundColor(.pulseAccent)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedWeekOffset = min(0, selectedWeekOffset + 1)
                }
                hapticEngine.playTap()
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(selectedWeekOffset >= 0 ? .white.opacity(0.2) : .white.opacity(0.6))
            }
            .disabled(selectedWeekOffset >= 0)
        }
        .padding(.horizontal)
    }
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let first = weekDates.first, let last = weekDates.last else {
            return ""
        }
        
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    // MARK: - Week Summary
    
    private var weekSummarySection: some View {
        HStack(spacing: 12) {
            MapSummaryCard(
                title: "Active Days",
                value: "\(activeDaysCount)",
                subtitle: "of 7",
                color: .pulseGreen
            )
            
            MapSummaryCard(
                title: "Projects Touched",
                value: "\(projectsTouchedCount)",
                subtitle: "of \(projects.count)",
                color: .pulseAccent
            )
            
            MapSummaryCard(
                title: "Total Sessions",
                value: "\(totalSessionsCount)",
                subtitle: "logged",
                color: .pulseOrange
            )
        }
    }
    
    private var activeDaysCount: Int {
        let calendar = Calendar.current
        var activeDays = Set<Date>()
        
        for entry in weekEntries {
            let day = calendar.startOfDay(for: entry.date)
            activeDays.insert(day)
        }
        
        return activeDays.count
    }
    
    private var projectsTouchedCount: Int {
        var touchedProjects = Set<UUID>()
        
        for entry in weekEntries {
            if let projectID = entry.project?.id {
                touchedProjects.insert(projectID)
            }
        }
        
        return touchedProjects.count
    }
    
    private var totalSessionsCount: Int {
        weekEntries.count
    }
    
    private var weekEntries: [PulseEntry] {
        let calendar = Calendar.current
        guard let weekStart = weekDates.first, let weekEnd = weekDates.last else {
            return []
        }
        
        let endOfWeek = calendar.date(byAdding: .day, value: 1, to: weekEnd)!
        
        return allEntries.filter { entry in
            entry.date >= weekStart && entry.date < endOfWeek
        }
    }
    
    // MARK: - Pulse Grid
    
    private var pulseGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Grid")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 0) {
                // Day labels
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 80)
                    
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 2) {
                            Text(weekDayLabels[index])
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Text(weekDateLabels[index])
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)
                
                // Project rows
                ForEach(projects) { project in
                    HStack(spacing: 0) {
                        // Project name
                        HStack(spacing: 6) {
                            Circle()
                                .fill(project.color)
                                .frame(width: 12, height: 12)
                            
                            Text(project.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .frame(width: 80, alignment: .leading)
                        
                        // Day cells
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let intensity = pulseIntensity(for: project, on: weekDates[dayIndex])
                            
                            PulseCell(
                                intensity: intensity,
                                color: project.color
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pulseCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.pulseBorder, lineWidth: 1)
                    )
            )
        }
    }
    
    private func pulseIntensity(for project: Project, on date: Date) -> Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        let dayEntries = allEntries.filter { entry in
            entry.project?.id == project.id &&
            entry.date >= dayStart &&
            entry.date < dayEnd
        }
        
        if dayEntries.isEmpty {
            return 0
        }
        
        // Return max intensity for the day
        return dayEntries.map { $0.intensityLevel }.max() ?? 0
    }
    
    // MARK: - Project Breakdown
    
    private var projectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Project Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ForEach(sortedProjectsByActivity) { project in
                let count = sessionCount(for: project)
                
                ProjectActivityRow(
                    project: project,
                    sessionCount: count,
                    maxCount: maxSessionCount
                )
            }
        }
    }
    
    private var sortedProjectsByActivity: [Project] {
        projects.sorted { p1, p2 in
            sessionCount(for: p1) > sessionCount(for: p2)
        }
    }
    
    private func sessionCount(for project: Project) -> Int {
        weekEntries.filter { $0.project?.id == project.id }.count
    }
    
    private var maxSessionCount: Int {
        projects.map { sessionCount(for: $0) }.max() ?? 1
    }
    
    // MARK: - Insights
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Most active day
                if let mostActiveDay = findMostActiveDay() {
                    InsightCard(
                        icon: "calendar.badge.clock",
                        title: "Most Active Day",
                        value: mostActiveDay,
                        color: .pulseGreen
                    )
                }
                
                // Neglected projects
                let neglectedCount = projects.filter { sessionCount(for: $0) == 0 }.count
                if neglectedCount > 0 {
                    InsightCard(
                        icon: "exclamationmark.triangle",
                        title: "Neglected Projects",
                        value: "\(neglectedCount) project\(neglectedCount > 1 ? "s" : "") got no love",
                        color: .pulseOrange
                    )
                }
                
                // Streak kings
                if let topStreak = projects.max(by: { $0.currentStreak < $1.currentStreak }),
                   topStreak.currentStreak > 0 {
                    InsightCard(
                        icon: "flame.fill",
                        title: "Streak Leader",
                        value: "\(topStreak.name) at \(topStreak.currentStreak) days",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private func findMostActiveDay() -> String? {
        let calendar = Calendar.current
        var dayCounts: [Date: Int] = [:]
        
        for entry in weekEntries {
            let day = calendar.startOfDay(for: entry.date)
            dayCounts[day, default: 0] += 1
        }
        
        guard let maxDay = dayCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: maxDay)
    }
}

// MARK: - Supporting Views

struct MapSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pulseBorder, lineWidth: 1)
                )
        )
    }
}

struct PulseCell: View {
    let intensity: Int
    let color: Color
    
    private var opacity: Double {
        switch intensity {
        case 0: return 0.1
        case 1: return 0.3
        case 2: return 0.5
        case 3: return 0.7
        case 4: return 0.85
        case 5: return 1.0
        default: return 0.1
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(intensity > 0 ? color.opacity(opacity) : Color.white.opacity(0.05))
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(intensity > 0 ? color.opacity(0.3) : Color.clear, lineWidth: 1)
            )
    }
}

struct ProjectActivityRow: View {
    let project: Project
    let sessionCount: Int
    let maxCount: Int
    
    private var fillPercentage: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(sessionCount) / CGFloat(maxCount)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Project indicator
            Circle()
                .fill(project.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: project.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(sessionCount) session\(sessionCount != 1 ? "s" : "")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(project.color)
                            .frame(width: geometry.size.width * fillPercentage)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
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
    PulseMapView()
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self, PulseEntry.self], inMemory: true)
}
