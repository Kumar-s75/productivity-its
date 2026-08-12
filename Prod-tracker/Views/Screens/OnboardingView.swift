//
//  OnboardingView.swift
//  Pulse
//
//  Interactive 6-page onboarding with haptics, animations, and first-project creation
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Floating Particle

struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var color: Color
}

// MARK: - Onboarding View

struct OnboardingView: View {

    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine

    @State private var currentPage = 0
    @State private var particles: [FloatingParticle] = []
    @State private var particleTimer: Timer?
    @State private var bgAnimating = false

    private let totalPages = 6

    private var pageColors: [Color] {
        [.pulseAccent, .pulseGreen, .pulseYellow, .pulseOrange, .cyan, .pulseAccent]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Deep background
            Color.pulseBackground.ignoresSafeArea()

            // Animated ambient gradient
            ambientGradient

            // Floating particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .blur(radius: particle.size * 0.3)
                    .allowsHitTesting(false)
            }

            // Pages
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.horizontal, 28)
                    .padding(.top, 60)

                // Page content via TabView
                TabView(selection: $currentPage) {
                    OBPage1(onTap: {
                        hapticEngine.playHealthyPulse()
                    })
                    .tag(0)

                    OBPage2()
                    .tag(1)

                    OBPage3()
                    .tag(2)

                    OBPage4()
                    .tag(3)

                    OBPage5()
                    .tag(4)

                    OBPage6(onComplete: { name, colorHex in
                        createFirstProject(name: name, colorHex: colorHex)
                    })
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)

                // Bottom navigation
                bottomNav
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
            }
        }
        .onAppear {
            spawnParticles()
        }
        .onDisappear {
            particleTimer?.invalidate()
        }
        .onChange(of: currentPage) { _, _ in
            hapticEngine.playSelection()
        }
    }

    // MARK: - Ambient Gradient

    private var ambientGradient: some View {
        let color = pageColors[min(currentPage, pageColors.count - 1)]
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.25), Color.clear],
                        center: .center, startRadius: 0, endRadius: 340
                    )
                )
                .frame(width: 500, height: 500)
                .offset(x: -80, y: -220)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 0.8), value: currentPage)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.15), Color.clear],
                        center: .center, startRadius: 0, endRadius: 280
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: 140, y: 340)
                .blur(radius: 50)
                .animation(.easeInOut(duration: 0.8).delay(0.1), value: currentPage)
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(
                        index <= currentPage
                            ? pageColors[min(currentPage, pageColors.count - 1)]
                            : Color.white.opacity(0.15)
                    )
                    .frame(height: 4)
                    .frame(maxWidth: index == currentPage ? .infinity : 28)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNav: some View {
        HStack {
            // Skip (not on last page)
            if currentPage < totalPages - 1 {
                Button("Skip") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hapticEngine.playTap()
                        completeOnboarding(projectName: nil, colorHex: nil)
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
            } else {
                Spacer().frame(width: 48)
            }

            Spacer()

            // Continue / Get Started (not shown on last page — last page has its own button)
            if currentPage < totalPages - 1 {
                Button {
                    hapticEngine.playTap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(pageColors[min(currentPage, pageColors.count - 1)])
                            .shadow(color: pageColors[min(currentPage, pageColors.count - 1)].opacity(0.4), radius: 14, x: 0, y: 6)
                    )
                }
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - Helpers

    private func spawnParticles() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        let colors: [Color] = [.pulseAccent, .pulseGreen, .cyan, .pulseYellow, .purple]
        particles = (0..<18).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0...screenW),
                y: CGFloat.random(in: 0...screenH),
                size: CGFloat.random(in: 4...14),
                opacity: Double.random(in: 0.04...0.18),
                speed: Double.random(in: 6...14),
                color: colors.randomElement() ?? .pulseAccent
            )
        }

        // Drift particles upward
        particleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                for i in particles.indices {
                    particles[i].y -= CGFloat(particles[i].speed * 0.05)
                    if particles[i].y < -20 {
                        particles[i].y = screenH + 20
                        particles[i].x = CGFloat.random(in: 0...screenW)
                    }
                }
            }
        }
    }

    private func createFirstProject(name: String?, colorHex: String?) {
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            let project = Project(
                name: name.trimmingCharacters(in: .whitespaces),
                colorHex: colorHex ?? "#6366F1"
            )
            modelContext.insert(project)
            try? modelContext.save()
        }
        completeOnboarding(projectName: name, colorHex: colorHex)
    }

    private func completeOnboarding(projectName: String?, colorHex: String?) {
        hapticEngine.playSuccess()
        withAnimation(.easeInOut(duration: 0.35)) {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Page 1: Tappable Pulsing Orb

struct OBPage1: View {
    let onTap: () -> Void

    @State private var pulsing = false
    @State private var tapCount = 0
    @State private var burstScale: CGFloat = 1
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Pulsing orb
            ZStack {
                // Outer rings
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(Color.pulseAccent.opacity(0.15 - Double(i) * 0.03), lineWidth: 1.5)
                        .frame(width: 160 + CGFloat(i * 44), height: 160 + CGFloat(i * 44))
                        .scaleEffect(pulsing ? 1 + CGFloat(i) * 0.04 : 1 - CGFloat(i) * 0.02)
                        .animation(
                            .easeInOut(duration: 1.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                            value: pulsing
                        )
                }

                // Glow burst on tap
                Circle()
                    .fill(Color.pulseAccent.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .scaleEffect(burstScale)
                    .blur(radius: 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: burstScale)

                // Main orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pulseAccent, Color.pulseAccent.opacity(0.7)],
                            center: .topLeading, startRadius: 0, endRadius: 75
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.clear],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 55, height: 55)
                            .offset(x: -20, y: -20)
                    )
                    .shadow(color: Color.pulseAccent.opacity(0.55), radius: 28, x: 0, y: 10)
                    .scaleEffect(pulsing ? 1.06 : 0.97)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulsing)

                Image(systemName: "heart.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 240, height: 300)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    burstScale = 1.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { burstScale = 1.0 }
                }
                tapCount += 1
            }

            VStack(spacing: 14) {
                Text("Your Projects Are Alive")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(tapCount == 0
                     ? "Tap the orb to feel its pulse"
                     : tapCount < 4
                     ? "Feel that? That's a healthy project"
                     : "Strong beats. This one's thriving.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: tapCount)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) { appeared = true }
            pulsing = true
        }
    }
}

// MARK: - Page 2: Health State Demo

struct OBPage2: View {

    @EnvironmentObject private var hapticEngine: HapticEngine

    private let states: [(label: String, color: Color, icon: String, description: String)] = [
        ("Healthy",   .pulseGreen,  "heart.fill",        "Thriving — you're shipping regularly"),
        ("Attention", .pulseYellow, "exclamationmark.circle.fill", "A few days without progress"),
        ("Critical",  .pulseOrange, "exclamationmark.triangle.fill", "Momentum is fading fast"),
        ("Dying",     .pulseRed,    "heart.slash.fill",  "Almost gone — needs you now"),
        ("Dead",      .pulseGray,   "xmark.circle.fill", "Flatlined — hibernate or revive it")
    ]
    @State private var stateIndex = 0
    @State private var orbScale: CGFloat = 1
    @State private var appeared = false

    private var current: (label: String, color: Color, icon: String, description: String) {
        states[stateIndex]
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            // State orb
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(current.color.opacity(0.2 - Double(i) * 0.06), lineWidth: 2)
                        .frame(width: 150 + CGFloat(i * 36), height: 150 + CGFloat(i * 36))
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [current.color, current.color.opacity(0.7)],
                            center: .topLeading, startRadius: 0, endRadius: 75
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: current.color.opacity(0.55), radius: 30, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 55, height: 55)
                            .offset(x: -20, y: -20)
                    )
                    .scaleEffect(orbScale)

                Image(systemName: current.icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(height: 260)
            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: stateIndex)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    orbScale = 1.12
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { orbScale = 1.0 }
                }
                hapticEngine.playTap()
                withAnimation(.spring(response: 0.45)) {
                    stateIndex = (stateIndex + 1) % states.count
                }
            }

            // State label chips
            HStack(spacing: 8) {
                ForEach(states.indices, id: \.self) { i in
                    Capsule()
                        .fill(states[i].color.opacity(i == stateIndex ? 0.25 : 0.08))
                        .overlay(Capsule().stroke(states[i].color.opacity(i == stateIndex ? 0.6 : 0.15), lineWidth: 1))
                        .frame(width: i == stateIndex ? 70 : 12, height: 8)
                        .animation(.spring(response: 0.35), value: stateIndex)
                }
            }

            VStack(spacing: 12) {
                Text(current.label)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(current.color)
                    .animation(.easeInOut(duration: 0.25), value: stateIndex)

                Text(current.description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.25), value: stateIndex)

                Text("Tap the orb to see each state")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Page 3: Expandable Health Level Cards

struct OBPage3: View {
    @State private var expandedIndex: Int? = nil
    @State private var appeared = false

    private let levels: [(title: String, color: Color, icon: String, detail: String)] = [
        ("Healthy",        .pulseGreen,  "heart.fill",                  "Worked on in the last 2 days. Keep it up!"),
        ("Needs Attention",.pulseYellow, "exclamationmark.circle.fill", "3–5 days without progress. Check in soon."),
        ("Critical",       .pulseOrange, "exclamationmark.triangle.fill","5–10 days dormant. Momentum is fading."),
        ("Dying",          .pulseRed,    "heart.slash.fill",             "10–30 days idle. Urgent intervention needed."),
        ("Dead",           .pulseGray,   "xmark.circle.fill",            "30+ days without a pulse. Hibernate or revive.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 28)

            Text("Project Health Levels")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Tap each card to learn more")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 6)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(levels.indices, id: \.self) { i in
                        let isExpanded = expandedIndex == i

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(levels[i].color.opacity(0.18))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: levels[i].icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(levels[i].color)
                                }

                                Text(levels[i].title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            if isExpanded {
                                Text(levels[i].detail)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(levels[i].color.opacity(isExpanded ? 0.12 : 0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(levels[i].color.opacity(isExpanded ? 0.35 : 0.15), lineWidth: 1)
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                expandedIndex = isExpanded ? nil : i
                            }
                        }
                    }
                }
                .padding(.horizontal, 28)
            }

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Page 4: Flame Streak Counter

struct OBPage4: View {
    @EnvironmentObject private var hapticEngine: HapticEngine

    @State private var streak = 0
    @State private var flameScale: CGFloat = 1
    @State private var appeared = false
    @State private var flameOpacity: Double = 1
    @State private var showSpark = false

    var flameSize: CGFloat { min(60 + CGFloat(streak) * 4, 120) }
    var flameColor: Color {
        streak < 3 ? .pulseYellow : streak < 7 ? .pulseOrange : .pulseRed
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            // Flame stack
            ZStack {
                // Glow
                Circle()
                    .fill(flameColor.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .blur(radius: 40)
                    .animation(.easeInOut(duration: 0.4), value: streak)

                // Layered flames
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "flame.fill")
                        .font(.system(size: flameSize - CGFloat(i * 12)))
                        .foregroundColor(flameColor.opacity(1 - Double(i) * 0.2))
                        .offset(y: CGFloat(i * 8))
                        .animation(.spring(response: 0.35), value: streak)
                }

                // Streak number
                Text("\(streak)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: flameColor.opacity(0.6), radius: 8)
                    .offset(y: 30)
                    .scaleEffect(flameScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: streak)
            }
            .frame(width: 240, height: 200)
            .contentShape(Rectangle())
            .onTapGesture {
                hapticEngine.playTap()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    streak += 1
                    flameScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { flameScale = 1.0 }
                }
            }

            VStack(spacing: 14) {
                Text("Build Your Streak")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(streak == 0
                     ? "Tap the flame to start your streak"
                     : streak < 5
                     ? "Keep going — consistency is power"
                     : streak < 10
                     ? "You're on fire! Don't break it"
                     : "Legend. Seriously.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.25), value: streak)

                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                        Text("\(streak) day streak")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(flameColor)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Page 5: Animated Daily Workflow

struct OBPage5: View {
    @State private var revealedSteps = 0
    @State private var appeared = false

    private let steps: [(icon: String, color: Color, title: String, detail: String)] = [
        ("sunrise.fill",      .pulseYellow, "Morning",    "Pick your Daily Three — the 3 projects that get energy today."),
        ("bolt.fill",         .pulseAccent, "Work",       "Log progress, capture ideas, and build momentum."),
        ("flame.fill",        .pulseOrange, "Streak",     "Touch each project daily to keep the streak alive."),
        ("moon.stars.fill",   .cyan,        "Evening",    "Reflect on what you shipped. Plan tomorrow."),
        ("chart.bar.fill",    .pulseGreen,  "Grow",       "Watch your health scores climb as consistency builds.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 4) {
                Text("Your Daily Rhythm")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Tap to reveal each step")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(steps.indices, id: \.self) { i in
                    if i <= revealedSteps {
                        WorkflowStepRow(
                            step: steps[i],
                            index: i,
                            isLatest: i == revealedSteps
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            if revealedSteps < steps.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        revealedSteps = min(revealedSteps + 1, steps.count - 1)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Next step")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
                }
            } else {
                Text("That's the whole loop")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.pulseGreen)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

struct WorkflowStepRow: View {
    let step: (icon: String, color: Color, title: String, detail: String)
    let index: Int
    let isLatest: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: step.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(step.color)
            }
            .shadow(color: step.color.opacity(isLatest ? 0.45 : 0), radius: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(step.detail)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
                    .lineSpacing(2)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(step.color.opacity(isLatest ? 0.1 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(step.color.opacity(isLatest ? 0.3 : 0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Page 6: Create First Project

struct OBPage6: View {
    let onComplete: (String?, String?) -> Void

    @EnvironmentObject private var hapticEngine: HapticEngine

    @State private var projectName = ""
    @State private var selectedColorHex = "#6366F1"
    @State private var appeared = false
    @State private var isPressed = false
    @FocusState private var nameFieldFocused: Bool

    private let colorChoices = Color.projectColorHexes

    var buttonColor: Color { Color(hex: selectedColorHex) ?? .pulseAccent }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 6) {
                Text("Launch Your First Project")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Give it a name and a color.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.bottom, 36)

            // Preview orb
            ZStack {
                Circle()
                    .fill(buttonColor.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [buttonColor, buttonColor.opacity(0.7)],
                            center: .topLeading, startRadius: 0, endRadius: 55
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .fill(LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                            .offset(x: -14, y: -14)
                    )
                    .shadow(color: buttonColor.opacity(0.5), radius: 20, x: 0, y: 8)

                Text(projectName.isEmpty ? "?" : String(projectName.prefix(1)).uppercased())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .animation(.spring(response: 0.35), value: selectedColorHex)
            .padding(.bottom, 28)

            // Name field
            TextField("", text: $projectName)
                .placeholder(when: projectName.isEmpty) {
                    Text("e.g. My iOS App, New Blog, Startup Idea…")
                        .foregroundColor(.white.opacity(0.3))
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .focused($nameFieldFocused)
                .autocorrectionDisabled()
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    nameFieldFocused
                                        ? buttonColor.opacity(0.6)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 1.5
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: nameFieldFocused)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

            // Color picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colorChoices, id: \.self) { hex in
                        let isSelected = hex == selectedColorHex
                        Circle()
                            .fill(Color(hex: hex) ?? .pulseAccent)
                            .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                    .padding(3)
                            )
                            .shadow(color: (Color(hex: hex) ?? .pulseAccent).opacity(isSelected ? 0.5 : 0), radius: 8)
                            .animation(.spring(response: 0.3), value: selectedColorHex)
                            .onTapGesture {
                                hapticEngine.playSelection()
                                selectedColorHex = hex
                            }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 8)
            }
            .padding(.bottom, 28)

            // Launch button
            Button {
                hapticEngine.playSuccess()
                onComplete(projectName.isEmpty ? nil : projectName, selectedColorHex)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: projectName.isEmpty ? "arrow.right.circle.fill" : "rocket.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(projectName.isEmpty ? "Skip for now" : "Launch Project")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(projectName.isEmpty ? Color.white.opacity(0.1) : buttonColor)
                        .shadow(
                            color: projectName.isEmpty ? .clear : buttonColor.opacity(0.4),
                            radius: 16, x: 0, y: 8
                        )
                )
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25), value: isPressed)
            .padding(.horizontal, 28)
            .animation(.easeInOut(duration: 0.2), value: projectName.isEmpty)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - Placeholder Helper

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
