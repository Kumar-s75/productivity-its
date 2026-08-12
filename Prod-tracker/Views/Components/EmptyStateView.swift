//
//  EmptyStateView.swift
//  Pulse
//
//  Beautiful empty state illustrations and messages
//

import SwiftUI

struct EmptyStateView: View {
    
    let type: EmptyStateType
    var action: (() -> Void)? = nil
    
    @State private var animateIllustration = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            illustration
                .frame(width: 200, height: 200)
            
            // Text content
            VStack(spacing: 10) {
                Text(type.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(type.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            
            // Action button
            if let action = action, let buttonTitle = type.buttonTitle {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if let icon = type.buttonIcon {
                            Image(systemName: icon)
                        }
                        Text(buttonTitle)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [type.accentColor, type.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: type.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateIllustration = true
            }
        }
    }
    
    // MARK: - Illustration
    
    @ViewBuilder
    private var illustration: some View {
        switch type {
        case .noProjects:
            NoProjectsIllustration(animate: animateIllustration)
        case .noTodos:
            NoTodosIllustration(animate: animateIllustration)
        case .noArchived:
            NoArchivedIllustration(animate: animateIllustration)
        case .allHealthy:
            AllHealthyIllustration(animate: animateIllustration)
        case .noActivity:
            NoActivityIllustration(animate: animateIllustration)
        case .searchNoResults:
            SearchNoResultsIllustration(animate: animateIllustration)
        case .noAchievements:
            NoAchievementsIllustration(animate: animateIllustration)
        }
    }
}

// MARK: - Empty State Type

enum EmptyStateType {
    case noProjects
    case noTodos
    case noArchived
    case allHealthy
    case noActivity
    case searchNoResults
    case noAchievements
    
    var title: String {
        switch self {
        case .noProjects: return "No Projects Yet"
        case .noTodos: return "All Clear! 🎉"
        case .noArchived: return "Nothing Archived"
        case .allHealthy: return "Everything's Thriving!"
        case .noActivity: return "No Activity"
        case .searchNoResults: return "No Results"
        case .noAchievements: return "Start Earning!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .noProjects: return "Give life to your first project. Watch it grow as you nurture it with consistent work."
        case .noTodos: return "You've completed everything for today. Time to relax or add new tasks."
        case .noArchived: return "Projects you hibernate or complete will appear here."
        case .allHealthy: return "All your projects have a strong pulse. Keep up the great work!"
        case .noActivity: return "Start working on your projects to see your activity map light up."
        case .searchNoResults: return "Try adjusting your search or filters to find what you're looking for."
        case .noAchievements: return "Complete tasks and maintain streaks to unlock achievements."
        }
    }
    
    var buttonTitle: String? {
        switch self {
        case .noProjects: return "Create Project"
        case .noTodos: return "Add Task"
        case .noArchived: return nil
        case .allHealthy: return nil
        case .noActivity: return "Touch a Project"
        case .searchNoResults: return "Clear Search"
        case .noAchievements: return nil
        }
    }
    
    var buttonIcon: String? {
        switch self {
        case .noProjects: return "plus"
        case .noTodos: return "plus"
        case .noActivity: return "hand.tap"
        case .searchNoResults: return "xmark"
        default: return nil
        }
    }
    
    var accentColor: Color {
        switch self {
        case .noProjects: return .pulseAccent
        case .noTodos: return .pulseGreen
        case .noArchived: return .gray
        case .allHealthy: return .pulseGreen
        case .noActivity: return .pulseAccent
        case .searchNoResults: return .orange
        case .noAchievements: return .pulseYellow
        }
    }
}

// MARK: - Illustrations

struct NoProjectsIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseAccent.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .scaleEffect(animate ? 1.1 : 0.9)
            
            // Dashed circle (project outline)
            Circle()
                .stroke(Color.pulseAccent.opacity(0.5), style: StrokeStyle(lineWidth: 3, dash: [8, 8]))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animate)
            
            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.pulseAccent.opacity(0.7))
                .scaleEffect(animate ? 1.1 : 1.0)
            
            // Floating particles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.pulseAccent.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(Double(index) * .pi * 2 / 3) * 70,
                        y: sin(Double(index) * .pi * 2 / 3) * 70
                    )
                    .offset(y: animate ? -5 : 5)
                    .animation(.easeInOut(duration: 1.5).delay(Double(index) * 0.3).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

struct NoTodosIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Celebration glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseGreen.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .scaleEffect(animate ? 1.15 : 0.95)
            
            // Checkmark circle
            Circle()
                .fill(Color.pulseGreen.opacity(0.2))
                .frame(width: 90, height: 90)
            
            Circle()
                .stroke(Color.pulseGreen, lineWidth: 3)
                .frame(width: 90, height: 90)
            
            // Animated checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.pulseGreen)
                .scaleEffect(animate ? 1.1 : 1.0)
            
            // Sparkles
            ForEach(0..<5, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / 5 + .pi/4
                let xOffset = cos(angle) * 65
                let yOffset = sin(angle) * 65
                let delay = Double(index) * 0.15
                
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundColor(.pulseYellow)
                    .offset(x: xOffset, y: yOffset)
                    .scaleEffect(animate ? 1.3 : 0.8)
                    .opacity(animate ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.8).delay(delay).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

struct NoArchivedIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gray.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
            
            // Archive box
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 80, height: 60)
                .offset(y: 10)
            
            // Lid
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 90, height: 15)
                .offset(y: -25)
                .rotationEffect(.degrees(animate ? -5 : 5), anchor: .leading)
            
            // Folder icon
            Image(systemName: "archivebox")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.6))
                .offset(y: 15)
        }
    }
}

struct AllHealthyIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseGreen.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .scaleEffect(animate ? 1.2 : 1.0)
            
            // Pulse rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.pulseGreen.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: 60 + CGFloat(index * 30), height: 60 + CGFloat(index * 30))
                    .scaleEffect(animate ? 1.1 : 0.95)
                    .animation(.easeInOut(duration: 1.2).delay(Double(index) * 0.2).repeatForever(autoreverses: true), value: animate)
            }
            
            // Heart
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.pulseGreen)
                .scaleEffect(animate ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)
        }
    }
}

struct NoActivityIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseAccent.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
            
            // Grid pattern
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<5, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            
            // Touch indicator
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 30))
                .foregroundColor(.pulseAccent.opacity(0.7))
                .offset(y: animate ? -5 : 5)
        }
    }
}

struct SearchNoResultsIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
            
            // Magnifying glass
            Circle()
                .stroke(Color.orange.opacity(0.6), lineWidth: 4)
                .frame(width: 60, height: 60)
                .offset(x: -10, y: -10)
            
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.orange.opacity(0.6))
                .frame(width: 30, height: 8)
                .rotationEffect(.degrees(45))
                .offset(x: 25, y: 25)
            
            // Question mark
            Text("?")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.orange.opacity(0.5))
                .offset(x: -10, y: -10)
                .scaleEffect(animate ? 1.1 : 0.9)
        }
    }
}

struct NoAchievementsIllustration: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseYellow.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
            
            // Trophy
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(.pulseYellow.opacity(0.4))
                .overlay(
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pulseYellow.opacity(0.6), Color.pulseYellow.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            Rectangle()
                                .frame(height: animate ? 60 : 20)
                                .offset(y: animate ? 0 : 20)
                        )
                )
            
            // Stars
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.pulseYellow.opacity(0.6))
                    .offset(
                        x: CGFloat(index - 1) * 40,
                        y: -50
                    )
                    .scaleEffect(animate ? 1 : 0.7)
                    .opacity(animate ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.2).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.pulseBackground.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 60) {
                EmptyStateView(type: .noProjects) {}
                EmptyStateView(type: .noTodos) {}
                EmptyStateView(type: .allHealthy)
                EmptyStateView(type: .noAchievements)
            }
            .padding(.vertical, 40)
        }
    }
}
