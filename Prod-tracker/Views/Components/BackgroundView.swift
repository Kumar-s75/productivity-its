//
//  BackgroundView.swift
//  Pulse
//
//  Atmospheric app background with gradient mesh
//

import SwiftUI

struct BackgroundView: View {

    @EnvironmentObject private var appState: AppState
    @State private var animateGradient = false

    var body: some View {
        let theme = appState.appTheme
        ZStack {
            // Base
            theme.background

            // Gradient mesh
            GeometryReader { geometry in
                ZStack {
                    // Top-left glow — theme primary
                    RadialGradient(
                        gradient: Gradient(colors: [
                            theme.topGlow.opacity(theme.topGlowOpacity),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.85
                    )

                    // Bottom-right glow — theme secondary
                    RadialGradient(
                        gradient: Gradient(colors: [
                            theme.bottomGlow.opacity(theme.bottomGlowOpacity),
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.75
                    )

                    // Animated drifting center blob
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    theme.centerGlow.opacity(theme.centerGlowOpacity),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.48
                            )
                        )
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.9)
                        .offset(
                            x: animateGradient ? 55 : -55,
                            y: animateGradient ? -35 : 35
                        )
                        .blur(radius: 65)
                        .animation(
                            .easeInOut(duration: 9).repeatForever(autoreverses: true),
                            value: animateGradient
                        )
                }
            }

            NoiseOverlay()
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Noise Overlay

struct NoiseOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for _ in 0..<Int(size.width * size.height / 100) {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.02...0.05)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    BackgroundView()
        .environmentObject(AppState.shared)
}
