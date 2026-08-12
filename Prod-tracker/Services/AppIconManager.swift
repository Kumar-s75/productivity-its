//
//  AppIconManager.swift
//  Pulse
//
//  Manages alternate app icons
//

import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class AppIconManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppIconManager()
    
    // MARK: - Published
    
    @Published var currentIcon: AppIcon = .default
    @Published var isChanging = false
    
    // MARK: - Available Icons
    
    enum AppIcon: String, CaseIterable, Identifiable {
        case `default` = "AppIcon"
        case dark = "AppIcon-Dark"
        case midnight = "AppIcon-Midnight"
        case neon = "AppIcon-Neon"
        case minimal = "AppIcon-Minimal"
        case pride = "AppIcon-Pride"
        case sunset = "AppIcon-Sunset"
        case ocean = "AppIcon-Ocean"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .default: return "Default"
            case .dark: return "Dark"
            case .midnight: return "Midnight"
            case .neon: return "Neon"
            case .minimal: return "Minimal"
            case .pride: return "Pride"
            case .sunset: return "Sunset"
            case .ocean: return "Ocean"
            }
        }
        
        var previewColors: [Color] {
            switch self {
            case .default: return [.pulseAccent, .purple]
            case .dark: return [Color(hex: "#1a1a2e") ?? .black, Color(hex: "#16213e") ?? .black]
            case .midnight: return [Color(hex: "#0f0c29") ?? .black, Color(hex: "#302b63") ?? .purple]
            case .neon: return [Color(hex: "#00ff87") ?? .green, Color(hex: "#60efff") ?? .cyan]
            case .minimal: return [.white, Color(hex: "#f0f0f0") ?? .gray]
            case .pride: return [.red, .orange, .yellow, .green, .blue, .purple]
            case .sunset: return [Color(hex: "#ff6b6b") ?? .red, Color(hex: "#feca57") ?? .yellow]
            case .ocean: return [Color(hex: "#0077b6") ?? .blue, Color(hex: "#00b4d8") ?? .cyan]
            }
        }
        
        var iconName: String? {
            self == .default ? nil : rawValue
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        loadCurrentIcon()
    }
    
    // MARK: - Load Current Icon
    
    private func loadCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName {
            currentIcon = AppIcon(rawValue: iconName) ?? .default
        } else {
            currentIcon = .default
        }
    }
    
    // MARK: - Change Icon
    
    func changeIcon(to icon: AppIcon) async {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        isChanging = true
        
        do {
            try await UIApplication.shared.setAlternateIconName(icon.iconName)
            currentIcon = icon
        } catch {
            print("Failed to change app icon: \(error.localizedDescription)")
        }
        
        isChanging = false
    }
}

// MARK: - App Icon Picker View

struct AppIconPickerView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var iconManager = AppIconManager.shared
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current icon preview
                        currentIconPreview
                        
                        // Icon grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(AppIconManager.AppIcon.allCases) { icon in
                                AppIconCard(
                                    icon: icon,
                                    isSelected: iconManager.currentIcon == icon,
                                    isChanging: iconManager.isChanging
                                ) {
                                    Task {
                                        await iconManager.changeIcon(to: icon)
                                        hapticEngine.playSuccess()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var currentIconPreview: some View {
        VStack(spacing: 12) {
            // Large preview
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: iconManager.currentIcon.previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: iconManager.currentIcon.previewColors.first?.opacity(0.4) ?? .clear, radius: 20, x: 0, y: 10)
                
                // Pulse icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            Text(iconManager.currentIcon.displayName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Current Icon")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 30)
    }
}

// MARK: - App Icon Card

struct AppIconCard: View {
    let icon: AppIconManager.AppIcon
    let isSelected: Bool
    let isChanging: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    // Icon preview
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: icon.previewColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.pulseAccent : Color.clear, lineWidth: 3)
                        )
                    
                    // Heart icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundColor(icon == .minimal ? .pulseAccent : .white)
                    
                    // Selected checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.pulseAccent)
                                    .background(Circle().fill(.white).frame(width: 16, height: 16))
                            }
                            Spacer()
                        }
                        .frame(width: 70, height: 70)
                        .offset(x: 8, y: -8)
                    }
                }
                
                Text(icon.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
        }
        .disabled(isChanging)
        .opacity(isChanging && !isSelected ? 0.5 : 1)
    }
}

// MARK: - Preview

#Preview {
    AppIconPickerView()
        .environmentObject(HapticEngine.shared)
}
