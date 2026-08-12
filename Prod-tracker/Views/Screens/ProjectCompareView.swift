//
//  ProjectCompareView.swift
//  Pulse
//
//  Side-by-side project comparison with beautiful visualizations
//

import SwiftUI
import SwiftData

struct ProjectCompareView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var project1: Project?
    @State private var project2: Project?
    @State private var showProjectPicker1 = false
    @State private var showProjectPicker2 = false
    @State private var animateComparison = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                if project1 == nil || project2 == nil {
                    selectionView
                } else {
                    comparisonView
                }
            }
            .navigationTitle("Compare")
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
                
                if project1 != nil && project2 != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Reset") {
                            withAnimation {
                                project1 = nil
                                project2 = nil
                                animateComparison = false
                            }
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showProjectPicker1) {
                projectPickerSheet(for: 1)
            }
            .sheet(isPresented: $showProjectPicker2) {
                projectPickerSheet(for: 2)
            }
        }
    }
    
    // MARK: - Selection View
    
    private var selectionView: some View {
        VStack(spacing: 30) {
            Text("Select Two Projects")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Compare health, activity, and progress")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 20) {
                // Project 1 selector
                projectSelector(project: project1, index: 1) {
                    showProjectPicker1 = true
                }
                
                // VS
                Text("VS")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                
                // Project 2 selector
                projectSelector(project: project2, index: 2) {
                    showProjectPicker2 = true
                }
            }
            
            if project1 != nil && project2 != nil {
                Button {
                    withAnimation(.spring(response: 0.6)) {
                        animateComparison = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Compare")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color.pulseAccent)
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
    }
    
    private func projectSelector(project: Project?, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let project = project {
                    // Selected project
                    ZStack {
                        Circle()
                            .fill(project.color.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(project.color)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: project.iconName)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Text(project.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                } else {
                    // Empty slot
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("Project \(index)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 120)
        }
    }
    
    // MARK: - Comparison View
    
    private var comparisonView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Project headers
                projectHeaders
                
                // Health comparison
                comparisonSection(title: "Health Score") {
                    healthComparison
                }
                
                // Stats comparison
                comparisonSection(title: "Activity") {
                    activityComparison
                }
                
                // Streak comparison
                comparisonSection(title: "Consistency") {
                    streakComparison
                }
                
                // Time invested
                comparisonSection(title: "Time Invested") {
                    timeComparison
                }
                
                // Radar chart
                comparisonSection(title: "Overall Profile") {
                    radarComparison
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animateComparison = true
            }
        }
    }
    
    // MARK: - Project Headers
    
    private var projectHeaders: some View {
        HStack {
            if let p1 = project1 {
                projectHeader(project: p1)
            }
            
            Spacer()
            
            if let p2 = project2 {
                projectHeader(project: p2)
            }
        }
    }
    
    private func projectHeader(project: Project) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(project.color)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: project.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
            
            Text(project.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
    
    // MARK: - Health Comparison
    
    private var healthComparison: some View {
        HStack {
            if let p1 = project1, let p2 = project2 {
                // Project 1 health
                healthGauge(project: p1)
                
                Spacer()
                
                // Winner indicator
                VStack {
                    let score1 = healthScore(for: p1)
                    let score2 = healthScore(for: p2)
                    let winner: Project? = score1 > score2 ? p1 : (score1 < score2 ? p2 : nil)
                    
                    if let winner = winner {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text(winner.name)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("TIE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(width: 60)
                
                Spacer()
                
                // Project 2 health
                healthGauge(project: p2)
            }
        }
    }
    
    private func healthScore(for project: Project) -> Int {
        switch project.healthLevel {
        case .healthy: return 100
        case .needsAttention: return 70
        case .critical: return 40
        case .dying: return 20
        case .dead: return 0
        }
    }
    
    private func healthGauge(project: Project) -> some View {
        let score = healthScore(for: project)
        
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: animateComparison ? CGFloat(score) / 100 : 0)
                    .stroke(project.healthLevel.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(project.healthLevel.rawValue)
                .font(.system(size: 12))
                .foregroundColor(project.healthLevel.color)
        }
    }
    
    // MARK: - Activity Comparison
    
    private var activityComparison: some View {
        VStack(spacing: 16) {
            if let p1 = project1, let p2 = project2 {
                comparisonBar(
                    label: "Total Sessions",
                    value1: p1.pulseEntries?.count ?? 0,
                    value2: p2.pulseEntries?.count ?? 0,
                    color1: p1.color,
                    color2: p2.color
                )
                
                comparisonBar(
                    label: "Milestones",
                    value1: p1.milestones?.filter { $0.isCompleted }.count ?? 0,
                    value2: p2.milestones?.filter { $0.isCompleted }.count ?? 0,
                    color1: p1.color,
                    color2: p2.color
                )
            }
        }
    }
    
    // MARK: - Streak Comparison
    
    private var streakComparison: some View {
        HStack(spacing: 20) {
            if let p1 = project1, let p2 = project2 {
                streakCard(project: p1)
                streakCard(project: p2)
            }
        }
    }
    
    private func streakCard(project: Project) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(project.currentStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text("Current Streak")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text("\(project.longestStreak) best")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(project.color.opacity(0.15))
        )
    }
    
    // MARK: - Time Comparison
    
    private var timeComparison: some View {
        VStack(spacing: 16) {
            if let p1 = project1, let p2 = project2 {
                let entries1 = p1.pulseEntries ?? []
                let entries2 = p2.pulseEntries ?? []
                let time1 = entries1.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
                let time2 = entries2.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
                let maxTime = max(time1, time2, 1)
                
                HStack(alignment: .bottom, spacing: 40) {
                    // Project 1 bar
                    VStack(spacing: 8) {
                        Text("\(time1 / 60)h \(time1 % 60)m")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(p1.color)
                            .frame(width: 60, height: animateComparison ? CGFloat(time1) / CGFloat(maxTime) * 150 : 0)
                    }
                    
                    // Project 2 bar
                    VStack(spacing: 8) {
                        Text("\(time2 / 60)h \(time2 % 60)m")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(p2.color)
                            .frame(width: 60, height: animateComparison ? CGFloat(time2) / CGFloat(maxTime) * 150 : 0)
                    }
                }
                .frame(height: 180)
            }
        }
    }
    
    // MARK: - Radar Comparison
    
    private var radarComparison: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius: CGFloat = min(geometry.size.width, geometry.size.height) / 2 - 30
            
            ZStack {
                // Background web
                ForEach(1...4, id: \.self) { ring in
                    radarWeb(center: center, radius: radius * CGFloat(ring) / 4)
                }
                
                // Axis labels
                radarLabels(center: center, radius: radius)
                
                // Project 1 shape
                if let p1 = project1 {
                    radarShape(
                        center: center,
                        radius: radius,
                        values: projectRadarValues(p1),
                        color: p1.color
                    )
                    .opacity(animateComparison ? 0.6 : 0)
                }
                
                // Project 2 shape
                if let p2 = project2 {
                    radarShape(
                        center: center,
                        radius: radius,
                        values: projectRadarValues(p2),
                        color: p2.color
                    )
                    .opacity(animateComparison ? 0.6 : 0)
                }
            }
        }
        .frame(height: 250)
    }
    
    private func radarWeb(center: CGPoint, radius: CGFloat) -> some View {
        Path { path in
            let dimensions = 5
            for i in 0..<dimensions {
                let angle = (Double(i) / Double(dimensions)) * 2 * .pi - .pi / 2
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        .stroke(Color.white.opacity(0.1), lineWidth: 1)
    }
    
    private func radarLabels(center: CGPoint, radius: CGFloat) -> some View {
        let labels = ["Health", "Streak", "Activity", "Time", "Milestones"]
        
        return ForEach(0..<5, id: \.self) { i in
            let angle = (Double(i) / 5.0) * 2 * .pi - .pi / 2
            let labelRadius = radius + 20
            
            Text(labels[i])
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
                .position(
                    x: center.x + CGFloat(cos(angle)) * labelRadius,
                    y: center.y + CGFloat(sin(angle)) * labelRadius
                )
        }
    }
    
    private func radarShape(center: CGPoint, radius: CGFloat, values: [Double], color: Color) -> some View {
        let fillPath = createRadarPath(center: center, radius: radius, values: values)
        let strokePath = createRadarPath(center: center, radius: radius, values: values)
        
        return ZStack {
            fillPath
                .fill(color.opacity(0.3))
            
            strokePath
                .stroke(color, lineWidth: 2)
        }
    }
    
    private func createRadarPath(center: CGPoint, radius: CGFloat, values: [Double]) -> Path {
        Path { path in
            for (i, value) in values.enumerated() {
                let angle = (Double(i) / Double(values.count)) * 2 * .pi - .pi / 2
                let r = radius * CGFloat(value)
                let x = center.x + CGFloat(cos(angle)) * r
                let y = center.y + CGFloat(sin(angle)) * r
                let point = CGPoint(x: x, y: y)
                
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
    
    private func projectRadarValues(_ project: Project) -> [Double] {
        let health = Double(healthScore(for: project)) / 100
        let streak = min(1.0, Double(project.currentStreak) / 30)
        let activity = min(1.0, Double(project.pulseEntries?.count ?? 0) / 50)
        let entries = project.pulseEntries ?? []
        let totalMinutes = entries.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
        let time = min(1.0, Double(totalMinutes) / 3000)
        let milestones = min(1.0, Double(project.milestones?.filter { $0.isCompleted }.count ?? 0) / 10)
        
        return [health, streak, activity, time, milestones]
    }
    
    // MARK: - Helper Views
    
    private func comparisonSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func comparisonBar(label: String, value1: Int, value2: Int, color1: Color, color2: Color) -> some View {
        let maxValue = max(value1, value2, 1)
        
        return VStack(spacing: 8) {
            HStack {
                Text("\(value1)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color1)
                
                Spacer()
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text("\(value2)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color2)
            }
            
            GeometryReader { geometry in
                HStack(spacing: 4) {
                    // Bar 1 (right aligned)
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color1)
                            .frame(width: animateComparison ? (geometry.size.width / 2 - 2) * CGFloat(value1) / CGFloat(maxValue) : 0)
                    }
                    .frame(width: geometry.size.width / 2 - 2)
                    
                    // Bar 2 (left aligned)
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color2)
                            .frame(width: animateComparison ? (geometry.size.width / 2 - 2) * CGFloat(value2) / CGFloat(maxValue) : 0)
                        Spacer()
                    }
                    .frame(width: geometry.size.width / 2 - 2)
                }
            }
            .frame(height: 20)
        }
    }
    
    // MARK: - Project Picker Sheet
    
    private func projectPickerSheet(for index: Int) -> some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(activeProjects.filter { project in
                            if index == 1 {
                                return project.id != project2?.id
                            } else {
                                return project.id != project1?.id
                            }
                        }) { project in
                            Button {
                                if index == 1 {
                                    project1 = project
                                    showProjectPicker1 = false
                                } else {
                                    project2 = project
                                    showProjectPicker2 = false
                                }
                                hapticEngine.playTap()
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(project.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: project.iconName)
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text(project.healthLevel.rawValue)
                                            .font(.system(size: 12))
                                            .foregroundColor(project.healthLevel.color)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if index == 1 {
                            showProjectPicker1 = false
                        } else {
                            showProjectPicker2 = false
                        }
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectCompareView()
        .modelContainer(for: Project.self)
        .environmentObject(HapticEngine.shared)
}
