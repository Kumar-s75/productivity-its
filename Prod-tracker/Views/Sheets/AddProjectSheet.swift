//
//  AddProjectSheet.swift
//  Pulse
//
//  Sheet for adding a new project
//

import SwiftUI
import SwiftData

struct AddProjectSheet: View {
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var projectName: String = ""
    @State private var projectDescription: String = ""
    @State private var selectedColorIndex: Int = 5
    @State private var selectedIcon: String = "folder.fill"
    @State private var showingIconPicker = false
    
    // GitHub integration
    @State private var githubURL: String = ""
    
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
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProject()
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
            
            if !projectName.isEmpty {
                Text(projectName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text("Project Name")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
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
            Text("Description (optional)")
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
            Text("Integrations (optional)")
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
    
    // MARK: - Computed Properties
    
    private var selectedColor: Color {
        Color.projectColors[selectedColorIndex]
    }
    
    private var selectedColorHex: String {
        Color.projectColorHexes[selectedColorIndex]
    }
    
    // MARK: - Methods
    
    private func createProject() {
        let project = Project(
            name: projectName,
            description: projectDescription,
            colorHex: selectedColorHex,
            iconName: selectedIcon
        )
        
        if !githubURL.isEmpty {
            project.githubRepoURL = githubURL
        }
        
        modelContext.insert(project)
        
        do {
            try modelContext.save()
            hapticEngine.playSuccess()
            dismiss()
        } catch {
            print("Failed to save project: \(error)")
        }
    }
}

// MARK: - Color Dot

struct ColorDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// MARK: - Icon Picker Sheet

struct IconPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    private let icons: [String] = [
        // Development
        "folder.fill", "doc.fill", "doc.text.fill", "terminal.fill",
        "chevron.left.forwardslash.chevron.right", "cpu.fill", "memorychip.fill", "apps.iphone",
        
        // Creative
        "paintbrush.fill", "pencil.tip", "photo.fill", "camera.fill",
        "film.fill", "music.note", "headphones", "gamecontroller.fill",
        
        // Business
        "chart.bar.fill", "chart.pie.fill", "briefcase.fill", "building.2.fill",
        "cart.fill", "creditcard.fill", "dollarsign.circle.fill", "person.3.fill",
        
        // Education
        "book.fill", "graduationcap.fill", "brain.head.profile", "lightbulb.fill",
        "text.book.closed.fill", "bookmark.fill", "note.text", "list.bullet.rectangle.fill",
        
        // Health & Fitness
        "heart.fill", "figure.run", "dumbbell.fill", "leaf.fill",
        "cross.fill", "pill.fill", "bed.double.fill", "cup.and.saucer.fill",
        
        // Travel & Places
        "airplane", "car.fill", "house.fill", "globe.americas.fill",
        "map.fill", "location.fill", "mountain.2.fill", "sun.max.fill",
        
        // Social
        "bubble.left.fill", "envelope.fill", "phone.fill", "video.fill",
        "person.fill", "hand.wave.fill", "star.fill", "hand.thumbsup.fill",
        
        // Objects
        "wrench.fill", "hammer.fill", "key.fill", "lock.fill",
        "flag.fill", "tag.fill", "bell.fill", "clock.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon
                        ) {
                            hapticEngine.playSelection()
                            selectedIcon = icon
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .pulseAccent : .white.opacity(0.7))
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.pulseAccent.opacity(0.2) : Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.pulseAccent : Color.pulseBorder, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    AddProjectSheet()
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
