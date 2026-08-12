//
//  AppTheme.swift
//  Pulse
//
//  Visual theme definitions — controls background, accent, and card colors
//

import SwiftUI

// MARK: - Theme Definition

struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String

    // Base palette
    let background: Color
    let cardBackground: Color
    let border: Color
    let accent: Color

    // BackgroundView gradient blobs
    let topGlow: Color
    let topGlowOpacity: Double
    let bottomGlow: Color
    let bottomGlowOpacity: Double
    let centerGlow: Color
    let centerGlowOpacity: Double
}

// MARK: - Theme Library

extension AppTheme {

    /// Deep indigo — the classic Pulse dark mode.
    static let midnight = AppTheme(
        id: "midnight", name: "Midnight", emoji: "🌙",
        background:      Color(hex: "#0A0A0F") ?? .black,
        cardBackground:  Color(hex: "#1A1A24") ?? .gray,
        border:          Color(hex: "#2A2A3A") ?? .gray,
        accent:          Color(hex: "#6366F1") ?? .indigo,
        topGlow:         Color(hex: "#6366F1") ?? .indigo, topGlowOpacity: 0.18,
        bottomGlow:      .purple,                          bottomGlowOpacity: 0.12,
        centerGlow:      Color(hex: "#6366F1") ?? .indigo, centerGlowOpacity: 0.08
    )

    /// Tropical breezy — cyan meets warm coral.
    static let summer = AppTheme(
        id: "summer", name: "Summer", emoji: "☀️",
        background:      Color(hex: "#060D14") ?? .black,
        cardBackground:  Color(hex: "#0D1C28") ?? .gray,
        border:          Color(hex: "#17303E") ?? .gray,
        accent:          Color(hex: "#06D6A0") ?? .teal,
        topGlow:         Color(hex: "#06D6A0") ?? .teal,    topGlowOpacity: 0.24,
        bottomGlow:      Color(hex: "#F97316") ?? .orange,  bottomGlowOpacity: 0.20,
        centerGlow:      Color(hex: "#14B8A6") ?? .teal,    centerGlowOpacity: 0.14
    )

    /// Northern lights — teal ribbons on deep teal-black.
    static let aurora = AppTheme(
        id: "aurora", name: "Aurora", emoji: "🌌",
        background:      Color(hex: "#050C10") ?? .black,
        cardBackground:  Color(hex: "#0D1A1E") ?? .gray,
        border:          Color(hex: "#1A2D30") ?? .gray,
        accent:          Color(hex: "#34D399") ?? .green,
        topGlow:         Color(hex: "#34D399") ?? .green,   topGlowOpacity: 0.22,
        bottomGlow:      Color(hex: "#8B5CF6") ?? .purple,  bottomGlowOpacity: 0.16,
        centerGlow:      Color(hex: "#10B981") ?? .green,   centerGlowOpacity: 0.11
    )

    /// Warm dusk — magenta to deep orange.
    static let sunset = AppTheme(
        id: "sunset", name: "Sunset", emoji: "🌅",
        background:      Color(hex: "#0C0810") ?? .black,
        cardBackground:  Color(hex: "#1C1422") ?? .gray,
        border:          Color(hex: "#2E2036") ?? .gray,
        accent:          Color(hex: "#FB923C") ?? .orange,
        topGlow:         Color(hex: "#EC4899") ?? .pink,    topGlowOpacity: 0.22,
        bottomGlow:      Color(hex: "#F97316") ?? .orange,  bottomGlowOpacity: 0.20,
        centerGlow:      Color(hex: "#F59E0B") ?? .yellow,  centerGlowOpacity: 0.10
    )

    /// Deep sea — layered azure blues.
    static let ocean = AppTheme(
        id: "ocean", name: "Ocean", emoji: "🌊",
        background:      Color(hex: "#050B18") ?? .black,
        cardBackground:  Color(hex: "#0B1624") ?? .gray,
        border:          Color(hex: "#152232") ?? .gray,
        accent:          Color(hex: "#38BDF8") ?? .blue,
        topGlow:         Color(hex: "#38BDF8") ?? .blue,    topGlowOpacity: 0.22,
        bottomGlow:      Color(hex: "#06B6D4") ?? .cyan,    bottomGlowOpacity: 0.16,
        centerGlow:      Color(hex: "#0EA5E9") ?? .blue,    centerGlowOpacity: 0.12
    )

    static let all: [AppTheme] = [.midnight, .summer, .aurora, .sunset, .ocean]
}

// MARK: - Global Theme Bridge
// Lets Color static properties stay reactive without per-view refactoring.

final class CurrentTheme {
    static let shared = CurrentTheme()
    var theme: AppTheme = {
        let id = UserDefaults.standard.string(forKey: "pulse.appTheme") ?? "midnight"
        return AppTheme.all.first { $0.id == id } ?? .midnight
    }()
    private init() {}
}
