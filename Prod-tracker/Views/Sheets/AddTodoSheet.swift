//
//  AddTodoSheet.swift
//  Pulse
//
//  Sheet for adding new todo items
//

import SwiftUI
import SwiftData

struct AddTodoSheet: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Properties
    
    let projects: [Project]
    
    // MARK: - State
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedPriority: TodoPriority = .medium
    @State private var hasDueDate = true
    @State private var dueDate = Date()
    @State private var selectedProjectID: UUID?
    @State private var showingProjects = false
    
    // Quick date options
    @State private var quickDateSelection: QuickDate = .today
    
    private var selectedProject: Project? {
        guard let id = selectedProjectID else { return nil }
        return projects.first { $0.id == id }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title input
                        titleSection
                        
                        // Quick date picker
                        quickDateSection
                        
                        // Priority picker
                        prioritySection
                        
                        // Project link
                        projectSection
                        
                        // Notes
                        notesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
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
                        addTodo()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.pulseAccent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("What needs to be done?", text: $title, axis: .vertical)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1...3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.1))
                )
                .tint(.pulseAccent)
        }
    }
    
    // MARK: - Quick Date Section
    
    private var quickDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 10) {
                ForEach(QuickDate.allCases, id: \.self) { option in
                    QuickDateButton(
                        option: option,
                        isSelected: quickDateSelection == option && hasDueDate
                    ) {
                        quickDateSelection = option
                        hasDueDate = option != .noDate
                        
                        if option != .noDate && option != .custom {
                            dueDate = option.date
                        }
                        
                        hapticEngine.playTap()
                    }
                }
            }
            
            // Custom date picker
            if quickDateSelection == .custom && hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: $dueDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.pulseAccent)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priority")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 10) {
                ForEach(TodoPriority.allCases, id: \.self) { priority in
                    PriorityButton(
                        priority: priority,
                        isSelected: selectedPriority == priority
                    ) {
                        selectedPriority = priority
                        hapticEngine.playTap()
                    }
                }
            }
        }
    }
    
    // MARK: - Project Section
    
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to Project")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Button {
                showingProjects.toggle()
            } label: {
                HStack {
                    if let project = selectedProject {
                        Circle()
                            .fill(project.color)
                            .frame(width: 14, height: 14)
                        
                        Text(project.name)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "folder")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Project")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .rotationEffect(.degrees(showingProjects ? 180 : 0))
                }
                .font(.system(size: 16, weight: .medium))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                )
            }
            
            if showingProjects {
                VStack(spacing: 4) {
                    // No project option
                    Button {
                        selectedProjectID = nil
                        showingProjects = false
                        hapticEngine.playTap()
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No Project")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            if selectedProjectID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.pulseAccent)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    
                    ForEach(projects) { project in
                        Button {
                            selectedProjectID = project.id
                            showingProjects = false
                            hapticEngine.playTap()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(project.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(project.name)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Health indicator
                                Circle()
                                    .fill(project.healthLevel.color)
                                    .frame(width: 8, height: 8)
                                
                                if selectedProjectID == project.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.pulseAccent)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedProjectID == project.id ? Color.pulseAccent.opacity(0.2) : Color.white.opacity(0.05))
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3), value: showingProjects)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Add details...", text: $notes, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.08))
                )
                .tint(.pulseAccent)
        }
    }
    
    // MARK: - Methods
    
    private func addTodo() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let todo = Todo(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            linkedProjectID: selectedProjectID
        )
        
        modelContext.insert(todo)
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Quick Date

enum QuickDate: CaseIterable {
    case today
    case tomorrow
    case nextWeek
    case custom
    case noDate
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .nextWeek: return "Next Week"
        case .custom: return "Custom"
        case .noDate: return "No Date"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .tomorrow: return "sunrise.fill"
        case .nextWeek: return "calendar"
        case .custom: return "calendar.badge.plus"
        case .noDate: return "minus.circle"
        }
    }
    
    var date: Date {
        let calendar = Calendar.current
        switch self {
        case .today: return calendar.startOfDay(for: Date())
        case .tomorrow: return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
        case .nextWeek: return calendar.date(byAdding: .weekOfYear, value: 1, to: calendar.startOfDay(for: Date())) ?? Date()
        case .custom, .noDate: return Date()
        }
    }
}

// MARK: - Quick Date Button

struct QuickDateButton: View {
    let option: QuickDate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 18))
                
                Text(option.title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pulseAccent : Color.white.opacity(0.08))
            )
        }
    }
}

// MARK: - Priority Button

struct PriorityButton: View {
    let priority: TodoPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: priority.icon)
                    .font(.system(size: 16))
                
                Text(priority.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : priority.color.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? priority.color : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.clear : priority.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AddTodoSheet(projects: [])
        .environmentObject(HapticEngine.shared)
}
