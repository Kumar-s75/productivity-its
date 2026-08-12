//
//  SearchView.swift
//  Pulse
//
//  Powerful search and filter interface
//

import SwiftUI
import SwiftData

struct SearchView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    @Query private var allTodos: [Todo]
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var showingFilters = false
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - Computed
    
    private var filteredProjects: [Project] {
        guard !searchText.isEmpty else { return [] }
        
        let lowercased = searchText.lowercased()
        
        return activeProjects.filter { project in
            project.name.lowercased().contains(lowercased) ||
            project.projectDescription.lowercased().contains(lowercased)
        }
    }
    
    private var filteredTodos: [Todo] {
        guard !searchText.isEmpty else { return [] }
        
        let lowercased = searchText.lowercased()
        
        return allTodos.filter { todo in
            todo.title.lowercased().contains(lowercased) ||
            todo.notes.lowercased().contains(lowercased)
        }
    }
    
    private var recentSearches: [String] {
        UserDefaults.standard.stringArray(forKey: "pulse.recentSearches") ?? []
    }
    
    private var healthyProjects: [Project] {
        activeProjects.filter { $0.healthLevel == .healthy }
    }
    
    private var needsAttentionProjects: [Project] {
        activeProjects.filter { $0.healthLevel == .needsAttention || $0.healthLevel == .critical }
    }
    
    private var dyingProjects: [Project] {
        activeProjects.filter { $0.healthLevel == .dying || $0.healthLevel == .dead }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Content
                    if searchText.isEmpty {
                        emptySearchContent
                    } else {
                        searchResults
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search projects and tasks...", text: $searchText)
                    .foregroundColor(.white)
                    .tint(.pulseAccent)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        saveRecentSearch(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        hapticEngine.playTap()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Filter button
            Button {
                showingFilters.toggle()
                hapticEngine.playTap()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(showingFilters ? .pulseAccent : .white.opacity(0.6))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(showingFilters ? Color.pulseAccent.opacity(0.2) : Color.white.opacity(0.1))
                    )
            }
        }
        .padding()
    }
    
    // MARK: - Empty Search Content
    
    private var emptySearchContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick filters
                quickFiltersSection
                
                // Recent searches
                if !recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Health overview
                healthOverviewSection
            }
            .padding()
        }
    }
    
    // MARK: - Quick Filters Section
    
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Filters")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                QuickFilterCard(
                    icon: "heart.fill",
                    title: "Healthy",
                    count: healthyProjects.count,
                    color: .pulseGreen
                ) {
                    searchText = "health:healthy"
                }
                
                QuickFilterCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Needs Attention",
                    count: needsAttentionProjects.count,
                    color: .pulseYellow
                ) {
                    searchText = "health:attention"
                }
                
                QuickFilterCard(
                    icon: "flame.fill",
                    title: "Has Streak",
                    count: activeProjects.filter { $0.currentStreak > 0 }.count,
                    color: .orange
                ) {
                    searchText = "streak:active"
                }
                
                QuickFilterCard(
                    icon: "heart.slash.fill",
                    title: "Dying",
                    count: dyingProjects.count,
                    color: .red
                ) {
                    searchText = "health:dying"
                }
            }
        }
    }
    
    // MARK: - Recent Searches Section
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Button("Clear") {
                    clearRecentSearches()
                }
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            }
            
            FlowLayout(spacing: 8) {
                ForEach(recentSearches, id: \.self) { search in
                    Button {
                        searchText = search
                        hapticEngine.playTap()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12))
                            Text(search)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Health Overview Section
    
    private var healthOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Overview")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 12) {
                HealthBar(label: "Healthy", value: healthyProjects.count, total: activeProjects.count, color: .pulseGreen)
                HealthBar(label: "Attention", value: needsAttentionProjects.count, total: activeProjects.count, color: .pulseYellow)
                HealthBar(label: "Critical", value: dyingProjects.count, total: activeProjects.count, color: .red)
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Projects section
                if !filteredProjects.isEmpty {
                    Section {
                        ForEach(filteredProjects) { project in
                            SearchProjectRow(project: project) {
                                appState.navigateToProject(project.id)
                                dismiss()
                            }
                        }
                    } header: {
                        SectionHeaderView(title: "Projects", count: filteredProjects.count)
                    }
                }
                
                // Todos section
                if !filteredTodos.isEmpty {
                    Section {
                        ForEach(filteredTodos) { todo in
                            SearchTodoRow(todo: todo)
                        }
                    } header: {
                        SectionHeaderView(title: "Tasks", count: filteredTodos.count)
                    }
                }
                
                // No results
                if filteredProjects.isEmpty && filteredTodos.isEmpty {
                    noResultsView
                }
            }
            .padding()
        }
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.2))
            
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Methods
    
    private func saveRecentSearch(_ text: String) {
        guard !text.isEmpty else { return }
        
        var searches = recentSearches
        searches.removeAll { $0 == text }
        searches.insert(text, at: 0)
        searches = Array(searches.prefix(5))
        
        UserDefaults.standard.set(searches, forKey: "pulse.recentSearches")
    }
    
    private func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: "pulse.recentSearches")
        hapticEngine.playTap()
    }
}

// MARK: - Search Filter

enum SearchFilter: CaseIterable {
    case all
    case projects
    case todos
    case tags
    
    var title: String {
        switch self {
        case .all: return "All"
        case .projects: return "Projects"
        case .todos: return "Tasks"
        case .tags: return "Tags"
        }
    }
}

// MARK: - Quick Filter Card

struct QuickFilterCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(count) projects")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Health Bar

struct HealthBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(height: geometry.size.height * percentage)
                }
            }
            .frame(width: 8, height: 40)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header View

struct SectionHeaderView: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Text("(\(count))")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
        }
    }
}

// MARK: - Search Project Row

struct SearchProjectRow: View {
    let project: Project
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Project orb
                ZStack {
                    Circle()
                        .fill(project.color.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(project.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Health indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(project.healthLevel.color)
                                .frame(width: 8, height: 8)
                            
                            Text(project.healthLevel.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        // Streak
                        if project.currentStreak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                Text("\(project.currentStreak)")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
}

// MARK: - Search Todo Row

struct SearchTodoRow: View {
    let todo: Todo
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(todo.isCompleted ? .pulseGreen : todo.priority.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(todo.isCompleted ? .white.opacity(0.4) : .white)
                    .strikethrough(todo.isCompleted)
                
                if let dueDate = todo.dueDate {
                    Text(dueDate, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(todo.isOverdue ? .red : .white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .modelContainer(for: [Project.self, Todo.self])
        .environmentObject(HapticEngine.shared)
        .environmentObject(AppState.shared)
}
