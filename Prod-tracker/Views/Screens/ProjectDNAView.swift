//
//  ProjectDNAView.swift
//  Pulse
//
//  Unique visual DNA fingerprint for each project - generative art from project history
//

import SwiftUI
import SwiftData

struct ProjectDNAView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Properties
    
    let project: Project
    
    // MARK: - State
    
    @State private var animateDNA = false
    @State private var selectedLayer: DNALayer?
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    
    // MARK: - Computed
    
    private var dnaData: ProjectDNAData {
        ProjectDNAData(project: project)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // DNA Visualization
                    dnaVisualization
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                    
                    // Info panel
                    infoPanel
                }
            }
            .navigationTitle("Project DNA")
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
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        shareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animateDNA = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    DNAShareSheet(items: [image])
                }
            }
        }
    }
    
    // MARK: - DNA Visualization
    
    private var dnaVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [project.color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .scaleEffect(animateDNA ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateDNA)
                
                // DNA Rings - each represents a different aspect
                ForEach(0..<dnaData.rings.count, id: \.self) { index in
                    DNARing(
                        ring: dnaData.rings[index],
                        index: index,
                        totalRings: dnaData.rings.count,
                        animate: animateDNA,
                        isSelected: selectedLayer == dnaData.rings[index].layer
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4)) {
                            if selectedLayer == dnaData.rings[index].layer {
                                selectedLayer = nil
                            } else {
                                selectedLayer = dnaData.rings[index].layer
                            }
                        }
                        hapticEngine.playTap()
                    }
                }
                
                // Center orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [project.color, project.color.opacity(0.5)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: project.color.opacity(0.8), radius: 20)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateDNA ? 1 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animateDNA)
                
                // Floating particles based on pulse count
                ForEach(0..<min(dnaData.particleCount, 30), id: \.self) { i in
                    DNAParticle(
                        index: i,
                        color: project.color,
                        animate: animateDNA
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    // MARK: - Info Panel
    
    private var infoPanel: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project name
                Text(project.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // DNA Stats
                HStack(spacing: 30) {
                    DNAStatView(
                        value: "\(dnaData.uniqueScore)",
                        label: "Uniqueness",
                        color: .purple
                    )
                    
                    DNAStatView(
                        value: "\(dnaData.consistencyScore)%",
                        label: "Consistency",
                        color: .cyan
                    )
                    
                    DNAStatView(
                        value: "\(dnaData.intensityScore)",
                        label: "Intensity",
                        color: .orange
                    )
                }
                
                // Layer info
                if let layer = selectedLayer {
                    layerInfo(for: layer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // DNA breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("DNA Breakdown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ForEach(dnaData.rings, id: \.layer) { ring in
                        DNABreakdownRow(ring: ring, isSelected: selectedLayer == ring.layer)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4)) {
                                    selectedLayer = ring.layer
                                }
                                hapticEngine.playTap()
                            }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .padding()
        }
    }
    
    private func layerInfo(for layer: DNALayer) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: layer.icon)
                    .foregroundColor(layer.color)
                Text(layer.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(layer.description(for: project))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(layer.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(layer.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Methods
    
    private func shareImage() {
        // Render DNA visualization
        let renderer = ImageRenderer(content: 
            ZStack {
                Color.black
                
                VStack {
                    Text(project.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Simplified DNA for share
                    ZStack {
                        Circle()
                            .fill(project.color)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: project.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Text("Project DNA • Pulse")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 400, height: 400)
        )
        
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            renderedImage = image
            showShareSheet = true
        }
    }
}

// MARK: - DNA Ring

struct DNARing: View {
    let ring: DNARingData
    let index: Int
    let totalRings: Int
    let animate: Bool
    let isSelected: Bool
    
    private var radius: CGFloat {
        CGFloat(60 + (index * 35))
    }
    
    var body: some View {
        ZStack {
            // Ring segments
            ForEach(0..<ring.segments, id: \.self) { segment in
                RingSegment(
                    startAngle: Double(segment) * (360.0 / Double(ring.segments)),
                    endAngle: Double(segment + 1) * (360.0 / Double(ring.segments)) - 5,
                    radius: radius,
                    thickness: isSelected ? 12 : 8,
                    color: ring.layer.color.opacity(ring.intensities[segment % ring.intensities.count])
                )
                .rotationEffect(.degrees(animate ? Double(index % 2 == 0 ? 1 : -1) * 360 : 0))
                .animation(
                    .linear(duration: Double(20 + index * 5))
                    .repeatForever(autoreverses: false),
                    value: animate
                )
            }
        }
        .scaleEffect(animate ? 1 : 0)
        .opacity(animate ? 1 : 0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7)
            .delay(Double(index) * 0.1),
            value: animate
        )
    }
}

struct RingSegment: View {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    let thickness: CGFloat
    let color: Color
    
    var body: some View {
        Circle()
            .trim(from: startAngle / 360, to: endAngle / 360)
            .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
    }
}

// MARK: - DNA Particle

struct DNAParticle: View {
    let index: Int
    let color: Color
    let animate: Bool
    
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 3...8), height: CGFloat.random(in: 3...8))
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let angle = Double.random(in: 0..<360)
                let distance = CGFloat.random(in: 100...180)
                
                withAnimation(
                    .easeOut(duration: Double.random(in: 1...2))
                    .delay(Double(index) * 0.05)
                ) {
                    offset = CGSize(
                        width: cos(angle * .pi / 180) * distance,
                        height: sin(angle * .pi / 180) * distance
                    )
                    opacity = Double.random(in: 0.3...0.8)
                }
                
                // Floating animation
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1)
                ) {
                    offset.width += CGFloat.random(in: -20...20)
                    offset.height += CGFloat.random(in: -20...20)
                }
            }
    }
}

// MARK: - DNA Stat View

struct DNAStatView: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - DNA Breakdown Row

struct DNABreakdownRow: View {
    let ring: DNARingData
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ring.layer.color)
                .frame(width: 12, height: 12)
            
            Text(ring.layer.title)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            // Mini visualization
            HStack(spacing: 2) {
                ForEach(0..<min(ring.intensities.count, 10), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ring.layer.color.opacity(ring.intensities[i]))
                        .frame(width: 4, height: 16)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? ring.layer.color.opacity(0.15) : Color.clear)
        )
    }
}

// MARK: - DNA Layer

enum DNALayer: String, CaseIterable {
    case activity
    case consistency
    case intensity
    case milestones
    case time
    
    var title: String {
        switch self {
        case .activity: return "Activity Pattern"
        case .consistency: return "Consistency"
        case .intensity: return "Work Intensity"
        case .milestones: return "Achievements"
        case .time: return "Time Distribution"
        }
    }
    
    var icon: String {
        switch self {
        case .activity: return "waveform.path"
        case .consistency: return "chart.bar.fill"
        case .intensity: return "flame.fill"
        case .milestones: return "flag.fill"
        case .time: return "clock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .activity: return .cyan
        case .consistency: return .green
        case .intensity: return .orange
        case .milestones: return .purple
        case .time: return .pink
        }
    }
    
    func description(for project: Project) -> String {
        switch self {
        case .activity:
            let count = project.pulseEntries?.count ?? 0
            return "You've logged \(count) work sessions on this project, creating a unique activity signature."
        case .consistency:
            return "Your streak of \(project.currentStreak) days shows your commitment pattern."
        case .intensity:
            let entries = project.pulseEntries ?? []
            let totalIntensity = entries.reduce(0.0) { $0 + Double($1.intensityLevel) }
            let avgIntensity = entries.isEmpty ? 0 : totalIntensity / Double(entries.count)
            return "Average intensity of \(String(format: "%.1f", avgIntensity))/5 across all sessions."
        case .milestones:
            let completed = project.milestones?.filter { $0.isCompleted }.count ?? 0
            let total = project.milestones?.count ?? 0
            return "\(completed) of \(total) milestones achieved, marking key moments in your journey."
        case .time:
            let entries = project.pulseEntries ?? []
            let totalMinutes = entries.reduce(0) { $0 + ($1.durationMinutes ?? 0) }
            let hours = totalMinutes / 60
            return "\(hours) hours invested, distributed across your work sessions."
        }
    }
}

// MARK: - DNA Ring Data

struct DNARingData {
    let layer: DNALayer
    let segments: Int
    let intensities: [Double]
}

// MARK: - Project DNA Data

struct ProjectDNAData {
    let rings: [DNARingData]
    let uniqueScore: Int
    let consistencyScore: Int
    let intensityScore: Int
    let particleCount: Int
    
    init(project: Project) {
        let pulses = project.pulseEntries ?? []
        let milestones = project.milestones ?? []
        
        // Generate rings from project data
        var generatedRings: [DNARingData] = []
        
        // Activity ring - based on pulse frequency
        let activityIntensities = Self.generateActivityIntensities(from: pulses)
        generatedRings.append(DNARingData(
            layer: .activity,
            segments: 12,
            intensities: activityIntensities
        ))
        
        // Consistency ring - based on streaks
        let consistencyIntensities = Self.generateConsistencyIntensities(streak: project.currentStreak, longest: project.longestStreak)
        generatedRings.append(DNARingData(
            layer: .consistency,
            segments: 8,
            intensities: consistencyIntensities
        ))
        
        // Intensity ring - based on work intensity
        let intensityValues = Self.generateIntensityValues(from: pulses)
        generatedRings.append(DNARingData(
            layer: .intensity,
            segments: 16,
            intensities: intensityValues
        ))
        
        // Milestones ring
        let milestoneIntensities = Self.generateMilestoneIntensities(from: milestones)
        generatedRings.append(DNARingData(
            layer: .milestones,
            segments: max(milestones.count, 6),
            intensities: milestoneIntensities
        ))
        
        // Time ring - based on when work happens
        let timeIntensities = Self.generateTimeIntensities(from: pulses)
        generatedRings.append(DNARingData(
            layer: .time,
            segments: 24,
            intensities: timeIntensities
        ))
        
        self.rings = generatedRings
        
        // Calculate scores
        self.uniqueScore = Self.calculateUniqueness(pulses: pulses, milestones: milestones)
        self.consistencyScore = min(100, project.currentStreak * 10 + project.longestStreak * 2)
        
        let totalIntensity = pulses.reduce(0.0) { $0 + Double($1.intensityLevel) }
        let avgIntensity = pulses.isEmpty ? 0.0 : totalIntensity / Double(pulses.count)
        self.intensityScore = Int(avgIntensity * 20)
        self.particleCount = min(pulses.count, 30)
    }
    
    private static func generateActivityIntensities(from pulses: [PulseEntry]) -> [Double] {
        guard !pulses.isEmpty else { return Array(repeating: 0.2, count: 12) }
        
        var monthlyActivity = Array(repeating: 0.0, count: 12)
        let calendar = Calendar.current
        
        for pulse in pulses {
            let month = calendar.component(.month, from: pulse.date) - 1
            monthlyActivity[month] += 1
        }
        
        let maxActivity = monthlyActivity.max() ?? 1
        return monthlyActivity.map { min(1.0, ($0 / maxActivity) * 0.8 + 0.2) }
    }
    
    private static func generateConsistencyIntensities(streak: Int, longest: Int) -> [Double] {
        let baseIntensity = Double(streak) / Double(max(longest, 1))
        return (0..<8).map { i in
            let variation = sin(Double(i) * .pi / 4) * 0.2
            return min(1.0, max(0.2, baseIntensity + variation))
        }
    }
    
    private static func generateIntensityValues(from pulses: [PulseEntry]) -> [Double] {
        guard !pulses.isEmpty else { return Array(repeating: 0.2, count: 16) }
        
        let sortedPulses = pulses.sorted { $0.date < $1.date }
        let step = max(1, sortedPulses.count / 16)
        
        var results: [Double] = []
        for i in 0..<16 {
            let index = min(i * step, sortedPulses.count - 1)
            let intensity = Double(sortedPulses[index].intensityLevel) / 5.0
            results.append(intensity)
        }
        return results
    }
    
    private static func generateMilestoneIntensities(from milestones: [Milestone]) -> [Double] {
        guard !milestones.isEmpty else { return Array(repeating: 0.3, count: 6) }
        
        return milestones.map { milestone in
            milestone.isCompleted ? 1.0 : 0.4
        }
    }
    
    private static func generateTimeIntensities(from pulses: [PulseEntry]) -> [Double] {
        var hourlyActivity = Array(repeating: 0.0, count: 24)
        let calendar = Calendar.current
        
        for pulse in pulses {
            let hour = calendar.component(.hour, from: pulse.date)
            hourlyActivity[hour] += 1
        }
        
        let maxActivity = hourlyActivity.max() ?? 1
        return hourlyActivity.map { max(0.1, $0 / maxActivity) }
    }
    
    private static func calculateUniqueness(pulses: [PulseEntry], milestones: [Milestone]) -> Int {
        // Uniqueness based on variance in work patterns
        guard !pulses.isEmpty else { return 50 }
        
        // Calculate intensity variance
        let intensityValues = pulses.map { Double($0.intensityLevel) }
        let intensityMean = intensityValues.reduce(0, +) / Double(intensityValues.count)
        let intensityVariance = intensityValues.map { pow($0 - intensityMean, 2) }.reduce(0, +) / Double(intensityValues.count)
        
        // Calculate duration variance
        let durationValues = pulses.compactMap { $0.durationMinutes }.map { Double($0) }
        var durationVariance = 0.0
        if !durationValues.isEmpty {
            let durationMean = durationValues.reduce(0, +) / Double(durationValues.count)
            durationVariance = durationValues.map { pow($0 - durationMean, 2) }.reduce(0, +) / Double(durationValues.count)
        }
        
        let uniqueness = Int(intensityVariance * 20 + sqrt(durationVariance) + Double(milestones.count) * 5)
        return min(100, max(10, uniqueness))
    }
}

// MARK: - Share Sheet

struct DNAShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ProjectDNAView(
        project: Project(name: "Pulse App", colorHex: "#6366F1", iconName: "heart.fill")
    )
    .environmentObject(HapticEngine.shared)
}
