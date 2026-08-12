//
//  VoicePulseView.swift
//  Pulse
//
//  Voice-first capture - record thoughts, transcribe, link to projects
//

import SwiftUI
import SwiftData
import AVFoundation
import Combine

struct VoicePulseView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var recordingTime: TimeInterval = 0
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.3, count: 40)
    @State private var selectedProjectID: UUID?
    @State private var transcription: String = ""
    @State private var isTranscribing = false
    @State private var showSaveOptions = false
    @State private var pulseAnimation = false
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    if !showSaveOptions {
                        // Recording interface
                        recordingInterface
                    } else {
                        // Save options
                        saveOptionsInterface
                    }
                }
            }
            .navigationTitle(showSaveOptions ? "Save Recording" : "Voice Pulse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if isRecording {
                            // Confirm discard
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .onReceive(timer) { _ in
                if isRecording && !isPaused {
                    recordingTime += 0.1
                    updateAudioLevels()
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color.pulseBackground
            
            // Animated gradient when recording
            if isRecording {
                RadialGradient(
                    colors: [Color.red.opacity(0.3), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Recording Interface
    
    private var recordingInterface: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Waveform visualization
            waveformView
            
            // Time display
            Text(formatTime(recordingTime))
                .font(.system(size: 48, weight: .light, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
            
            // Status
            Text(statusText)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Controls
            recordingControls
            
            // Project selector
            projectSelector
                .padding(.bottom, 30)
        }
        .padding()
    }
    
    // MARK: - Waveform View
    
    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<audioLevels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: isRecording ? [.red, .orange] : [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: audioLevels[index] * 100)
                    .animation(.easeOut(duration: 0.1), value: audioLevels[index])
            }
        }
        .frame(height: 100)
    }
    
    // MARK: - Recording Controls
    
    private var recordingControls: some View {
        HStack(spacing: 40) {
            // Cancel/Reset
            Button {
                if isRecording {
                    stopRecording()
                    recordingTime = 0
                    audioLevels = Array(repeating: 0.3, count: 40)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(isRecording ? 0.7 : 0.3))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .disabled(!isRecording)
            
            // Main record button
            Button {
                if isRecording {
                    finishRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 88, height: 88)
                    
                    // Pulsing ring when recording
                    if isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation ? 1.2 : 1)
                    }
                    
                    // Inner button
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 72, height: 72)
                    }
                }
            }
            
            // Pause/Resume
            Button {
                isPaused.toggle()
                hapticEngine.playTap()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(isRecording ? 0.7 : 0.3))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .disabled(!isRecording)
        }
    }
    
    // MARK: - Project Selector
    
    private var projectSelector: some View {
        VStack(spacing: 12) {
            Text("Link to Project")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // None option
                    Button {
                        selectedProjectID = nil
                        hapticEngine.playTap()
                    } label: {
                        Text("None")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedProjectID == nil ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedProjectID == nil ? Color.pulseAccent : Color.white.opacity(0.08))
                            )
                    }
                    
                    ForEach(activeProjects) { project in
                        Button {
                            selectedProjectID = project.id
                            hapticEngine.playTap()
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(project.color)
                                    .frame(width: 8, height: 8)
                                Text(project.name)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedProjectID == project.id ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedProjectID == project.id ? project.color.opacity(0.5) : Color.white.opacity(0.08))
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Save Options Interface
    
    private var saveOptionsInterface: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Recording summary
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.pulseAccent)
                    
                    Text(formatTime(recordingTime))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Voice Recording")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 40)
                
                // Transcription
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.white.opacity(0.5))
                        Text("Transcription")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isTranscribing {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    
                    if isTranscribing {
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(Color.pulseAccent)
                                    .frame(width: 8, height: 8)
                                    .opacity(pulseAnimation ? 1 : 0.3)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(i) * 0.2),
                                        value: pulseAnimation
                                    )
                            }
                            Text("Transcribing...")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    } else if transcription.isEmpty {
                        Text("Transcription will appear here...")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.3))
                            .italic()
                    } else {
                        TextEditor(text: $transcription)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Linked project
                if let projectID = selectedProjectID,
                   let project = activeProjects.first(where: { $0.id == projectID }) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(project.color)
                            .frame(width: 12, height: 12)
                        
                        Text("Linked to \(project.name)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Button {
                            selectedProjectID = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(project.color.opacity(0.15))
                    )
                }
                
                // Save actions
                VStack(spacing: 12) {
                    Button {
                        saveVoicePulse()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Voice Pulse")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.pulseAccent)
                        )
                    }
                    
                    Button {
                        showSaveOptions = false
                        recordingTime = 0
                        transcription = ""
                    } label: {
                        Text("Discard & Record Again")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // MARK: - Computed
    
    private var statusText: String {
        if isRecording {
            return isPaused ? "Paused" : "Recording..."
        }
        return "Tap to start recording"
    }
    
    // MARK: - Methods
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
    
    private func updateAudioLevels() {
        // Simulate audio levels (in real implementation, use AVAudioRecorder.averagePower)
        for i in 0..<audioLevels.count {
            let newLevel = CGFloat.random(in: 0.2...1.0)
            audioLevels[i] = audioLevels[i] * 0.7 + newLevel * 0.3
        }
    }
    
    private func startRecording() {
        isRecording = true
        isPaused = false
        hapticEngine.playTap()
        
        // In real implementation:
        // - Request microphone permission
        // - Start AVAudioRecorder
    }
    
    private func stopRecording() {
        isRecording = false
        isPaused = false
        hapticEngine.playTap()
    }
    
    private func finishRecording() {
        stopRecording()
        showSaveOptions = true
        startTranscription()
        hapticEngine.playSuccess()
    }
    
    private func startTranscription() {
        isTranscribing = true
        
        // Simulate transcription delay (in real implementation, use Speech framework)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isTranscribing = false
            transcription = "This is a sample transcription of your voice recording. In the actual app, this would use Apple's Speech framework to transcribe your audio in real-time or after recording."
        }
    }
    
    private func saveVoicePulse() {
        // Create voice pulse entry
        let voicePulse = VoicePulse(
            duration: recordingTime,
            transcription: transcription.isEmpty ? nil : transcription,
            linkedProjectID: selectedProjectID
        )
        
        modelContext.insert(voicePulse)
        
        // Touch linked project
        if let projectID = selectedProjectID,
           let project = activeProjects.first(where: { $0.id == projectID }) {
            project.touch()
            
            // Create pulse entry
            let pulseEntry = PulseEntry(
                date: Date(),
                intensityLevel: 3,
                notes: "🎤 Voice: \(transcription.prefix(100))...",
                durationMinutes: Int(recordingTime / 60)
            )
            pulseEntry.project = project
            modelContext.insert(pulseEntry)
        }
        
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    VoicePulseView()
        .modelContainer(for: [VoicePulse.self, Project.self, PulseEntry.self])
        .environmentObject(HapticEngine.shared)
}
