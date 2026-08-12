//
//  PulseOrbView.swift
//  Pulse
//
//  Living project orb with organic breathing animation
//

import SwiftUI

struct PulseOrbView: View {

    // MARK: - Properties

    let project: Project
    let size: CGFloat
    var showLabel: Bool = true
    var onTap: (() -> Void)?

    @EnvironmentObject private var hapticEngine: HapticEngine

    // MARK: - Breathing State

    @State private var inhaling = false          // drives all breathing animations
    @State private var glowBreath: Double = 0.25 // glow opacity oscillation
    @State private var ringExpand = false        // outer ring expansion

    // MARK: - Computed

    private var healthLevel: HealthLevel { project.healthLevel }
    private var baseColor: Color { project.color }
    private var glowColor: Color { healthLevel.glowColor }

    // How much the orb scales during one breath cycle
    private var breathDepth: CGFloat {
        switch healthLevel {
        case .healthy:       return 0.07   // 93%–107% of size
        case .needsAttention:return 0.05
        case .critical:      return 0.04
        case .dying:         return 0.025
        case .dead:          return 0      // static
        }
    }

    // Duration of one breath inhale (exhale mirrors it)
    private var breathDuration: Double {
        switch healthLevel {
        case .healthy:       return 1.8
        case .needsAttention:return 2.4
        case .critical:      return 1.2   // fast/anxious
        case .dying:         return 4.0   // laboured
        case .dead:          return 0
        }
    }

    private var breathAnimation: Animation {
        guard breathDuration > 0 else { return .linear(duration: 0) }
        return .easeInOut(duration: breathDuration).repeatForever(autoreverses: true)
    }

    private var breathScale: CGFloat {
        inhaling ? 1.0 + breathDepth : 1.0 - breathDepth
    }

    private var glowMin: Double { 0.18 + project.pulseIntensity * 0.08 }
    private var glowMax: Double { 0.45 + project.pulseIntensity * 0.25 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            orbBody
            if showLabel { labelBody }
        }
        .onAppear { startBreathing() }
    }

    // MARK: - Orb

    private var orbBody: some View {
        ZStack {
            // --- Outer breathing rings (3 layers) ---
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        glowColor.opacity(
                            inhaling
                                ? 0.28 - Double(i) * 0.08
                                : 0.10 - Double(i) * 0.03
                        ),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: size + CGFloat(i + 1) * 18,
                        height: size + CGFloat(i + 1) * 18
                    )
                    .scaleEffect(ringExpand ? 1.0 + CGFloat(i) * 0.025 : 1.0 - CGFloat(i) * 0.01)
                    .animation(
                        breathDuration > 0
                            ? breathAnimation.delay(Double(i) * 0.12)
                            : .linear(duration: 0),
                        value: ringExpand
                    )
            }

            // --- Glow blob ---
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(glowBreath * 0.85),
                            baseColor.opacity(glowBreath * 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 22)
                .animation(breathAnimation, value: glowBreath)

            // --- Main orb sphere ---
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor,
                            baseColor.opacity(0.82),
                            baseColor.opacity(0.55)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                // inner specular highlight
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(inhaling ? 0.38 : 0.22),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.55, height: size * 0.55)
                        .offset(x: -size * 0.14, y: -size * 0.14)
                        .animation(breathAnimation, value: inhaling)
                )
                // rim border
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .scaleEffect(breathScale)
                .animation(breathAnimation, value: inhaling)
                .shadow(
                    color: baseColor.opacity(inhaling ? 0.55 : 0.28),
                    radius: inhaling ? 22 : 10,
                    x: 0, y: inhaling ? 8 : 4
                )
                .animation(breathAnimation, value: inhaling)

            // --- Icon ---
            Image(systemName: project.iconName)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .scaleEffect(breathScale)
                .animation(breathAnimation, value: inhaling)

            // --- Streak badge ---
            if project.currentStreak > 0 {
                StreakBadge(streak: project.currentStreak)
                    .offset(x: size * 0.36, y: -size * 0.36)
            }
        }
        .frame(width: size * 1.6, height: size * 1.6)
        .contentShape(Circle())
        .onTapGesture {
            playHapticForHealth()
            onTap?()
        }
    }

    // MARK: - Label

    private var labelBody: some View {
        VStack(spacing: 3) {
            Text(project.name)
                .font(.system(size: min(size * 0.2, 15), weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(healthLevel.description)
                .font(.system(size: min(size * 0.14, 10), weight: .medium))
                .foregroundColor(healthLevel.color.opacity(0.85))
                .lineLimit(1)
        }
        .frame(maxWidth: size * 1.3)
    }

    // MARK: - Methods

    private func startBreathing() {
        guard breathDuration > 0 else {
            // Dead — ensure static state
            inhaling = false
            ringExpand = false
            glowBreath = glowMin * 0.5
            return
        }
        // Stagger the initial trigger slightly so not all orbs breathe in unison
        let delay = Double.random(in: 0...breathDuration)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(breathAnimation) {
                inhaling = true
                ringExpand = true
                glowBreath = glowMax
            }
        }
        // Start the glow oscillation
        withAnimation(breathAnimation) {
            glowBreath = glowMax
        }
    }

    private func playHapticForHealth() {
        switch healthLevel {
        case .healthy:        hapticEngine.playHealthyPulse()
        case .needsAttention: hapticEngine.playAttentionPulse()
        case .critical:       hapticEngine.playCriticalPulse()
        case .dying:          hapticEngine.playDyingPulse()
        case .dead:           hapticEngine.playTap()
        }
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 9, weight: .bold))
            Text("\(streak)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange)
                .shadow(color: .orange.opacity(0.55), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.pulseBackground.ignoresSafeArea()
        HStack(spacing: 50) {
            PulseOrbView(project: PreviewData.healthyProject, size: 80)
            PulseOrbView(project: PreviewData.dyingProject, size: 80)
        }
    }
    .environmentObject(HapticEngine.shared)
}

// MARK: - Preview Data

enum PreviewData {
    static var healthyProject: Project {
        let p = Project(name: "Pulse", colorHex: "#10B981", iconName: "heart.fill")
        p.currentStreak = 12
        p.lastTouchedAt = Date()
        return p
    }
    static var dyingProject: Project {
        let p = Project(name: "Old App", colorHex: "#EF4444", iconName: "app.fill")
        p.currentStreak = 0
        p.lastTouchedAt = Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date()
        return p
    }
}
