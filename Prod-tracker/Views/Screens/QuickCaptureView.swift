//
//  QuickCaptureView.swift
//  Pulse
//
//  Apple Notes-style quick capture for ideas, thoughts, tasks
//

import SwiftUI
import SwiftData

struct QuickCaptureView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var content: String = ""
    @State private var captureType: CaptureType = .thought
    @State private var selectedProjectID: UUID?
    @State private var showProjectPicker = false
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Type selector
                    typeSelector
                        .padding()
                    
                    // Main input area
                    inputArea
                    
                    Spacer()
                    
                    // Bottom toolbar
                    bottomToolbar
                }
            }
            .navigationTitle("Quick Capture")
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
                        saveCapture()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(content.isEmpty ? .white.opacity(0.3) : .pulseAccent)
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
    
    // MARK: - Type Selector
    
    private var typeSelector: some View {
        HStack(spacing: 10) {
            ForEach(CaptureType.allCases, id: \.self) { type in
                Button {
                    captureType = type
                    hapticEngine.playTap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                        Text(type.label)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(captureType == type ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(captureType == type ? type.color.opacity(0.3) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        Capsule()
                            .stroke(captureType == type ? type.color.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Placeholder with icon
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: captureType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(captureType.color)
                    .frame(width: 30)
                
                TextEditor(text: $content)
                    .focused($isFocused)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text(captureType.placeholder)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.3))
                                .allowsHitTesting(false)
                        }
                    }
            }
            
            // Project link
            if let projectID = selectedProjectID,
               let project = activeProjects.first(where: { $0.id == projectID }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(project.color)
                        .frame(width: 10, height: 10)
                    
                    Text(project.name)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button {
                        selectedProjectID = nil
                        hapticEngine.playTap()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(project.color.opacity(0.15))
                )
            }
        }
        .padding()
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Link to project
            Button {
                showProjectPicker.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedProjectID != nil ? "link.circle.fill" : "link.circle")
                        .font(.system(size: 20))
                    
                    if selectedProjectID == nil {
                        Text("Link to project")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(selectedProjectID != nil ? .pulseAccent : .white.opacity(0.5))
            }
            
            Spacer()
            
            // Character count
            Text("\(content.count)")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .sheet(isPresented: $showProjectPicker) {
            projectPickerSheet
        }
    }
    
    // MARK: - Project Picker Sheet
    
    private var projectPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 8) {
                        // None option
                        Button {
                            selectedProjectID = nil
                            showProjectPicker = false
                            hapticEngine.playTap()
                        } label: {
                            HStack {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No project")
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                if selectedProjectID == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.pulseAccent)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                        
                        // Projects
                        ForEach(activeProjects) { project in
                            Button {
                                selectedProjectID = project.id
                                showProjectPicker = false
                                hapticEngine.playTap()
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(project.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(project.name)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedProjectID == project.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.pulseAccent)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedProjectID == project.id ? project.color.opacity(0.2) : Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Link to Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showProjectPicker = false
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Methods
    
    private func saveCapture() {
        let capture = QuickCapture(
            content: content,
            type: captureType,
            linkedProjectID: selectedProjectID
        )
        
        modelContext.insert(capture)
        
        // Touch linked project
        if let projectID = selectedProjectID,
           let project = activeProjects.first(where: { $0.id == projectID }) {
            project.touch()
        }
        
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    QuickCaptureView()
        .modelContainer(for: [QuickCapture.self, Project.self])
        .environmentObject(HapticEngine.shared)
}
