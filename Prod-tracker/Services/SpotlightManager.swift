//
//  SpotlightManager.swift
//  Pulse
//
//  Indexes projects for iOS Spotlight search
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import SwiftUI
import Combine

@MainActor
final class SpotlightManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SpotlightManager()
    
    // MARK: - Domain Identifier
    
    private let domainIdentifier = "com.pulse.projects"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Index Project
    
    func indexProject(_ project: Project) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        
        // Basic info
        attributeSet.title = project.name
        attributeSet.contentDescription = project.projectDescription.isEmpty 
            ? "Health: \(project.healthLevel.displayName) • Streak: \(project.currentStreak) days"
            : project.projectDescription
        
        // Keywords for better search
        attributeSet.keywords = [
            project.name,
            project.healthLevel.displayName,
            "project",
            "pulse",
            "streak \(project.currentStreak)"
        ]
        
        // Display info
        attributeSet.displayName = project.name
        attributeSet.identifier = project.id.uuidString
        
        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: project.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        
        // Set expiration (never for active projects)
        if project.archivedAt == nil {
            item.expirationDate = .distantFuture
        } else {
            // Archived projects expire after 30 days from archive
            item.expirationDate = project.archivedAt?.addingTimeInterval(30 * 24 * 60 * 60)
        }
        
        // Index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Index All Projects
    
    func indexAllProjects(_ projects: [Project]) {
        let items = projects.map { project -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
            
            attributeSet.title = project.name
            attributeSet.contentDescription = project.projectDescription.isEmpty 
                ? "Health: \(project.healthLevel.displayName) • Streak: \(project.currentStreak) days"
                : project.projectDescription
            
            attributeSet.keywords = [
                project.name,
                project.healthLevel.displayName,
                "project",
                "pulse"
            ]
            
            attributeSet.displayName = project.name
            attributeSet.identifier = project.id.uuidString
            
            let item = CSSearchableItem(
                uniqueIdentifier: project.id.uuidString,
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
            
            item.expirationDate = project.archivedAt == nil ? .distantFuture : project.archivedAt?.addingTimeInterval(30 * 24 * 60 * 60)
            
            return item
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Spotlight batch indexing error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Remove Project from Index
    
    func removeProject(_ projectID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [projectID.uuidString]) { error in
            if let error = error {
                print("Spotlight removal error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Remove All Projects
    
    func removeAllProjects() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error = error {
                print("Spotlight clear error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Handle Spotlight Selection
    
    func projectID(from userActivity: NSUserActivity) -> UUID? {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return nil
        }
        return UUID(uuidString: identifier)
    }
    
    // MARK: - Index Todo
    
    private var todoDomainIdentifier: String { "com.pulse.todos" }
    
    func indexTodo(_ todo: Todo) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        
        attributeSet.title = todo.title
        attributeSet.contentDescription = todo.notes.isEmpty 
            ? "Priority: \(todo.priority.rawValue)"
            : todo.notes
        
        attributeSet.keywords = [
            todo.title,
            "task",
            "todo",
            todo.priority.rawValue
        ]
        
        attributeSet.displayName = todo.title
        attributeSet.identifier = todo.id.uuidString
        
        let item = CSSearchableItem(
            uniqueIdentifier: "todo_\(todo.id.uuidString)",
            domainIdentifier: todoDomainIdentifier,
            attributeSet: attributeSet
        )
        
        // Completed todos expire after 7 days
        if todo.isCompleted {
            item.expirationDate = todo.completedAt?.addingTimeInterval(7 * 24 * 60 * 60)
        } else {
            item.expirationDate = .distantFuture
        }
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight todo indexing error: \(error.localizedDescription)")
            }
        }
    }
    
    func removeTodo(_ todoID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["todo_\(todoID.uuidString)"]) { error in
            if let error = error {
                print("Spotlight todo removal error: \(error.localizedDescription)")
            }
        }
    }
}
