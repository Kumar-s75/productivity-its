//
//  ShareCardView.swift
//  Pulse
//
//  Beautiful shareable cards for social media
//

import SwiftUI
import SwiftData

struct ShareCardView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Properties
    
    let project: Project
    
    // MARK: - State
    
    @State private var selectedStyle: CardStyle = .gradient
    @State private var isExporting = false
    @State private var exportedImage: UIImage?
    @State private var showShareSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Card preview
                    cardPreview
                        .padding(.top, 20)
                    
                    // Style selector
                    styleSelector
                    
                    Spacer()
                    
                    // Export button
                    exportButton
                }
                .padding()
            }
            .navigationTitle("Share Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = exportedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    // MARK: - Card Preview
    
    private var cardPreview: some View {
        ShareableCard(project: project, style: selectedStyle)
            .frame(width: 320, height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: project.color.opacity(0.3), radius: 30, x: 0, y: 15)
    }
    
    // MARK: - Style Selector
    
    private var styleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 12) {
                ForEach(CardStyle.allCases, id: \.self) { style in
                    Button {
                        selectedStyle = style
                        hapticEngine.playTap()
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(style.previewGradient(for: project.color))
                                .frame(width: 50, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedStyle == style ? Color.white : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            
                            Text(style.name)
                                .font(.system(size: 11))
                                .foregroundColor(selectedStyle == style ? .white : .white.opacity(0.5))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button {
            exportCard()
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(project.color)
            )
        }
        .disabled(isExporting)
        .padding(.bottom, 20)
    }
    
    // MARK: - Methods
    
    private func exportCard() {
        isExporting = true
        hapticEngine.playTap()
        
        // Render the card to image
        let renderer = ImageRenderer(
            content: ShareableCard(project: project, style: selectedStyle)
                .frame(width: 640, height: 800)
        )
        renderer.scale = 2.0
        
        if let image = renderer.uiImage {
            exportedImage = image
            showShareSheet = true
        }
        
        isExporting = false
    }
}

// MARK: - Shareable Card

struct ShareableCard: View {
    let project: Project
    let style: CardStyle
    
    var body: some View {
        ZStack {
            // Background
            style.background(for: project.color)
            
            // Content
            VStack(spacing: 20) {
                Spacer()
                
                // Orb
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    project.healthLevel.color.opacity(0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    // Main orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    project.color,
                                    project.color.opacity(0.7)
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .offset(x: -15, y: -15)
                        )
                        .shadow(color: project.color.opacity(0.5), radius: 20)
                    
                    // Icon
                    Image(systemName: project.iconName)
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                // Project name
                Text(project.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Stats row
                HStack(spacing: 30) {
                    StatBadge(
                        icon: "flame.fill",
                        value: "\(project.currentStreak)",
                        label: "streak"
                    )
                    
                    StatBadge(
                        icon: "heart.fill",
                        value: project.healthLevel.displayName,
                        label: "health"
                    )
                }
                
                Spacer()
                
                // Branding
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14))
                    Text("Pulse")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }
}

// MARK: - Card Style

enum CardStyle: CaseIterable {
    case gradient
    case dark
    case minimal
    case neon
    
    var name: String {
        switch self {
        case .gradient: return "Gradient"
        case .dark: return "Dark"
        case .minimal: return "Minimal"
        case .neon: return "Neon"
        }
    }
    
    func previewGradient(for color: Color) -> LinearGradient {
        switch self {
        case .gradient:
            return LinearGradient(
                colors: [color, color.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                colors: [Color(hex: "#1A1A2E")!, Color(hex: "#0A0A0F")!],
                startPoint: .top,
                endPoint: .bottom
            )
        case .minimal:
            return LinearGradient(
                colors: [Color(hex: "#1C1C1E")!, Color(hex: "#2C2C2E")!],
                startPoint: .top,
                endPoint: .bottom
            )
        case .neon:
            return LinearGradient(
                colors: [Color(hex: "#0D0D0D")!, color.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    @ViewBuilder
    func background(for color: Color) -> some View {
        switch self {
        case .gradient:
            LinearGradient(
                colors: [
                    color.opacity(0.8),
                    color.opacity(0.4),
                    Color(hex: "#0A0A0F")!
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .dark:
            ZStack {
                Color(hex: "#0A0A0F")
                
                // Subtle gradient
                LinearGradient(
                    colors: [
                        color.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
            
        case .minimal:
            Color(hex: "#1C1C1E")
            
        case .neon:
            ZStack {
                Color(hex: "#0D0D0D")
                
                // Neon glow border effect
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color, lineWidth: 2)
                    .blur(radius: 4)
                    .padding(4)
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(color, lineWidth: 1)
                    .padding(4)
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ShareCardView(
        project: Project(name: "Pulse App", colorHex: "#6366F1", iconName: "heart.fill")
    )
    .environmentObject(HapticEngine.shared)
}
