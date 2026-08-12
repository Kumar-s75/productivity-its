//
//  Color+Extensions.swift
//  Pulse
//
//  Color utilities and extensions
//

import SwiftUI

extension Color {
    
    // MARK: - Hex Initialization
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }
    
    // MARK: - To Hex
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // MARK: - App Colors (theme-aware)

    static var pulseBackground:    Color { CurrentTheme.shared.theme.background }
    static var pulseCardBackground: Color { CurrentTheme.shared.theme.cardBackground }
    static var pulseBorder:        Color { CurrentTheme.shared.theme.border }
    static var pulseAccent:        Color { CurrentTheme.shared.theme.accent }

    // Semantic colors — stay constant regardless of theme
    static let pulseGreen  = Color(hex: "#10B981") ?? .green
    static let pulseYellow = Color(hex: "#F59E0B") ?? .yellow
    static let pulseOrange = Color(hex: "#F97316") ?? .orange
    static let pulseRed    = Color(hex: "#EF4444") ?? .red
    static let pulseGray   = Color(hex: "#6B7280") ?? .gray
    static let pulseBlue   = Color(hex: "#3B82F6") ?? .blue
    
    // MARK: - Project Colors
    
    static let projectColors: [Color] = [
        Color(hex: "#EF4444") ?? .red,      // Red
        Color(hex: "#F97316") ?? .orange,   // Orange
        Color(hex: "#F59E0B") ?? .yellow,   // Amber
        Color(hex: "#EAB308") ?? .yellow,   // Yellow
        Color(hex: "#84CC16") ?? .green,    // Lime
        Color(hex: "#22C55E") ?? .green,    // Green
        Color(hex: "#10B981") ?? .teal,     // Emerald
        Color(hex: "#14B8A6") ?? .teal,     // Teal
        Color(hex: "#06B6D4") ?? .cyan,     // Cyan
        Color(hex: "#0EA5E9") ?? .blue,     // Sky
        Color(hex: "#3B82F6") ?? .blue,     // Blue
        Color(hex: "#6366F1") ?? .indigo,   // Indigo
        Color(hex: "#8B5CF6") ?? .purple,   // Violet
        Color(hex: "#A855F7") ?? .purple,   // Purple
        Color(hex: "#D946EF") ?? .pink,     // Fuchsia
        Color(hex: "#EC4899") ?? .pink,     // Pink
        Color(hex: "#F43F5E") ?? .red,      // Rose
    ]
    
    static let projectColorHexes: [String] = [
        "#EF4444", "#F97316", "#F59E0B", "#EAB308",
        "#84CC16", "#22C55E", "#10B981", "#14B8A6",
        "#06B6D4", "#0EA5E9", "#3B82F6", "#6366F1",
        "#8B5CF6", "#A855F7", "#D946EF", "#EC4899", "#F43F5E"
    ]
}
