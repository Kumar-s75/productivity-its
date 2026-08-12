//
//  Tag.swift
//  Pulse
//
//  Tags for organizing projects into categories
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {
    
    // MARK: - Properties
    
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var createdAt: Date
    var sortOrder: Int
    
    // MARK: - Computed Properties
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        colorHex: String = "#6366F1",
        iconName: String = "tag.fill",
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }
}

// MARK: - Default Tags

extension Tag {
    static let defaultTags: [(name: String, colorHex: String, iconName: String)] = [
        ("Work", "#3B82F6", "briefcase.fill"),
        ("Personal", "#10B981", "person.fill"),
        ("Side Project", "#F59E0B", "hammer.fill"),
        ("Learning", "#8B5CF6", "book.fill"),
        ("Health", "#EF4444", "heart.fill"),
        ("Finance", "#06B6D4", "dollarsign.circle.fill")
    ]
}
