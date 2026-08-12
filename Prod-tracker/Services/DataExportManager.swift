//
//  DataExportManager.swift
//  Pulse
//
//  Handles exporting user data to JSON and CSV
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

@MainActor
final class DataExportManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DataExportManager()
    
    // MARK: - Published
    
    @Published var isExporting = false
    @Published var exportError: String?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Export All Data (JSON)
    
    func exportAllData(projects: [Project], todos: [Todo]) -> URL? {
        isExporting = true
        defer { isExporting = false }
        
        let exportData = PulseExportData(
            exportDate: Date(),
            version: "1.0",
            projects: projects.map { ProjectExport(from: $0) },
            todos: todos.map { TodoExport(from: $0) }
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try encoder.encode(exportData)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            let fileName = "pulse-export-\(dateString).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try data.write(to: tempURL)
            
            return tempURL
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Export Projects (CSV)
    
    func exportProjectsCSV(projects: [Project]) -> URL? {
        isExporting = true
        defer { isExporting = false }
        
        var csv = "Name,Description,Health,Current Streak,Longest Streak,Total Touches,Last Touched,Created,Color\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for project in projects {
            let row = [
                escapeCSV(project.name),
                escapeCSV(project.projectDescription),
                project.healthLevel.displayName,
                "\(project.currentStreak)",
                "\(project.longestStreak)",
                "\(project.totalTouches)",
                dateFormatter.string(from: project.lastTouchedAt),
                dateFormatter.string(from: project.createdAt),
                project.colorHex
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            let fileName = "pulse-projects-\(dateString).csv"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            
            return tempURL
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Export Todos (CSV)
    
    func exportTodosCSV(todos: [Todo]) -> URL? {
        isExporting = true
        defer { isExporting = false }
        
        var csv = "Title,Notes,Priority,Due Date,Completed,Completed At,Created At\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for todo in todos {
            let row = [
                escapeCSV(todo.title),
                escapeCSV(todo.notes),
                todo.priority.rawValue,
                todo.dueDate.map { dateFormatter.string(from: $0) } ?? "",
                todo.isCompleted ? "Yes" : "No",
                todo.completedAt.map { dateFormatter.string(from: $0) } ?? "",
                dateFormatter.string(from: todo.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            let fileName = "pulse-todos-\(dateString).csv"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            
            return tempURL
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Helper
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}

// MARK: - Export Data Structures

struct PulseExportData: Codable {
    let exportDate: Date
    let version: String
    let projects: [ProjectExport]
    let todos: [TodoExport]
}

struct ProjectExport: Codable {
    let id: String
    let name: String
    let description: String
    let colorHex: String
    let iconName: String
    let createdAt: Date
    let lastTouchedAt: Date?
    let currentStreak: Int
    let longestStreak: Int
    let totalTouches: Int
    let healthLevel: String
    let isArchived: Bool
    let archivedAt: Date?
    
    init(from project: Project) {
        self.id = project.id.uuidString
        self.name = project.name
        self.description = project.projectDescription
        self.colorHex = project.colorHex
        self.iconName = project.iconName
        self.createdAt = project.createdAt
        self.lastTouchedAt = project.lastTouchedAt
        self.currentStreak = project.currentStreak
        self.longestStreak = project.longestStreak
        self.totalTouches = project.totalTouches
        self.healthLevel = project.healthLevel.displayName
        self.isArchived = project.isArchived
        self.archivedAt = project.archivedAt
    }
}

struct TodoExport: Codable {
    let id: String
    let title: String
    let notes: String
    let priority: String
    let createdAt: Date
    let dueDate: Date?
    let completedAt: Date?
    let linkedProjectID: String?
    
    init(from todo: Todo) {
        self.id = todo.id.uuidString
        self.title = todo.title
        self.notes = todo.notes
        self.priority = todo.priority.rawValue
        self.createdAt = todo.createdAt
        self.dueDate = todo.dueDate
        self.completedAt = todo.completedAt
        self.linkedProjectID = todo.linkedProjectID?.uuidString
    }
}

// MARK: - Share Sheet

struct ExportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export View

struct DataExportView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var exportManager = DataExportManager.shared
    
    let projects: [Project]
    let todos: [Todo]
    
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var selectedExportType: ExportType = .json
    
    enum ExportType: String, CaseIterable {
        case json = "Full Backup (JSON)"
        case projectsCSV = "Projects (CSV)"
        case todosCSV = "Todos (CSV)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.pulseAccent.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 32))
                            .foregroundColor(.pulseAccent)
                    }
                    .padding(.top, 20)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Export Your Data")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Your data belongs to you. Export it anytime.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Export options
                    VStack(spacing: 12) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            ExportOptionRow(
                                type: type,
                                isSelected: selectedExportType == type
                            ) {
                                selectedExportType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 30) {
                        ExportStatBadge(value: "\(projects.count)", label: "Projects")
                        ExportStatBadge(value: "\(todos.count)", label: "Tasks")
                    }
                    .padding(.vertical)
                    
                    Spacer()
                    
                    // Export button
                    Button {
                        performExport()
                    } label: {
                        HStack {
                            if exportManager.isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.pulseAccent)
                        .cornerRadius(14)
                    }
                    .disabled(exportManager.isExporting)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ExportShareSheet(items: [url])
                }
            }
        }
    }
    
    private func performExport() {
        switch selectedExportType {
        case .json:
            exportURL = exportManager.exportAllData(projects: projects, todos: todos)
        case .projectsCSV:
            exportURL = exportManager.exportProjectsCSV(projects: projects)
        case .todosCSV:
            exportURL = exportManager.exportTodosCSV(todos: todos)
        }
        
        if exportURL != nil {
            showingShareSheet = true
        }
    }
}

struct ExportOptionRow: View {
    let type: DataExportView.ExportType
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch type {
        case .json: return "doc.badge.gearshape"
        case .projectsCSV: return "folder"
        case .todosCSV: return "checkmark.circle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.pulseAccent)
                    .frame(width: 30)
                
                Text(type.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .pulseAccent : .white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.pulseAccent.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

struct ExportStatBadge: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview {
    DataExportView(projects: [], todos: [])
}
