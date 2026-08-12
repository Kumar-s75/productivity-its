//
//  YearInReviewView.swift
//  Pulse
//
//  Beautiful animated year-in-review like Spotify Wrapped
//

import SwiftUI
import SwiftData

struct YearInReviewView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query private var projects: [Project]
    @Query private var pulseEntries: [PulseEntry]
    @Query private var todos: [Todo]
    
    // MARK: - State
    
    @State private var currentSlide = 0
    @State private var animateContent = false
    
    private let slides = 7
    
    // MARK: - Computed Stats
    
    private var totalProjects: Int {
        projects.count
    }
    
    private var totalPulses: Int {
        pulseEntries.count
    }
    
    private var totalMinutes: Int {
        pulseEntries.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }
    
    private var totalHours: Int {
        totalMinutes / 60
    }
    
    private var longestStreak: Int {
        projects.map { $0.longestStreak }.max() ?? 0
    }
    
    private var completedProjects: Int {
        projects.filter { $0.archivedAt != nil && $0.archiveReason == .some(.shipped) }.count
    }
    
    private var completedTodos: Int {
        todos.filter { $0.completedAt != nil }.count
    }
    
    private var topProject: Project? {
        projects.max { ($0.pulseEntries?.count ?? 0) < ($1.pulseEntries?.count ?? 0) }
    }
    
    private var mostProductiveMonth: String {
        // Simplified - would need proper calculation
        "March"
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Dynamic background
            backgroundGradient
            
            // Content
            TabView(selection: $currentSlide) {
                // Slide 1: Opening
                openingSlide.tag(0)
                
                // Slide 2: Total Projects
                projectsSlide.tag(1)
                
                // Slide 3: Time Invested
                timeSlide.tag(2)
                
                // Slide 4: Longest Streak
                streakSlide.tag(3)
                
                // Slide 5: Top Project
                topProjectSlide.tag(4)
                
                // Slide 6: Achievements
                achievementsSlide.tag(5)
                
                // Slide 7: Summary
                summarySlide.tag(6)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Navigation overlay
            VStack {
                // Close button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    
                    Spacer()
                    
                    // Slide indicator
                    Text("\(currentSlide + 1)/\(slides)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                
                Spacer()
                
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<slides, id: \.self) { index in
                        Capsule()
                            .fill(index == currentSlide ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentSlide ? 20 : 8, height: 4)
                            .animation(.spring(response: 0.3), value: currentSlide)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onChange(of: currentSlide) { _, _ in
            hapticEngine.playTap()
            animateContent = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6)) {
                    animateContent = true
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.3)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        let colors: [Color] = {
            switch currentSlide {
            case 0: return [.purple, .indigo, Color(hex: "#0A0A0F")!]
            case 1: return [.blue, .cyan, Color(hex: "#0A0A0F")!]
            case 2: return [.orange, .red, Color(hex: "#0A0A0F")!]
            case 3: return [.yellow, .orange, Color(hex: "#0A0A0F")!]
            case 4: return [topProject?.color ?? .pulseAccent, .purple, Color(hex: "#0A0A0F")!]
            case 5: return [.green, .teal, Color(hex: "#0A0A0F")!]
            case 6: return [.pulseAccent, .purple, Color(hex: "#0A0A0F")!]
            default: return [.pulseAccent, .purple, Color(hex: "#0A0A0F")!]
            }
        }()
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentSlide)
    }
    
    // MARK: - Slides
    
    private var openingSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated orbs
            ZStack {
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(Double(i) * 0.1), value: animateContent)
                }
                
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .scaleEffect(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.5), value: animateContent)
            }
            
            VStack(spacing: 16) {
                Text("Your Year")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("In Pulse")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text(String(Calendar.current.component(.year, from: Date())))
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
            }
            .animation(.spring(response: 0.6).delay(0.3), value: animateContent)
            
            Spacer()
            
            Text("Swipe to explore →")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .opacity(animateContent ? 1 : 0)
                .animation(.easeIn.delay(1), value: animateContent)
        }
        .padding()
    }
    
    private var projectsSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("You brought")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .opacity(animateContent ? 1 : 0)
            
            Text("\(totalProjects)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animateContent ? 1 : 0.5)
                .opacity(animateContent ? 1 : 0)
            
            Text("projects to life")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .opacity(animateContent ? 1 : 0)
            
            // Mini orbs representing projects
            HStack(spacing: 8) {
                ForEach(projects.prefix(7)) { project in
                    Circle()
                        .fill(project.color)
                        .frame(width: 30, height: 30)
                        .shadow(color: project.color.opacity(0.5), radius: 5)
                }
            }
            .padding(.top, 20)
            .opacity(animateContent ? 1 : 0)
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
    
    private var timeSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("You invested")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(totalHours)")
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("hours")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .scaleEffect(animateContent ? 1 : 0.5)
            .opacity(animateContent ? 1 : 0)
            
            Text("into your projects")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            // Visual representation
            VStack(spacing: 8) {
                Text("That's \(totalPulses) work sessions!")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                
                // Progress representation
                HStack(spacing: 2) {
                    ForEach(0..<min(totalPulses, 30), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 6, height: 20)
                            .cornerRadius(2)
                    }
                }
            }
            .padding(.top, 20)
            .opacity(animateContent ? 1 : 0)
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
    
    private var streakSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Fire animation
            ZStack {
                ForEach(0..<3) { i in
                    Image(systemName: "flame.fill")
                        .font(.system(size: 80 - CGFloat(i * 15)))
                        .foregroundColor(.orange.opacity(1 - Double(i) * 0.2))
                        .offset(y: CGFloat(i * 10))
                }
            }
            .scaleEffect(animateContent ? 1 : 0.5)
            .opacity(animateContent ? 1 : 0)
            
            Text("Your longest streak")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("\(longestStreak)")
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("days")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .scaleEffect(animateContent ? 1 : 0.5)
            .opacity(animateContent ? 1 : 0)
            
            if longestStreak >= 7 {
                Text("That's dedication! 🔥")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
    
    private var topProjectSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your #1 project")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .opacity(animateContent ? 1 : 0)
            
            if let project = topProject {
                // Large orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [project.color.opacity(0.5), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 30)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [project.color, project.color.opacity(0.7)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: project.color.opacity(0.5), radius: 30)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateContent ? 1 : 0.5)
                .opacity(animateContent ? 1 : 0)
                
                Text(project.name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                
                Text("\(project.pulseEntries?.count ?? 0) sessions • \(project.currentStreak) day streak")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .opacity(animateContent ? 1 : 0)
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
    
    private var achievementsSlide: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .scaleEffect(animateContent ? 1 : 0.5)
                .opacity(animateContent ? 1 : 0)
            
            Text("You completed")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(completedTodos)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animateContent ? 1 : 0.5)
                .opacity(animateContent ? 1 : 0)
            
            Text("tasks this year")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            if completedProjects > 0 {
                Text("and shipped \(completedProjects) projects! 🚀")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
    
    private var summarySlide: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Your \(String(Calendar.current.component(.year, from: Date()))) Summary")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(animateContent ? 1 : 0)
            
            // Summary grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                YearSummaryCard(icon: "folder.fill", value: "\(totalProjects)", label: "Projects", color: .blue)
                YearSummaryCard(icon: "clock.fill", value: "\(totalHours)h", label: "Invested", color: .orange)
                YearSummaryCard(icon: "flame.fill", value: "\(longestStreak)d", label: "Best Streak", color: .yellow)
                YearSummaryCard(icon: "checkmark.circle.fill", value: "\(completedTodos)", label: "Tasks Done", color: .green)
            }
            .padding()
            .opacity(animateContent ? 1 : 0)
            
            Spacer()
            
            // Share button
            Button {
                // Share functionality
                hapticEngine.playSuccess()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share My Year")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.pulseAccent)
                .padding(.horizontal, 30)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
            }
            .opacity(animateContent ? 1 : 0)
            
            Text("Here's to an even better \(String(Calendar.current.component(.year, from: Date()) + 1))!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 10)
                .opacity(animateContent ? 1 : 0)
            
            Spacer()
        }
        .animation(.spring(response: 0.6), value: animateContent)
    }
}

// MARK: - Summary Card

struct YearSummaryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    YearInReviewView()
        .modelContainer(for: [Project.self, PulseEntry.self, Todo.self])
        .environmentObject(HapticEngine.shared)
}
