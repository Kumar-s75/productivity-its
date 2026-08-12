//
//  TodoListView.swift
//  Pulse
//
//  Daily todo list integrated with projects
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(
        filter: #Predicate<Todo> { $0.completedAt == nil },
        sort: [
            SortDescriptor(\Todo.dueDate, order: .forward)
        ]
    )
    private var incompleteTodos: [Todo]
    
    @Query(
        filter: #Predicate<Todo> { $0.completedAt != nil },
        sort: [SortDescriptor(\Todo.completedAt, order: .reverse)]
    )
    private var completedTodos: [Todo]
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var projects: [Project]
    
    // MARK: - State
    
    @State private var showingAddTodo = false
    @State private var selectedFilter: TodoFilter = .today
    @State private var showingCompletedSection = false
    @State private var showConfetti = false
    
    // MARK: - Computed
    
    private var filteredTodos: [Todo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch selectedFilter {
        case .today:
            return incompleteTodos.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return calendar.isDateInToday(dueDate) || dueDate < today
            }.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
            
        case .upcoming:
            return incompleteTodos.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return dueDate > today && !calendar.isDateInToday(dueDate)
            }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            
        case .all:
            return incompleteTodos.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
            
        case .noDate:
            return incompleteTodos.filter { $0.dueDate == nil }
        }
    }
    
    private var overdueTodos: [Todo] {
        incompleteTodos.filter { $0.isOverdue }
    }
    
    private var todayCompletedCount: Int {
        let calendar = Calendar.current
        return completedTodos.filter { todo in
            guard let completedAt = todo.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats header
                    statsHeader
                    
                    // Filter tabs
                    filterTabs
                    
                    // Todo list
                    if filteredTodos.isEmpty && !showingCompletedSection {
                        emptyState
                    } else {
                        todoList
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTodo = true
                        hapticEngine.playTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.pulseAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddTodo) {
                AddTodoSheet(projects: projects)
            }
            .confetti(isActive: $showConfetti, intensity: .medium)
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 20) {
            // Completed today
            StatCard(
                icon: "checkmark.circle.fill",
                value: "\(todayCompletedCount)",
                label: "Done Today",
                color: .pulseGreen
            )
            
            // Remaining
            StatCard(
                icon: "circle",
                value: "\(filteredTodos.count)",
                label: "Remaining",
                color: .pulseAccent
            )
            
            // Overdue
            if !overdueTodos.isEmpty {
                StatCard(
                    icon: "exclamationmark.circle.fill",
                    value: "\(overdueTodos.count)",
                    label: "Overdue",
                    color: .red
                )
            }
        }
        .padding()
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TodoFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                        hapticEngine.playTap()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Todo List
    
    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Overdue section
                if selectedFilter == .today && !overdueTodos.isEmpty {
                    Section {
                        ForEach(overdueTodos) { todo in
                            TodoRow(
                                todo: todo,
                                projects: projects,
                                onComplete: { completeTodo(todo) },
                                onDelete: { deleteTodo(todo) }
                            )
                        }
                    } header: {
                        SectionHeader(title: "Overdue", icon: "exclamationmark.triangle.fill", color: .red)
                    }
                }
                
                // Main todos
                ForEach(filteredTodos.filter { !$0.isOverdue || selectedFilter != .today }) { todo in
                    TodoRow(
                        todo: todo,
                        projects: projects,
                        onComplete: { completeTodo(todo) },
                        onDelete: { deleteTodo(todo) }
                    )
                }
                
                // Completed section toggle
                if !completedTodos.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showingCompletedSection.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Completed (\(completedTodos.count))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: showingCompletedSection ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .padding(.top, 8)
                    
                    if showingCompletedSection {
                        ForEach(completedTodos.prefix(10)) { todo in
                            CompletedTodoRow(todo: todo) {
                                uncompleteTodo(todo)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.pulseAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: selectedFilter == .today ? "sun.max.fill" : "tray.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pulseAccent.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(emptyStateSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddTodo = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Task")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.pulseAccent)
                .cornerRadius(12)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .today: return "All Clear! 🎉"
        case .upcoming: return "Nothing Upcoming"
        case .all: return "No Tasks Yet"
        case .noDate: return "All Scheduled"
        }
    }
    
    private var emptyStateSubtitle: String {
        switch selectedFilter {
        case .today: return "You've completed all tasks for today.\nEnjoy your free time!"
        case .upcoming: return "No upcoming tasks scheduled.\nAdd some for the future."
        case .all: return "Start adding tasks to stay productive."
        case .noDate: return "All your tasks have due dates.\nGreat organization!"
        }
    }
    
    // MARK: - Methods
    
    private func countForFilter(_ filter: TodoFilter) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        switch filter {
        case .today:
            return incompleteTodos.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return calendar.isDateInToday(dueDate) || dueDate < today
            }.count
        case .upcoming:
            return incompleteTodos.filter { todo in
                guard let dueDate = todo.dueDate else { return false }
                return dueDate > today && !calendar.isDateInToday(dueDate)
            }.count
        case .all:
            return incompleteTodos.count
        case .noDate:
            return incompleteTodos.filter { $0.dueDate == nil }.count
        }
    }
    
    private func completeTodo(_ todo: Todo) {
        withAnimation(.spring(response: 0.3)) {
            todo.complete()
            
            // Touch linked project if exists
            if let projectID = todo.linkedProjectID,
               let project = projects.first(where: { $0.id == projectID }) {
                project.touch()
            }
        }
        
        hapticEngine.playSuccess()
        
        // Show confetti for completing tasks
        if todayCompletedCount == 3 || todayCompletedCount == 5 || todayCompletedCount == 10 {
            showConfetti = true
        }
    }
    
    private func uncompleteTodo(_ todo: Todo) {
        withAnimation(.spring(response: 0.3)) {
            todo.uncomplete()
        }
        hapticEngine.playTap()
    }
    
    private func deleteTodo(_ todo: Todo) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(todo)
        }
        hapticEngine.playTap()
    }
}

// MARK: - Todo Filter

enum TodoFilter: CaseIterable {
    case today
    case upcoming
    case all
    case noDate
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .all: return "All"
        case .noDate: return "No Date"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.pulseAccent : Color.white.opacity(0.08))
            )
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Todo Row

struct TodoRow: View {
    let todo: Todo
    let projects: [Project]
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    
    private var linkedProject: Project? {
        guard let projectID = todo.linkedProjectID else { return nil }
        return projects.first { $0.id == projectID }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Complete button
            Button(action: onComplete) {
                Circle()
                    .stroke(todo.priority.color, lineWidth: 2)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .fill(todo.priority.color.opacity(0.2))
                            .frame(width: 18, height: 18)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Due date
                    if let _ = todo.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: todo.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                .font(.system(size: 11))
                            Text(todo.dueDateDisplay)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(todo.isOverdue ? .red : .white.opacity(0.5))
                    }
                    
                    // Linked project
                    if let project = linkedProject {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(project.color)
                                .frame(width: 8, height: 8)
                            Text(project.name)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Carried over badge
                    if todo.isCarriedOver {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 9))
                            Text("\(todo.carriedOverCount)×")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.orange.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Priority indicator
            Image(systemName: todo.priority.icon)
                .font(.system(size: 12))
                .foregroundColor(todo.priority.color.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(todo.isOverdue ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Completed Todo Row

struct CompletedTodoRow: View {
    let todo: Todo
    let onUncomplete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Button(action: onUncomplete) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pulseGreen.opacity(0.6))
            }
            
            Text(todo.title)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
                .strikethrough(true, color: .white.opacity(0.3))
                .lineLimit(1)
            
            Spacer()
            
            if let completedAt = todo.completedAt {
                Text(completedAt, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Preview

#Preview {
    TodoListView()
        .modelContainer(for: [Todo.self, Project.self])
        .environmentObject(HapticEngine.shared)
}
