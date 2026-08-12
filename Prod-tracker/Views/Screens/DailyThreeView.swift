//
//  DailyThreeView.swift
//  Pulse
//
//  Daily focus - pick 3 projects to focus on today
//

import SwiftUI
import SwiftData

struct DailyThreeView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<Project> { $0.archivedAt == nil },
        sort: [SortDescriptor(\Project.lastTouchedAt, order: .reverse)]
    )
    private var projects: [Project]
    
    @Query(sort: [SortDescriptor(\DailyFocus.date, order: .reverse)])
    private var dailyFocuses: [DailyFocus]
    
    // MARK: - State
    
    @State private var todaysFocus: DailyFocus?
    @State private var selectedProjectIDs: Set<UUID> = []
    @State private var showingReflection = false
    
    // MARK: - Computed
    
    private var focusedProjects: [Project] {
        projects.filter { selectedProjectIDs.contains($0.id) }
    }
    
    private var isToday: Bool {
        guard let focus = todaysFocus else { return false }
        return Calendar.current.isDateInToday(focus.date)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Today's Focus
                    if !selectedProjectIDs.isEmpty {
                        todaysFocusSection
                    }
                    
                    // Project Selection
                    projectSelectionSection
                    
                    // Past Days
                    pastFocusSection
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Daily Focus")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                loadTodaysFocus()
            }
            .sheet(isPresented: $showingReflection) {
                ReflectionSheet(focus: todaysFocus)
            }
        }
    }
    
    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.pulseAccent)
                Text("Which 3 projects get energy today?")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)

            Text("Choose intentionally. Everything else can wait.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseAccent.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pulseAccent.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.top, 4)
    }
    
    // MARK: - Today's Focus Section
    
    private var todaysFocusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(selectedProjectIDs.count)/3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pulseAccent)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(focusedProjects) { project in
                    FocusProjectRow(
                        project: project,
                        isCompleted: todaysFocus?.isCompleted(projectID: project.id) ?? false,
                        onToggleComplete: {
                            toggleProjectCompletion(project)
                        },
                        onRemove: {
                            removeFromFocus(project)
                        }
                    )
                }
            }
            
            // End of day reflection
            if let focus = todaysFocus, focus.completedProjectIDs.count == selectedProjectIDs.count && !selectedProjectIDs.isEmpty {
                Button {
                    showingReflection = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Add Reflection")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pulseAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pulseAccent.opacity(0.15))
                    )
                }
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
    
    // MARK: - Project Selection
    
    private var projectSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Projects")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(projects) { project in
                    ProjectSelectionRow(
                        project: project,
                        isSelected: selectedProjectIDs.contains(project.id),
                        isDisabled: selectedProjectIDs.count >= 3 && !selectedProjectIDs.contains(project.id)
                    ) {
                        toggleSelection(project)
                    }
                }
            }
        }
    }
    
    // MARK: - Past Focus Section

    private var pastFocusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Days")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            if dailyFocuses.filter({ !Calendar.current.isDateInToday($0.date) }).isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.2))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No history yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Your focus history will appear here")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                )
            } else {
                ForEach(dailyFocuses.prefix(7)) { focus in
                    if !Calendar.current.isDateInToday(focus.date) {
                        PastFocusRow(focus: focus, projects: projects)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Methods
    
    private func loadTodaysFocus() {
        let today = Calendar.current.startOfDay(for: Date())
        
        todaysFocus = dailyFocuses.first { focus in
            Calendar.current.isDate(focus.date, inSameDayAs: today)
        }
        
        if let focus = todaysFocus {
            selectedProjectIDs = Set(focus.projectIDs)
        }
    }
    
    private func toggleSelection(_ project: Project) {
        hapticEngine.playSelection()
        
        if selectedProjectIDs.contains(project.id) {
            selectedProjectIDs.remove(project.id)
        } else if selectedProjectIDs.count < 3 {
            selectedProjectIDs.insert(project.id)
        }
        
        saveFocus()
    }
    
    private func removeFromFocus(_ project: Project) {
        hapticEngine.playTap()
        selectedProjectIDs.remove(project.id)
        saveFocus()
    }
    
    private func toggleProjectCompletion(_ project: Project) {
        guard let focus = todaysFocus else { return }
        
        if focus.isCompleted(projectID: project.id) {
            focus.markIncomplete(projectID: project.id)
        } else {
            focus.markCompleted(projectID: project.id)
            hapticEngine.playSuccess()
            
            // Also touch the project
            project.touch()
        }
        
        try? modelContext.save()
    }
    
    private func saveFocus() {
        if let focus = todaysFocus {
            focus.projectIDs = Array(selectedProjectIDs)
        } else {
            let newFocus = DailyFocus(projectIDs: Array(selectedProjectIDs))
            modelContext.insert(newFocus)
            todaysFocus = newFocus
        }
        
        try? modelContext.save()
    }
}

// MARK: - Focus Project Row

struct FocusProjectRow: View {
    let project: Project
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Completion toggle
            Button(action: onToggleComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundColor(isCompleted ? .pulseGreen : .white.opacity(0.3))
                    .shadow(color: isCompleted ? Color.pulseGreen.opacity(0.4) : .clear, radius: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
            }

            // Project orb mini
            Circle()
                .fill(project.color.opacity(isCompleted ? 0.5 : 1))
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: project.iconName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(isCompleted ? 0.5 : 1))
                )
                .shadow(color: project.color.opacity(0.35), radius: 6)

            // Name + streak
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(isCompleted ? 0.45 : 1))
                    .strikethrough(isCompleted, color: .white.opacity(0.4))
                    .animation(.easeInOut(duration: 0.2), value: isCompleted)

                if project.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(project.currentStreak) day streak")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.orange.opacity(isCompleted ? 0.4 : 0.9))
                }
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isCompleted
                      ? Color.pulseGreen.opacity(0.08)
                      : project.color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isCompleted ? Color.pulseGreen.opacity(0.25) : project.color.opacity(0.25),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.35), value: isCompleted)
    }
}

// MARK: - Project Selection Row

struct ProjectSelectionRow: View {
    let project: Project
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini orb
                Circle()
                    .fill(project.color.opacity(isDisabled ? 0.25 : 1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: project.iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(isDisabled ? 0.4 : 1))
                    )
                    .shadow(color: project.color.opacity(isSelected ? 0.4 : 0), radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(isDisabled ? 0.35 : 0.9))

                    if project.currentStreak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 9))
                            Text("\(project.currentStreak)d streak")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.orange.opacity(isDisabled ? 0.4 : 0.9))
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // Health dot
                    Circle()
                        .fill(project.healthLevel.color)
                        .frame(width: 7, height: 7)

                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .pulseAccent : .white.opacity(0.2))
                        .animation(.spring(response: 0.3), value: isSelected)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? project.color.opacity(0.12)
                            : Color.white.opacity(isPressed ? 0.05 : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? project.color.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .disabled(isDisabled && !isSelected)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Past Focus Row

struct PastFocusRow: View {
    let focus: DailyFocus
    let projects: [Project]
    
    private var focusedProjects: [Project] {
        projects.filter { focus.projectIDs.contains($0.id) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(focus.formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Completion indicator
                Text("\(focus.completedProjectIDs.count)/\(focus.projectIDs.count)")
                    .font(.system(size: 12))
                    .foregroundColor(focus.completedProjectIDs.count == focus.projectIDs.count ? .pulseGreen : .white.opacity(0.5))
            }
            
            HStack(spacing: 8) {
                ForEach(focusedProjects) { project in
                    Circle()
                        .fill(project.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: focus.isCompleted(projectID: project.id) ? "checkmark" : "")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    DailyThreeView()
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self, DailyFocus.self], inMemory: true)
}
