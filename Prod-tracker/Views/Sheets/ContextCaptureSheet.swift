//
//  ContextCaptureSheet.swift
//  Pulse
//
//  Capture where you left off on a project
//

import SwiftUI
import SwiftData

struct ContextCaptureSheet: View {
    
    // MARK: - Properties
    
    let project: Project
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var contextText: String = ""
    @State private var isRecording: Bool = false
    @State private var captureType: SnapshotType = .manual
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Project Header
                projectHeader
                
                // Capture Mode Toggle
                captureModeToggle
                
                // Input Area
                if captureType == .manual {
                    textInputArea
                } else {
                    voiceInputArea
                }
                
                // Previous Snapshots
                previousSnapshotsSection
                
                Spacer()
                
                // Save Button
                saveButton
            }
            .padding()
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Capture Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Project Header
    
    private var projectHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(project.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: project.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Where did you leave off?")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
    
    // MARK: - Capture Mode Toggle
    
    private var captureModeToggle: some View {
        HStack(spacing: 0) {
            CaptureTabButton(
                title: "Text",
                icon: "text.bubble.fill",
                isSelected: captureType == .manual
            ) {
                withAnimation {
                    captureType = .manual
                }
            }
            
            CaptureTabButton(
                title: "Voice",
                icon: "mic.fill",
                isSelected: captureType == .voiceNote
            ) {
                withAnimation {
                    captureType = .voiceNote
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.pulseCardBackground)
        )
    }
    
    // MARK: - Text Input Area
    
    private var textInputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: $contextText, prompt: Text("I was working on...").foregroundColor(.white.opacity(0.3)), axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(5...10)
                .focused($isTextFieldFocused)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
            
            // Quick suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    QuickSuggestionChip(text: "Debugging") {
                        contextText += (contextText.isEmpty ? "" : " ") + "Debugging"
                    }
                    QuickSuggestionChip(text: "Building feature") {
                        contextText += (contextText.isEmpty ? "" : " ") + "Building feature:"
                    }
                    QuickSuggestionChip(text: "Fixing bug in") {
                        contextText += (contextText.isEmpty ? "" : " ") + "Fixing bug in"
                    }
                    QuickSuggestionChip(text: "Researching") {
                        contextText += (contextText.isEmpty ? "" : " ") + "Researching"
                    }
                    QuickSuggestionChip(text: "Waiting on") {
                        contextText += (contextText.isEmpty ? "" : " ") + "Waiting on"
                    }
                }
            }
        }
    }
    
    // MARK: - Voice Input Area
    
    private var voiceInputArea: some View {
        VStack(spacing: 20) {
            // Recording visualization
            ZStack {
                // Background circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.pulseAccent.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(100 + index * 30), height: CGFloat(100 + index * 30))
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(
                            isRecording ?
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2) :
                                .default,
                            value: isRecording
                        )
                }
                
                // Record button
                Button {
                    toggleRecording()
                } label: {
                    Circle()
                        .fill(isRecording ? Color.pulseRed : Color.pulseAccent)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        )
                        .shadow(color: (isRecording ? Color.pulseRed : Color.pulseAccent).opacity(0.5), radius: 10)
                }
            }
            .frame(height: 180)
            
            Text(isRecording ? "Recording... Tap to stop" : "Tap to record")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            // Transcription preview (if available)
            if !contextText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Transcription", systemImage: "text.quote")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(contextText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pulseCardBackground)
                        )
                }
            }
        }
    }
    
    // MARK: - Previous Snapshots
    
    private var previousSnapshotsSection: some View {
        Group {
            if let snapshots = project.contextSnapshots, !snapshots.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Previous")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ForEach(snapshots.prefix(2)) { snapshot in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: snapshot.snapshotType.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(snapshot.displayContent)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(2)
                                
                                Text(snapshot.timeAgo)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveContext()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Context")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(contextText.isEmpty ? Color.pulseGray : project.color)
            )
        }
        .disabled(contextText.isEmpty)
    }
    
    // MARK: - Methods
    
    private func toggleRecording() {
        hapticEngine.playTap()
        isRecording.toggle()
        
        if isRecording {
            // Start recording
            // TODO: Implement actual audio recording
        } else {
            // Stop recording and transcribe
            // TODO: Implement transcription
            // For now, simulate with placeholder
            contextText = "Sample voice note transcription..."
        }
    }
    
    private func saveContext() {
        let snapshot = ContextSnapshot(
            content: contextText,
            type: captureType
        )
        snapshot.project = project
        
        modelContext.insert(snapshot)
        
        // Also touch the project
        project.touch()
        
        do {
            try modelContext.save()
            hapticEngine.playSuccess()
            dismiss()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Capture Tab Button

struct CaptureTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.pulseAccent : Color.clear)
            )
        }
    }
}

// MARK: - Quick Suggestion Chip

struct QuickSuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.pulseCardBackground)
                        .overlay(
                            Capsule()
                                .stroke(Color.pulseBorder, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ContextCaptureSheet(project: PreviewData.healthyProject)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self, ContextSnapshot.self], inMemory: true)
}
