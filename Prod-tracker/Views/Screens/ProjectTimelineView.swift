//
//  ProjectTimelineView.swift
//  Pulse
//
//  Beautiful visual timeline showing project journey and milestones
//

import SwiftUI
import SwiftData

struct ProjectTimelineView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Properties
    
    let project: Project
    
    // MARK: - State
    
    @State private var selectedEntry: TimelineEntry?
    @State private var animateTimeline = false
    @State private var scrollOffset: CGFloat = 0
    
    // MARK: - Computed
    
    private var timelineEntries: [TimelineEntry] {
        var entries: [TimelineEntry] = []
        
        // Add creation event
        entries.append(TimelineEntry(
            id: UUID(),
            date: project.createdAt,
            type: .created,
            title: "Project Created",
            subtitle: "The journey begins",
            icon: "sparkles",
            color: .pulseAccent
        ))
        
        // Add pulse entries
        if let pulses = project.pulseEntries {
            for pulse in pulses.sorted(by: { $0.date < $1.date }) {
                entries.append(TimelineEntry(
                    id: pulse.id,
                    date: pulse.date,
                    type: .pulse,
                    title: "Work Session",
                    subtitle: pulse.notes ?? "\(pulse.durationMinutes ?? 0) min • Intensity \(pulse.intensityLevel)/5",
                    icon: "heart.fill",
                    color: project.color
                ))
            }
        }
        
        // Add milestones
        if let milestones = project.milestones {
            for milestone in milestones.sorted(by: { $0.createdAt < $1.createdAt }) {
                entries.append(TimelineEntry(
                    id: milestone.id,
                    date: milestone.completedAt ?? milestone.createdAt,
                    type: milestone.isCompleted ? .milestoneCompleted : .milestoneAdded,
                    title: milestone.title,
                    subtitle: milestone.isCompleted ? "Milestone achieved! 🎉" : "Milestone set",
                    icon: milestone.isCompleted ? "flag.checkered" : "flag.fill",
                    color: milestone.isCompleted ? .pulseGreen : .orange
                ))
            }
        }
        
        // Add streak events (every 7 days)
        let streakMilestones = [7, 14, 30, 60, 100]
        for streak in streakMilestones where project.longestStreak >= streak {
            if let firstPulse = project.pulseEntries?.sorted(by: { $0.date < $1.date }).first {
                let streakDate = Calendar.current.date(byAdding: .day, value: streak, to: firstPulse.date) ?? Date()
                entries.append(TimelineEntry(
                    id: UUID(),
                    date: streakDate,
                    type: .streak,
                    title: "\(streak) Day Streak!",
                    subtitle: "Consistency achievement",
                    icon: "flame.fill",
                    color: .orange
                ))
            }
        }
        
        // Add completion if shipped
        if let archivedAt = project.archivedAt, project.archiveReason == .shipped {
            entries.append(TimelineEntry(
                id: UUID(),
                date: archivedAt,
                type: .shipped,
                title: "Project Shipped! 🚀",
                subtitle: "Mission accomplished",
                icon: "checkmark.seal.fill",
                color: .pulseGreen
            ))
        }
        
        return entries.sorted { $0.date > $1.date }
    }
    
    private var projectAge: String {
        let days = Calendar.current.dateComponents([.day], from: project.createdAt, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "1 day" }
        if days < 30 { return "\(days) days" }
        let months = days / 30
        if months == 1 { return "1 month" }
        return "\(months) months"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MeshGradientBackground(baseColor: project.color)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header stats
                        headerStats
                        
                        // Timeline
                        timelineContent
                    }
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateTimeline = true
                }
            }
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStats: some View {
        VStack(spacing: 20) {
            // Project orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [project.color.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Circle()
                    .fill(project.color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: project.iconName)
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    )
                    .shadow(color: project.color.opacity(0.5), radius: 20)
            }
            
            // Project name
            Text(project.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Age badge
            Text("Started \(projectAge) ago")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            // Quick stats
            HStack(spacing: 30) {
                TimelineStatBadge(
                    value: "\(project.pulseEntries?.count ?? 0)",
                    label: "Sessions",
                    icon: "heart.fill",
                    color: project.color
                )
                
                TimelineStatBadge(
                    value: "\(project.currentStreak)",
                    label: "Streak",
                    icon: "flame.fill",
                    color: .orange
                )
                
                TimelineStatBadge(
                    value: "\(project.milestones?.filter { $0.isCompleted }.count ?? 0)",
                    label: "Milestones",
                    icon: "flag.fill",
                    color: .pulseGreen
                )
            }
            .padding(.top, 10)
        }
        .padding()
        .padding(.top, 20)
    }
    
    // MARK: - Timeline Content
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("Timeline")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(timelineEntries.count) events")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Timeline items
            ForEach(Array(timelineEntries.enumerated()), id: \.element.id) { index, entry in
                TimelineItemView(
                    entry: entry,
                    isFirst: index == 0,
                    isLast: index == timelineEntries.count - 1,
                    projectColor: project.color
                )
                .opacity(animateTimeline ? 1 : 0)
                .offset(x: animateTimeline ? 0 : -50)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(Double(index) * 0.05),
                    value: animateTimeline
                )
            }
        }
        .padding(.bottom, 100)
    }
}

// MARK: - Timeline Entry

struct TimelineEntry: Identifiable {
    let id: UUID
    let date: Date
    let type: TimelineEventType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

enum TimelineEventType {
    case created
    case pulse
    case milestoneAdded
    case milestoneCompleted
    case streak
    case shipped
    case archived
}

// MARK: - Timeline Item View

struct TimelineItemView: View {
    let entry: TimelineEntry
    let isFirst: Bool
    let isLast: Bool
    let projectColor: Color
    
    @State private var isExpanded = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line and dot
            VStack(spacing: 0) {
                // Top line
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.white.opacity(0.2))
                    .frame(width: 2, height: 20)
                
                // Dot
                ZStack {
                    Circle()
                        .fill(entry.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(entry.color)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: entry.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                // Bottom line
                Rectangle()
                    .fill(isLast ? Color.clear : Color.white.opacity(0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 40)
            
            // Content card
            VStack(alignment: .leading, spacing: 8) {
                // Date
                Text(entry.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                // Title
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                // Subtitle
                Text(entry.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(isExpanded ? nil : 2)
                
                // Time
                Text(entry.date, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(entry.color.opacity(0.2), lineWidth: 1)
                    )
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding(.horizontal)
        .frame(minHeight: 100)
    }
}

// MARK: - Timeline Stat Badge

struct TimelineStatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectTimelineView(
        project: Project(name: "Pulse App", colorHex: "#6366F1", iconName: "heart.fill")
    )
    .environmentObject(HapticEngine.shared)
}
