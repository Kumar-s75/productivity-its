//
//  ArchiveView.swift
//  Pulse
//
//  The Archive - museum of completed and killed projects
//

import SwiftUI
import SwiftData

struct ArchiveView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<Project> { $0.archivedAt != nil },
        sort: [SortDescriptor(\Project.archivedAt, order: .reverse)]
    )
    private var archivedProjects: [Project]
    
    // MARK: - State
    
    @State private var selectedProject: Project?
    @State private var showingProjectDetail = false
    @State private var filterReason: ArchiveReason?
    
    // MARK: - Computed
    
    private var filteredProjects: [Project] {
        if let reason = filterReason {
            return archivedProjects.filter { $0.archiveReason == reason }
        }
        return archivedProjects
    }
    
    private var completedCount: Int {
        archivedProjects.filter { $0.archiveReason == .completed }.count
    }
    
    private var killedCount: Int {
        archivedProjects.filter { $0.archiveReason == .killed }.count
    }
    
    private var hibernatingCount: Int {
        archivedProjects.filter { $0.archiveReason == .hibernating }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if archivedProjects.isEmpty {
                        emptyStateView
                    } else {
                        // Stats Overview
                        archiveStatsSection
                        
                        // Filter Pills
                        filterSection
                        
                        // Archive Grid
                        archiveGridSection
                    }
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedProject) { project in
                ArchivedProjectDetailView(project: project)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.2))
            
            Text("No Archived Projects")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Completed and killed projects will appear here as a record of your journey.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
    
    // MARK: - Stats Section
    
    private var archiveStatsSection: some View {
        HStack(spacing: 12) {
            ArchiveStatPill(
                count: completedCount,
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: .pulseGreen
            )
            
            ArchiveStatPill(
                count: killedCount,
                label: "Killed",
                icon: "xmark.circle.fill",
                color: .pulseRed
            )
            
            ArchiveStatPill(
                count: hibernatingCount,
                label: "Hibernating",
                icon: "moon.zzz.fill",
                color: .pulseAccent
            )
        }
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ArchiveFilterChip(
                    label: "All",
                    isSelected: filterReason == nil,
                    count: archivedProjects.count
                ) {
                    withAnimation {
                        filterReason = nil
                    }
                }
                
                ForEach(ArchiveReason.allCases, id: \.self) { reason in
                    let count = archivedProjects.filter { $0.archiveReason == reason }.count
                    
                    ArchiveFilterChip(
                        label: reason.rawValue,
                        isSelected: filterReason == reason,
                        count: count,
                        color: reason.color
                    ) {
                        withAnimation {
                            filterReason = filterReason == reason ? nil : reason
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Archive Grid
    
    private var archiveGridSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredProjects) { project in
                ArchivedProjectCard(project: project) {
                    selectedProject = project
                }
            }
        }
    }
}

// MARK: - Archive Stat Pill

struct ArchiveStatPill: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text("\(count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
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

// MARK: - Archive Filter Chip

struct ArchiveFilterChip: View {
    let label: String
    let isSelected: Bool
    var count: Int = 0
    var color: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : color.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.3) : Color.pulseCardBackground)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color.opacity(0.5) : Color.pulseBorder, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Archived Project Card

struct ArchivedProjectCard: View {
    let project: Project
    let onTap: () -> Void
    
    private var durationText: String {
        guard let archived = project.archivedAt else { return "" }
        
        let days = Calendar.current.dateComponents([.day], from: project.createdAt, to: archived).day ?? 0
        
        if days < 30 {
            return "\(days) days"
        } else if days < 365 {
            let months = days / 30
            return "\(months) month\(months > 1 ? "s" : "")"
        } else {
            let years = days / 365
            return "\(years) year\(years > 1 ? "s" : "")"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Project orb (dimmed)
                ZStack {
                    Circle()
                        .fill(project.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(project.color.opacity(0.7))
                    
                    // Archive badge
                    if let reason = project.archiveReason {
                        Image(systemName: reason.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(reason.color)
                            .padding(4)
                            .background(Circle().fill(Color.pulseBackground))
                            .offset(x: 18, y: 18)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Duration
                        Label(durationText, systemImage: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        // Active days
                        Label("\(project.totalActiveDays) active", systemImage: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        // Best streak
                        if project.longestStreak > 0 {
                            Label("\(project.longestStreak) best", systemImage: "flame")
                                .font(.system(size: 11))
                                .foregroundColor(.orange.opacity(0.7))
                        }
                    }
                    
                    if let reason = project.archiveReason {
                        Text(reason.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(reason.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(reason.color.opacity(0.15))
                            )
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
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
}

// MARK: - Archived Project Detail View

struct ArchivedProjectDetailView: View {
    @Bindable var project: Project
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    @State private var showingReviveConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stats
                    statsSection
                    
                    // Post Mortem
                    if let postMortem = project.postMortem, !postMortem.isEmpty {
                        postMortemSection(postMortem)
                    }
                    
                    // Lessons Learned
                    if let lessons = project.lessonsLearned, !lessons.isEmpty {
                        lessonsSection(lessons)
                    }
                    
                    // Revive Button
                    if project.archiveReason == .hibernating || project.archiveReason == .killed {
                        reviveSection
                    }
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Revive Project?", isPresented: $showingReviveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Revive") {
                    reviveProject()
                }
            } message: {
                Text("This will move \(project.name) back to your active projects. The streak will reset.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Dimmed orb
            ZStack {
                Circle()
                    .fill(project.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: project.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(project.color.opacity(0.5))
            }
            
            Text(project.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            if let reason = project.archiveReason {
                HStack {
                    Image(systemName: reason.icon)
                    Text(reason.rawValue)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(reason.color)
            }
            
            if let archivedAt = project.archivedAt {
                Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            ArchiveDetailStat(title: "Duration", value: durationText, icon: "clock")
            ArchiveDetailStat(title: "Active Days", value: "\(project.totalActiveDays)", icon: "calendar")
            ArchiveDetailStat(title: "Best Streak", value: "\(project.longestStreak)", icon: "flame.fill")
        }
    }
    
    private var durationText: String {
        guard let archived = project.archivedAt else { return "N/A" }
        let days = Calendar.current.dateComponents([.day], from: project.createdAt, to: archived).day ?? 0
        return "\(days)d"
    }
    
    private func postMortemSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Post Mortem", systemImage: "doc.text")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                )
        }
    }
    
    private func lessonsSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Lessons Learned", systemImage: "lightbulb")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseAccent.opacity(0.1))
                )
        }
    }
    
    private var reviveSection: some View {
        Button {
            showingReviveConfirmation = true
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                Text("Revive Project")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.pulseAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pulseAccent.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pulseAccent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func reviveProject() {
        project.revive()
        hapticEngine.playSuccess()
        try? modelContext.save()
        dismiss()
    }
}

struct ArchiveDetailStat: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    ArchiveView()
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
