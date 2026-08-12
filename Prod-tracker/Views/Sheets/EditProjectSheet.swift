//
//  EditProjectSheet.swift
//  Pulse
//
//  Sheet for editing an existing project
//

import SwiftUI
import SwiftData

struct EditProjectSheet: View {
    
    // MARK: - Properties
    
    @Bindable var project: Project
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var projectName: String = ""
    @State private var projectDescription: String = ""
    @State private var selectedColorIndex: Int = 0
    @State private var selectedIcon: String = "folder.fill"
    @State private var showingIconPicker = false
    @State private var githubURL: String = ""
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Orb
                    previewSection
                    
                    // Name Input
                    nameSection
                    
                    // Description
                    descriptionSection
                    
                    // Color Picker
                    colorSection
                    
                    // Icon Picker
                    iconSection
                    
                    // Integrations
                    integrationsSection
                    
                    // Delete Section
                    deleteSection
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(projectName.isEmpty ? .white.opacity(0.3) : .pulseAccent)
                    .disabled(projectName.isEmpty)
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingIconPicker) {
                IconPickerSheet(selectedIcon: $selectedIcon)
            }
            .alert("Delete Project?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteProject()
                }
            } message: {
                Text("This will permanently delete '\(project.name)' and all its data. This action cannot be undone.")
            }
            .onAppear {
                loadProjectData()
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow
                Circle()
                    .fill(selectedColor.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // Orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [selectedColor.opacity(0.9), selectedColor.opacity(0.6)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Text(projectName.isEmpty ? "Project Name" : projectName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(projectName.isEmpty ? .white.opacity(0.3) : .white)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("", text: $projectName, prompt: Text("My Awesome Project").foregroundColor(.white.opacity(0.3)))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("", text: $projectDescription, prompt: Text("What's this project about?").foregroundColor(.white.opacity(0.3)), axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(3...6)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Color Section
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
                ForEach(0..<Color.projectColors.count, id: \.self) { index in
                    ColorDot(
                        color: Color.projectColors[index],
                        isSelected: selectedColorIndex == index
                    ) {
                        hapticEngine.playSelection()
                        selectedColorIndex = index
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pulseCardBackground)
            )
        }
    }
    
    // MARK: - Icon Section
    
    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Button {
                showingIconPicker = true
            } label: {
                HStack {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedColor)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedColor.opacity(0.2))
                        )
                    
                    Text("Change Icon")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Integrations Section
    
    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integrations")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24)
                    
                    TextField("", text: $githubURL, prompt: Text("GitHub repo URL").foregroundColor(.white.opacity(0.3)))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Project")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.pulseRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pulseRed.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pulseRed.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 12)
    }
    
    // MARK: - Computed Properties
    
    private var selectedColor: Color {
        Color.projectColors[selectedColorIndex]
    }
    
    private var selectedColorHex: String {
        Color.projectColorHexes[selectedColorIndex]
    }
    
    // MARK: - Methods
    
    private func loadProjectData() {
        projectName = project.name
        projectDescription = project.projectDescription
        selectedIcon = project.iconName
        githubURL = project.githubRepoURL ?? ""
        
        // Find color index
        if let index = Color.projectColorHexes.firstIndex(of: project.colorHex) {
            selectedColorIndex = index
        }
    }
    
    private func saveChanges() {
        project.name = projectName
        project.projectDescription = projectDescription
        project.colorHex = selectedColorHex
        project.iconName = selectedIcon
        project.githubRepoURL = githubURL.isEmpty ? nil : githubURL
        
        do {
            try modelContext.save()
            hapticEngine.playSuccess()
            dismiss()
        } catch {
            print("Failed to save project: \(error)")
        }
    }
    
    private func deleteProject() {
        modelContext.delete(project)
        hapticEngine.playProjectKilled()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete project: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    EditProjectSheet(project: PreviewData.healthyProject)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
