//
//  AnimatedGradientBackground.swift
//  Pulse
//
//  Mesmerizing animated gradient backgrounds
//

import SwiftUI

struct AnimatedGradientBackground: View {
    
    let colors: [Color]
    var animationDuration: Double = 5.0
    
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Mesh Gradient Background (iOS 18+)

struct MeshGradientBackground: View {
    
    let baseColor: Color
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.pulseBackground
            
            // Animated blobs
            GeometryReader { geometry in
                ZStack {
                    // Blob 1
                    Circle()
                        .fill(baseColor.opacity(0.4))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animate ? geometry.size.width * 0.2 : -geometry.size.width * 0.2,
                            y: animate ? -geometry.size.height * 0.2 : geometry.size.height * 0.1
                        )
                    
                    // Blob 2
                    Circle()
                        .fill(baseColor.opacity(0.3))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(
                            x: animate ? -geometry.size.width * 0.15 : geometry.size.width * 0.15,
                            y: animate ? geometry.size.height * 0.15 : -geometry.size.height * 0.1
                        )
                    
                    // Blob 3
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 40)
                        .offset(
                            x: animate ? geometry.size.width * 0.1 : -geometry.size.width * 0.1,
                            y: animate ? geometry.size.height * 0.2 : geometry.size.height * 0.3
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Particle Background

struct ParticleBackground: View {
    
    let particleColor: Color
    var particleCount: Int = 50
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.pulseBackground
                
                ForEach(particles) { particle in
                    Circle()
                        .fill(particleColor.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.size / 4)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 4...20),
                opacity: Double.random(in: 0.1...0.4),
                velocity: CGPoint(
                    x: CGFloat.random(in: -0.5...0.5),
                    y: CGFloat.random(in: -0.3...0.3)
                )
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                
                // Wrap around
                if particles[i].position.x < 0 { particles[i].position.x = size.width }
                if particles[i].position.x > size.width { particles[i].position.x = 0 }
                if particles[i].position.y < 0 { particles[i].position.y = size.height }
                if particles[i].position.y > size.height { particles[i].position.y = 0 }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var velocity: CGPoint
}

// MARK: - Aurora Background

struct AuroraBackground: View {
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.pulseBackground
            
            GeometryReader { geometry in
                ZStack {
                    // Aurora wave 1
                    AuroraWave(phase: phase, color: .green)
                        .frame(height: geometry.size.height * 0.6)
                        .offset(y: -geometry.size.height * 0.2)
                    
                    // Aurora wave 2
                    AuroraWave(phase: phase + 0.5, color: .blue)
                        .frame(height: geometry.size.height * 0.5)
                        .offset(y: -geometry.size.height * 0.1)
                    
                    // Aurora wave 3
                    AuroraWave(phase: phase + 1, color: .purple)
                        .frame(height: geometry.size.height * 0.4)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

struct AuroraWave: View {
    let phase: CGFloat
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let path = Path { path in
                path.move(to: CGPoint(x: 0, y: size.height))
                
                for x in stride(from: 0, to: size.width, by: 2) {
                    let relativeX = x / size.width
                    let y = sin(relativeX * 4 * .pi + phase) * size.height * 0.3 + size.height * 0.5
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.closeSubpath()
            }
            
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.4), color.opacity(0.1), .clear]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
        }
        .blur(radius: 30)
    }
}

// MARK: - Gradient Orb Background

struct GradientOrbBackground: View {
    
    let primaryColor: Color
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        ZStack {
            Color.pulseBackground
            
            // Large rotating gradient orb
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            primaryColor,
                            primaryColor.opacity(0.5),
                            .purple,
                            .purple.opacity(0.5),
                            primaryColor
                        ],
                        center: .center
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .opacity(0.6)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - Preview

#Preview("Animated Gradient") {
    AnimatedGradientBackground(colors: [.pulseAccent, .purple, Color(hex: "#0A0A0F")!])
}

#Preview("Mesh Gradient") {
    MeshGradientBackground(baseColor: .pulseAccent)
}

#Preview("Particles") {
    ParticleBackground(particleColor: .pulseAccent)
}

#Preview("Aurora") {
    AuroraBackground()
}

#Preview("Gradient Orb") {
    GradientOrbBackground(primaryColor: .pulseAccent)
}
