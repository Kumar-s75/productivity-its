//
//  ConfettiView.swift
//  Pulse
//
//  Beautiful confetti animation for celebrations
//

import SwiftUI

struct ConfettiView: View {
    
    @Binding var isActive: Bool
    var intensity: ConfettiIntensity = .medium
    
    @State private var particles: [ConfettiParticle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startConfetti(in: geometry.size)
                } else {
                    stopConfetti()
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startConfetti(in size: CGSize) {
        particles = (0..<intensity.particleCount).map { _ in
            ConfettiParticle(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: ConfettiColors.random,
                size: CGFloat.random(in: 8...14),
                rotation: Double.random(in: 0...360),
                velocity: CGPoint(
                    x: CGFloat.random(in: -3...3),
                    y: CGFloat.random(in: 5...10)
                ),
                rotationSpeed: Double.random(in: -10...10),
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles(in: size)
        }
        
        // Auto-stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + intensity.duration) {
            stopConfetti()
        }
    }
    
    private func updateParticles(in size: CGSize) {
        particles = particles.compactMap { particle in
            var updated = particle
            updated.position.x += particle.velocity.x
            updated.position.y += particle.velocity.y
            updated.rotation += particle.rotationSpeed
            updated.velocity.y += 0.2 // Gravity
            updated.opacity -= 0.005
            
            // Remove if off screen or faded
            if updated.position.y > size.height + 50 || updated.opacity <= 0 {
                return nil
            }
            return updated
        }
        
        if particles.isEmpty {
            stopConfetti()
        }
    }
    
    private func stopConfetti() {
        animationTimer?.invalidate()
        animationTimer = nil
        particles = []
        isActive = false
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var rotation: Double
    var velocity: CGPoint
    var rotationSpeed: Double
    var shape: ConfettiShape
    var opacity: Double = 1.0
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    
    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
            case .square:
                Rectangle()
                    .fill(particle.color)
            case .triangle:
                Triangle()
                    .fill(particle.color)
            case .star:
                Image(systemName: "star.fill")
                    .resizable()
                    .foregroundColor(particle.color)
            case .heart:
                Image(systemName: "heart.fill")
                    .resizable()
                    .foregroundColor(particle.color)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.rotation))
        .position(particle.position)
        .opacity(particle.opacity)
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Shape

enum ConfettiShape: CaseIterable {
    case circle
    case square
    case triangle
    case star
    case heart
}

// MARK: - Confetti Colors

enum ConfettiColors {
    static let all: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        Color(hex: "#FF6B6B") ?? .red,
        Color(hex: "#4ECDC4") ?? .teal,
        Color(hex: "#FFE66D") ?? .yellow,
        Color(hex: "#95E1D3") ?? .mint,
        Color(hex: "#F38181") ?? .pink
    ]
    
    static var random: Color {
        all.randomElement() ?? .blue
    }
}

// MARK: - Confetti Intensity

enum ConfettiIntensity {
    case light
    case medium
    case heavy
    case epic
    
    var particleCount: Int {
        switch self {
        case .light: return 30
        case .medium: return 60
        case .heavy: return 100
        case .epic: return 200
        }
    }
    
    var duration: Double {
        switch self {
        case .light: return 2.0
        case .medium: return 3.0
        case .heavy: return 4.0
        case .epic: return 5.0
        }
    }
}

// MARK: - Confetti Modifier

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    var intensity: ConfettiIntensity = .medium
    
    func body(content: Content) -> some View {
        ZStack {
            content
            ConfettiView(isActive: $isActive, intensity: intensity)
        }
    }
}

extension View {
    func confetti(isActive: Binding<Bool>, intensity: ConfettiIntensity = .medium) -> some View {
        modifier(ConfettiModifier(isActive: isActive, intensity: intensity))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var showConfetti = false
        
        var body: some View {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack {
                    Button("Celebrate! 🎉") {
                        showConfetti = true
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.pulseAccent)
                    .cornerRadius(12)
                }
            }
            .confetti(isActive: $showConfetti, intensity: .heavy)
        }
    }
    
    return PreviewWrapper()
}
