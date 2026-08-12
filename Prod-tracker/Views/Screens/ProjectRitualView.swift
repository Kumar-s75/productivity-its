//
//  ProjectRitualView.swift
//  Pulse
//
//  Start and end work rituals - mindful transitions into deep work
//

import SwiftUI
import SwiftData
import Combine

struct ProjectRitualView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Properties
    
    let project: Project
    let ritualType: RitualType
    let onComplete: () -> Void
    
    // MARK: - State
    
    @State private var currentStep = 0
    @State private var breathePhase: BreathPhase = .inhale
    @State private var breatheProgress: CGFloat = 0
    @State private var intention: String = ""
    @State private var reflection: String = ""
    @State private var energyRating: Int = 3
    @State private var showCompletion = false
    @State private var animateOrb = false
    
    private let breatheTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    private var steps: [RitualStep] {
        ritualType.steps
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            if showCompletion {
                completionView
            } else {
                // Content
                VStack(spacing: 0) {
                    // Progress dots
                    progressIndicator
                        .padding(.top, 20)
                    
                    // Step content
                    stepContent
                    
                    // Navigation
                    navigationButtons
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateOrb = true
            }
        }
        .onReceive(breatheTimer) { _ in
            if steps[currentStep].type == .breathe {
                updateBreathing()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color.black
            
            // Ambient gradient
            RadialGradient(
                colors: [project.color.opacity(0.3), Color.black],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .scaleEffect(animateOrb ? 1.2 : 0.9)
            
            // Floating particles
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(project.color.opacity(Double.random(in: 0.1...0.3)))
                    .frame(width: CGFloat.random(in: 4...12))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -300...300)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateOrb
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? project.color : Color.white.opacity(0.2))
                    .frame(width: index == currentStep ? 10 : 6, height: index == currentStep ? 10 : 6)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        let step = steps[currentStep]
        
        VStack(spacing: 30) {
            Spacer()
            
            switch step.type {
            case .welcome:
                welcomeContent(step: step)
                
            case .breathe:
                breatheContent(step: step)
                
            case .intention:
                intentionContent(step: step)
                
            case .energy:
                energyContent(step: step)
                
            case .reflection:
                reflectionContent(step: step)
                
            case .gratitude:
                gratitudeContent(step: step)
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Welcome Content
    
    private func welcomeContent(step: RitualStep) -> some View {
        VStack(spacing: 24) {
            // Project orb
            ZStack {
                Circle()
                    .fill(project.color.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateOrb ? 1.1 : 0.9)
                
                Circle()
                    .fill(project.color)
                    .frame(width: 100, height: 100)
                
                Image(systemName: project.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text(step.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(step.subtitle ?? "")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Breathe Content
    
    private func breatheContent(step: RitualStep) -> some View {
        VStack(spacing: 30) {
            Text(step.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            // Breathing circle
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: breatheProgress)
                    .stroke(
                        LinearGradient(
                            colors: [project.color, project.color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Inner breathing circle
                Circle()
                    .fill(project.color.opacity(0.3))
                    .frame(width: breathingCircleSize, height: breathingCircleSize)
                
                // Phase text
                VStack(spacing: 4) {
                    Text(breathePhase.instruction)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(breathePhase.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Text(step.subtitle ?? "")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    private var breathingCircleSize: CGFloat {
        switch breathePhase {
        case .inhale:
            return 80 + (breatheProgress * 60)
        case .hold:
            return 140
        case .exhale:
            return 140 - (breatheProgress * 60)
        }
    }
    
    // MARK: - Intention Content
    
    private func intentionContent(step: RitualStep) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(project.color)
            
            Text(step.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(step.subtitle ?? "")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            TextField("What will you accomplish?", text: $intention, axis: .vertical)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Energy Content
    
    private func energyContent(step: RitualStep) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
            
            Text(step.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            // Energy slider
            VStack(spacing: 16) {
                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            energyRating = level
                            hapticEngine.playTap()
                        } label: {
                            VStack(spacing: 8) {
                                Text(energyEmoji(for: level))
                                    .font(.system(size: 36))
                                    .scaleEffect(energyRating == level ? 1.2 : 1)
                                
                                Text(energyLabel(for: level))
                                    .font(.system(size: 11))
                                    .foregroundColor(energyRating == level ? .white : .white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func energyEmoji(for level: Int) -> String {
        switch level {
        case 1: return "😴"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "🔥"
        default: return "🙂"
        }
    }
    
    private func energyLabel(for level: Int) -> String {
        switch level {
        case 1: return "Low"
        case 2: return "Tired"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "High"
        default: return ""
        }
    }
    
    // MARK: - Reflection Content
    
    private func reflectionContent(step: RitualStep) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(project.color)
            
            Text(step.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(step.subtitle ?? "")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            TextField("What did you accomplish?", text: $reflection, axis: .vertical)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                .lineLimit(3...5)
        }
    }
    
    // MARK: - Gratitude Content
    
    private func gratitudeContent(step: RitualStep) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.pink)
            
            Text(step.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(step.subtitle ?? "")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 20) {
            // Back button
            if currentStep > 0 {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep -= 1
                    }
                    hapticEngine.playTap()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            Spacer()
            
            // Next/Complete button
            Button {
                if currentStep < steps.count - 1 {
                    withAnimation(.spring(response: 0.4)) {
                        currentStep += 1
                    }
                    hapticEngine.playTap()
                } else {
                    completeRitual()
                }
            } label: {
                HStack {
                    Text(currentStep < steps.count - 1 ? "Continue" : "Complete")
                    Image(systemName: currentStep < steps.count - 1 ? "arrow.right" : "checkmark")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(project.color)
                )
            }
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(project.color.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateOrb ? 1.2 : 0.9)
                
                Circle()
                    .fill(project.color)
                    .frame(width: 120, height: 120)
                
                Image(systemName: ritualType == .start ? "play.fill" : "checkmark")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text(ritualType == .start ? "Ready to Begin" : "Session Complete")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(ritualType == .start ? "Time to do great work on \(project.name)" : "Great work on \(project.name) today!")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                onComplete()
                dismiss()
            } label: {
                Text(ritualType == .start ? "Let's Go!" : "Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(project.color)
                    )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Methods
    
    private func updateBreathing() {
        breatheProgress += 0.025
        
        if breatheProgress >= 1 {
            breatheProgress = 0
            
            switch breathePhase {
            case .inhale:
                breathePhase = .hold
            case .hold:
                breathePhase = .exhale
            case .exhale:
                breathePhase = .inhale
            }
            
            hapticEngine.playTap()
        }
    }
    
    private func completeRitual() {
        withAnimation(.spring(response: 0.5)) {
            showCompletion = true
        }
        hapticEngine.playSuccess()
    }
}

// MARK: - Ritual Type

enum RitualType {
    case start
    case end
    
    var steps: [RitualStep] {
        switch self {
        case .start:
            return [
                RitualStep(type: .welcome, title: "Time to Focus", subtitle: "Let's prepare your mind for deep work"),
                RitualStep(type: .breathe, title: "Take 3 Deep Breaths", subtitle: "Clear your mind and center yourself"),
                RitualStep(type: .intention, title: "Set Your Intention", subtitle: "What do you want to accomplish this session?"),
                RitualStep(type: .energy, title: "How's Your Energy?", subtitle: "Being aware helps you work smarter")
            ]
        case .end:
            return [
                RitualStep(type: .welcome, title: "Session Complete", subtitle: "Let's close out mindfully"),
                RitualStep(type: .reflection, title: "Reflect on Your Work", subtitle: "What did you accomplish? What did you learn?"),
                RitualStep(type: .gratitude, title: "Acknowledge Your Effort", subtitle: "You showed up and did the work. That matters."),
                RitualStep(type: .breathe, title: "Transition Out", subtitle: "Take a moment to reset before your next activity")
            ]
        }
    }
}

// MARK: - Ritual Step

struct RitualStep {
    let type: RitualStepType
    let title: String
    let subtitle: String?
}

enum RitualStepType {
    case welcome
    case breathe
    case intention
    case energy
    case reflection
    case gratitude
}

// MARK: - Breathe Phase

enum BreathPhase: String {
    case inhale = "Inhale"
    case hold = "Hold"
    case exhale = "Exhale"
    
    var instruction: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
}

// MARK: - Preview

#Preview {
    ProjectRitualView(
        project: Project(name: "Pulse App", colorHex: "#6366F1", iconName: "heart.fill"),
        ritualType: .start,
        onComplete: {}
    )
    .environmentObject(HapticEngine.shared)
}
