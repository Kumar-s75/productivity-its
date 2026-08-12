//
//  ReflectionSheet.swift
//  Pulse
//
//  End of day reflection on focus projects
//

import SwiftUI
import SwiftData

struct ReflectionSheet: View {
    
    // MARK: - Properties
    
    var focus: DailyFocus?
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var reflectionText: String = ""
    @State private var overallMood: ReflectionMood = .neutral
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Completion Summary
                    if let focus = focus {
                        completionSummary(focus)
                    }
                    
                    // Mood Selector
                    moodSection
                    
                    // Reflection Text
                    reflectionTextSection
                    
                    Spacer(minLength: 24)
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(.pulseAccent)
            
            Text("How was your day?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Take a moment to reflect on your progress")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.vertical)
    }
    
    // MARK: - Completion Summary
    
    private func completionSummary(_ focus: DailyFocus) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Focus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(focus.completedProjectIDs.count)/\(focus.projectIDs.count) completed")
                    .font(.system(size: 12))
                    .foregroundColor(focus.completedProjectIDs.count == focus.projectIDs.count ? .pulseGreen : .white.opacity(0.5))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.pulseGreen)
                        .frame(width: geometry.size.width * focus.completionPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
        )
    }
    
    // MARK: - Mood Section
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How do you feel?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(ReflectionMood.allCases, id: \.self) { mood in
                    ReflectionMoodButton(
                        mood: mood,
                        isSelected: overallMood == mood
                    ) {
                        hapticEngine.playSelection()
                        overallMood = mood
                    }
                }
            }
        }
    }
    
    // MARK: - Reflection Text
    
    private var reflectionTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reflection (optional)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("", text: $reflectionText, prompt: Text("What went well? What could be better?").foregroundColor(.white.opacity(0.3)), axis: .vertical)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(5...10)
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
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveReflection()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Reflection")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pulseAccent)
            )
        }
    }
    
    // MARK: - Methods
    
    private func saveReflection() {
        if let focus = focus {
            focus.reflectionNote = reflectionText.isEmpty ? nil : reflectionText
            try? modelContext.save()
        }
        
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Reflection Mood

enum ReflectionMood: String, CaseIterable {
    case terrible = "Terrible"
    case bad = "Bad"
    case neutral = "Okay"
    case good = "Good"
    case great = "Great"
    
    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😔"
        case .neutral: return "😐"
        case .good: return "😊"
        case .great: return "🤩"
        }
    }
    
    var color: Color {
        switch self {
        case .terrible: return .red
        case .bad: return .orange
        case .neutral: return .yellow
        case .good: return .green
        case .great: return .pulseAccent
        }
    }
}

// MARK: - Mood Button

struct ReflectionMoodButton: View {
    let mood: ReflectionMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                
                Text(mood.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color.opacity(0.2) : Color.pulseCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? mood.color : Color.pulseBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ReflectionSheet(focus: nil)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [DailyFocus.self], inMemory: true)
}
