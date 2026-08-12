//
//  LogPulseSheet.swift
//  Pulse
//
//  Log a work session on a project
//

import SwiftUI
import SwiftData

struct LogPulseSheet: View {
    
    // MARK: - Properties
    
    let project: Project
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var intensityLevel: Int = 3
    @State private var notes: String = ""
    @State private var durationMinutes: Int = 30
    
    private let durations = [15, 30, 45, 60, 90, 120, 180]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Project Header
                projectHeader
                
                // Intensity Picker
                intensitySection
                
                // Duration Picker
                durationSection
                
                // Notes
                notesSection
                
                Spacer()
                
                // Log Button
                logButton
            }
            .padding()
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Log Work")
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
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(project.currentStreak) day streak")
                        .font(.system(size: 12))
                }
                .foregroundColor(.orange)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
    
    // MARK: - Intensity Section
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Intensity")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(intensityDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(intensityColor)
            }
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    IntensityButton(
                        level: level,
                        isSelected: intensityLevel == level,
                        color: project.color
                    ) {
                        hapticEngine.playSelection()
                        intensityLevel = level
                    }
                }
            }
            
            // Description
            Text(intensityDetailDescription)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseCardBackground)
        )
    }
    
    private var intensityDescription: String {
        switch intensityLevel {
        case 1: return "Light touch"
        case 2: return "Minor work"
        case 3: return "Solid session"
        case 4: return "Deep work"
        case 5: return "Major push"
        default: return ""
        }
    }
    
    private var intensityDetailDescription: String {
        switch intensityLevel {
        case 1: return "Quick check-in, minor update, or review"
        case 2: return "Small fixes, research, or planning"
        case 3: return "Good progress on features or tasks"
        case 4: return "Significant progress, focused deep work"
        case 5: return "Major milestone, breakthrough, or launch"
        default: return ""
        }
    }
    
    private var intensityColor: Color {
        switch intensityLevel {
        case 1: return .white.opacity(0.5)
        case 2: return .blue
        case 3: return .green
        case 4: return .orange
        case 5: return .red
        default: return .white
        }
    }
    
    // MARK: - Duration Section
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(durations, id: \.self) { duration in
                        DurationChip(
                            minutes: duration,
                            isSelected: durationMinutes == duration,
                            color: project.color
                        ) {
                            hapticEngine.playTap()
                            durationMinutes = duration
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("", text: $notes, prompt: Text("What did you work on?").foregroundColor(.white.opacity(0.3)), axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(3...5)
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
    
    // MARK: - Log Button
    
    private var logButton: some View {
        Button {
            logPulse()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Log Session")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(project.color)
                    .shadow(color: project.color.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Methods
    
    private func logPulse() {
        let entry = PulseEntry(
            intensityLevel: intensityLevel,
            notes: notes.isEmpty ? nil : notes,
            durationMinutes: durationMinutes
        )
        entry.project = project
        
        modelContext.insert(entry)
        
        // Touch the project
        project.touch()
        
        do {
            try modelContext.save()
            hapticEngine.playSuccess()
            dismiss()
        } catch {
            print("Failed to log pulse: \(error)")
        }
    }
}

// MARK: - Intensity Button

struct IntensityButton: View {
    let level: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    private var emoji: String {
        switch level {
        case 1: return "💨"
        case 2: return "⚡"
        case 3: return "🔥"
        case 4: return "💪"
        case 5: return "🚀"
        default: return "❓"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                
                Text("\(level)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.pulseBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    private var displayText: String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.pulseCardBackground)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color.pulseBorder, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Preview

#Preview {
    LogPulseSheet(project: PreviewData.healthyProject)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self, PulseEntry.self], inMemory: true)
}
