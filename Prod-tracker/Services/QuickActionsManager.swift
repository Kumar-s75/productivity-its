//
//  QuickActionsManager.swift
//  Pulse
//
//  Manages 3D Touch / Long Press quick actions on app icon
//

import Foundation
import UIKit
import SwiftUI
import Combine

@MainActor
final class QuickActionsManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = QuickActionsManager()
    
    // MARK: - Published Properties
    
    @Published var selectedAction: QuickActionType?
    
    // MARK: - Quick Action Types
    
    enum QuickActionType: String {
        case addProject = "com.pulse.addProject"
        case addTodo = "com.pulse.addTodo"
        case dailyThree = "com.pulse.dailyThree"
        case quickTouch = "com.pulse.quickTouch"
        
        var shortcutItem: UIApplicationShortcutItem {
            switch self {
            case .addProject:
                return UIApplicationShortcutItem(
                    type: rawValue,
                    localizedTitle: "Add Project",
                    localizedSubtitle: "Create a new project",
                    icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
                    userInfo: nil
                )
            case .addTodo:
                return UIApplicationShortcutItem(
                    type: rawValue,
                    localizedTitle: "Add Task",
                    localizedSubtitle: "Create a new todo",
                    icon: UIApplicationShortcutIcon(systemImageName: "checkmark.circle"),
                    userInfo: nil
                )
            case .dailyThree:
                return UIApplicationShortcutItem(
                    type: rawValue,
                    localizedTitle: "Daily Three",
                    localizedSubtitle: "Pick today's focus",
                    icon: UIApplicationShortcutIcon(systemImageName: "target"),
                    userInfo: nil
                )
            case .quickTouch:
                return UIApplicationShortcutItem(
                    type: rawValue,
                    localizedTitle: "Quick Touch",
                    localizedSubtitle: "Touch your top project",
                    icon: UIApplicationShortcutIcon(systemImageName: "hand.tap.fill"),
                    userInfo: nil
                )
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        setupShortcuts()
    }
    
    // MARK: - Setup
    
    func setupShortcuts() {
        UIApplication.shared.shortcutItems = [
            QuickActionType.addProject.shortcutItem,
            QuickActionType.addTodo.shortcutItem,
            QuickActionType.dailyThree.shortcutItem,
            QuickActionType.quickTouch.shortcutItem
        ]
    }
    
    // MARK: - Handle Shortcut
    
    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else {
            return false
        }
        
        selectedAction = actionType
        return true
    }
    
    // MARK: - Clear Selection
    
    func clearSelection() {
        selectedAction = nil
    }
}

// MARK: - Quick Action Modifier

struct QuickActionModifier: ViewModifier {
    @ObservedObject var quickActionsManager = QuickActionsManager.shared
    
    let onAddProject: () -> Void
    let onAddTodo: () -> Void
    let onDailyThree: () -> Void
    let onQuickTouch: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: quickActionsManager.selectedAction) { _, action in
                guard let action = action else { return }
                
                switch action {
                case .addProject:
                    onAddProject()
                case .addTodo:
                    onAddTodo()
                case .dailyThree:
                    onDailyThree()
                case .quickTouch:
                    onQuickTouch()
                }
                
                quickActionsManager.clearSelection()
            }
    }
}

extension View {
    func handleQuickActions(
        onAddProject: @escaping () -> Void,
        onAddTodo: @escaping () -> Void,
        onDailyThree: @escaping () -> Void,
        onQuickTouch: @escaping () -> Void
    ) -> some View {
        modifier(QuickActionModifier(
            onAddProject: onAddProject,
            onAddTodo: onAddTodo,
            onDailyThree: onDailyThree,
            onQuickTouch: onQuickTouch
        ))
    }
}
