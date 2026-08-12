//
//  HabitStackView.swift
//  Pulse
//
//  Habit stacking - chain habits with project work
//

import SwiftUI
import SwiftData

struct HabitStackView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(sort: \HabitStack.sortOrder)
    private var habitStacks: [HabitStack]
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var showingAddSheet = false
    @State private var selectedStack: HabitStack?
    @State private var completedToday: Set<UUID> = []
    @State private var showConfetti = false
    
    private var todayProgress: Double {
        guard !habitStacks.isEmpty else { return 0 }
        return Double(completedToday.count) / Double(habitStacks.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress header
                        progressHeader
                        
                        // Habit stacks
                        if habitStacks.isEmpty {
                            emptyState
                        } else {
                            habitList
                        }
                    }
                    .padding()
                }
                
                ConfettiView(isActive: $showConfetti, intensity: .heavy)
            }
            .navigationTitle("Habit Stack")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pulseAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHabitStackSheet()
            }
            .sheet(item: $selectedStack) { stack in
                EditHabitStackSheet(stack: stack)
            }
            .onAppear {
                loadTodayProgress()
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: todayProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.pulseGreen, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: todayProgress)
                
                // Center content
                VStack(spacing: 2) {
                    Text("\(completedToday.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("of \(habitStacks.count)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Message
            Text(progressMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    private var progressMessage: String {
        if completedToday.count == habitStacks.count && !habitStacks.isEmpty {
            return "🎉 All habits completed!"
        } else if completedToday.count > 0 {
            return "Keep going! You're doing great."
        } else {
            return "Start your habit stack for today"
        }
    }
    
    // MARK: - Habit List
    
    private var habitList: some View {
        VStack(spacing: 12) {
            ForEach(Array(habitStacks.enumerated()), id: \.element.id) { index, stack in
                HabitStackCard(
                    stack: stack,
                    index: index + 1,
                    isCompleted: completedToday.contains(stack.id),
                    previousCompleted: index == 0 || completedToday.contains(habitStacks[index - 1].id)
                ) {
                    toggleCompletion(stack)
                } onEdit: {
                    selectedStack = stack
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Habits Yet")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Create a chain of habits to build\npowerful routines around your projects")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add First Habit")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.pulseAccent)
                )
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - Methods
    
    private func loadTodayProgress() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        completedToday = Set(
            habitStacks
                .filter { stack in
                    guard let lastCompleted = stack.lastCompletedAt else { return false }
                    return calendar.isDate(lastCompleted, inSameDayAs: today)
                }
                .map { $0.id }
        )
    }
    
    private func toggleCompletion(_ stack: HabitStack) {
        if completedToday.contains(stack.id) {
            completedToday.remove(stack.id)
            stack.lastCompletedAt = nil
        } else {
            completedToday.insert(stack.id)
            stack.lastCompletedAt = Date()
            stack.completionCount += 1
            hapticEngine.playSuccess()
            
            // Touch linked project
            if let projectID = stack.linkedProjectID,
               let project = activeProjects.first(where: { $0.id == projectID }) {
                project.touch()
            }
            
            // Check if all completed
            if completedToday.count == habitStacks.count {
                showConfetti = true
            }
        }
    }
}

// MARK: - Habit Stack Card

struct HabitStackCard: View {
    let stack: HabitStack
    let index: Int
    let isCompleted: Bool
    let previousCompleted: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    var body: some View {
        HStack(spacing: 16) {
            // Chain link indicator
            VStack(spacing: 0) {
                if index > 1 {
                    Rectangle()
                        .fill(previousCompleted ? Color.pulseGreen : Color.white.opacity(0.2))
                        .frame(width: 3, height: 20)
                }
                
                // Checkbox
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.pulseGreen : Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .disabled(!previousCompleted && !isCompleted)
                .opacity(previousCompleted || isCompleted ? 1 : 0.5)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title row
                HStack {
                    Image(systemName: stack.icon)
                        .foregroundColor(isCompleted ? .pulseGreen : .white.opacity(0.6))
                    
                    Text(stack.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCompleted ? .white.opacity(0.5) : .white)
                        .strikethrough(isCompleted)
                }
                
                // Duration
                if let duration = stack.estimatedMinutes {
                    Text("\(duration) min")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Trigger
                if let trigger = stack.triggerText {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.system(size: 10))
                        Text(trigger)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.pulseAccent.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCompleted ? Color.pulseGreen.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCompleted ? Color.pulseGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3), value: isCompleted)
    }
}

// MARK: - Add Habit Stack Sheet

struct AddHabitStackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    @Query(sort: \HabitStack.sortOrder)
    private var existingStacks: [HabitStack]
    
    @State private var title = ""
    @State private var icon = "circle.fill"
    @State private var estimatedMinutes: Int?
    @State private var triggerText = ""
    @State private var selectedProjectID: UUID?
    
    private let icons = [
        "sun.max.fill", "moon.fill", "cup.and.saucer.fill", "figure.walk",
        "book.fill", "pencil", "brain.head.profile", "heart.fill",
        "leaf.fill", "drop.fill", "flame.fill", "bolt.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("e.g., Morning meditation", text: $title)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        
                        // Icon picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(icons, id: \.self) { iconName in
                                    Button {
                                        icon = iconName
                                        hapticEngine.playTap()
                                    } label: {
                                        Image(systemName: iconName)
                                            .font(.system(size: 20))
                                            .foregroundColor(icon == iconName ? .pulseAccent : .white.opacity(0.5))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(icon == iconName ? Color.pulseAccent.opacity(0.2) : Color.white.opacity(0.05))
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Duration (optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 10) {
                                ForEach([5, 10, 15, 30], id: \.self) { mins in
                                    Button {
                                        estimatedMinutes = estimatedMinutes == mins ? nil : mins
                                        hapticEngine.playTap()
                                    } label: {
                                        Text("\(mins)m")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(estimatedMinutes == mins ? .white : .white.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(estimatedMinutes == mins ? Color.pulseAccent : Color.white.opacity(0.08))
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Trigger
                        VStack(alignment: .leading, spacing: 8) {
                            Text("After I... (optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("e.g., finish my coffee", text: $triggerText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        
                        // Link to project
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Link to Project (optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    Button {
                                        selectedProjectID = nil
                                        hapticEngine.playTap()
                                    } label: {
                                        Text("None")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedProjectID == nil ? .white : .white.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(selectedProjectID == nil ? Color.pulseAccent : Color.white.opacity(0.08))
                                            )
                                    }
                                    
                                    ForEach(activeProjects) { project in
                                        Button {
                                            selectedProjectID = project.id
                                            hapticEngine.playTap()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(project.color)
                                                    .frame(width: 8, height: 8)
                                                Text(project.name)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(selectedProjectID == project.id ? .white : .white.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(selectedProjectID == project.id ? project.color.opacity(0.5) : Color.white.opacity(0.08))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.pulseAccent)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveHabit() {
        let stack = HabitStack(
            title: title,
            icon: icon,
            estimatedMinutes: estimatedMinutes,
            triggerText: triggerText.isEmpty ? nil : triggerText,
            linkedProjectID: selectedProjectID,
            sortOrder: existingStacks.count
        )
        
        modelContext.insert(stack)
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Edit Habit Stack Sheet

struct EditHabitStackSheet: View {
    let stack: HabitStack
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    @State private var title: String
    @State private var showDeleteConfirm = false
    
    init(stack: HabitStack) {
        self.stack = stack
        _title = State(initialValue: stack.title)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Stats
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(stack.completionCount)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.pulseGreen)
                            Text("Completions")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        VStack {
                            Text("\(stack.currentStreak)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("Streak")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    
                    // Edit title
                    TextField("Habit name", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    
                    Spacer()
                    
                    // Delete button
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Habit")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        stack.title = title
                        hapticEngine.playTap()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.pulseAccent)
                }
            }
            .alert("Delete Habit?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(stack)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete this habit and its history.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HabitStackView()
        .modelContainer(for: [HabitStack.self, Project.self])
        .environmentObject(HapticEngine.shared)
}
