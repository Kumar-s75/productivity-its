//
//  MoodCheckInView.swift
//  Pulse
//
//  Beautiful mood tracking with project correlation insights
//

import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(sort: \MoodEntry.date, order: .reverse)
    private var moodEntries: [MoodEntry]
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var selectedMood: Mood?
    @State private var selectedEnergy: Int = 3
    @State private var note: String = ""
    @State private var selectedProjects: Set<UUID> = []
    @State private var showingHistory = false
    @State private var animateEmojis = false
    @State private var showConfetti = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Greeting
                        greetingSection
                        
                        // Mood selector
                        moodSelector
                        
                        // Energy level
                        if selectedMood != nil {
                            energySelector
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Project correlation
                        if selectedMood != nil {
                            projectSelector
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Note
                        if selectedMood != nil {
                            noteSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        
                        // Save button
                        if selectedMood != nil {
                            saveButton
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
                
                // Confetti
                ConfettiView(isActive: $showConfetti, intensity: .medium)
            }
            .navigationTitle("Check In")
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
                        showingHistory = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                MoodHistoryView()
            }
            .onAppear {
                withAnimation(.spring(response: 0.6).delay(0.3)) {
                    animateEmojis = true
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Color.pulseBackground
            
            // Mood-based gradient
            if let mood = selectedMood {
                RadialGradient(
                    colors: [mood.color.opacity(0.3), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: selectedMood)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        VStack(spacing: 8) {
            Text(greetingText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("How are you feeling right now?")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 20)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning ☀️"
        case 12..<17: return "Good Afternoon 🌤"
        case 17..<21: return "Good Evening 🌅"
        default: return "Good Night 🌙"
        }
    }
    
    // MARK: - Mood Selector
    
    private var moodSelector: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(Mood.allCases, id: \.self) { mood in
                    MoodSelectionButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        animate: animateEmojis
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedMood = mood
                        }
                        hapticEngine.playTap()
                    }
                }
            }
            
            // Selected mood label
            if let mood = selectedMood {
                Text(mood.label)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mood.color)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Energy Selector
    
    private var energySelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("Energy Level")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        selectedEnergy = level
                        hapticEngine.playTap()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: level <= selectedEnergy ? "bolt.fill" : "bolt")
                                .font(.system(size: 24))
                                .foregroundColor(level <= selectedEnergy ? .yellow : .white.opacity(0.3))
                            
                            Text(energyLabel(for: level))
                                .font(.system(size: 10))
                                .foregroundColor(level == selectedEnergy ? .white : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(level == selectedEnergy ? Color.yellow.opacity(0.2) : Color.white.opacity(0.05))
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func energyLabel(for level: Int) -> String {
        switch level {
        case 1: return "Drained"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Energized"
        default: return ""
        }
    }
    
    // MARK: - Project Selector
    
    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.pulseAccent)
                Text("What influenced your mood?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Select projects you worked on")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
            
            MoodFlowLayout(spacing: 10) {
                ForEach(activeProjects) { project in
                    ProjectChip(
                        project: project,
                        isSelected: selectedProjects.contains(project.id)
                    ) {
                        if selectedProjects.contains(project.id) {
                            selectedProjects.remove(project.id)
                        } else {
                            selectedProjects.insert(project.id)
                        }
                        hapticEngine.playTap()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Note Section
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(.white.opacity(0.6))
                Text("Add a note (optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            TextField("What's on your mind?", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveMoodEntry()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save Check-In")
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedMood?.color ?? .pulseAccent)
            )
        }
        .padding(.top, 10)
    }
    
    // MARK: - Methods
    
    private func saveMoodEntry() {
        guard let mood = selectedMood else { return }
        
        let entry = MoodEntry(
            mood: mood,
            energyLevel: selectedEnergy,
            note: note.isEmpty ? nil : note,
            projectIDs: Array(selectedProjects)
        )
        
        modelContext.insert(entry)
        
        hapticEngine.playSuccess()
        showConfetti = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
}

// MARK: - Mood Selection Button

struct MoodSelectionButton: View {
    let mood: Mood
    let isSelected: Bool
    let animate: Bool
    let action: () -> Void
    
    @State private var bounceAnimation = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .scaleEffect(bounceAnimation ? 1.1 : 1.0)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(isSelected ? mood.color.opacity(0.3) : Color.white.opacity(0.05))
            )
            .overlay(
                Circle()
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .scaleEffect(animate ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6)
            .delay(Double(Mood.allCases.firstIndex(of: mood) ?? 0) * 0.05),
            value: animate
        )
        .onChange(of: isSelected) { _, selected in
            if selected {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation {
                        bounceAnimation = false
                    }
                }
            }
        }
    }
}

// MARK: - Project Chip

struct ProjectChip: View {
    let project: Project
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(project.color)
                    .frame(width: 10, height: 10)
                
                Text(project.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? project.color.opacity(0.5) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? project.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Flow Layout

struct MoodFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                self.size.width = max(self.size.width, currentX)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

// MARK: - Mood History View

struct MoodHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \MoodEntry.date, order: .reverse)
    private var moodEntries: [MoodEntry]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                if moodEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No mood entries yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Weekly chart placeholder
                            weeklyChart
                            
                            // Entries list
                            ForEach(moodEntries) { entry in
                                MoodEntryRow(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date())!
                    let entry = moodEntries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
                    
                    VStack(spacing: 6) {
                        if let entry = entry {
                            Text(entry.mood.emoji)
                                .font(.system(size: 20))
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(dayLabel(for: date))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Mood Entry Row

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Mood emoji
            Text(entry.mood.emoji)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(entry.mood.color.opacity(0.2))
                )
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.mood.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(entry.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Energy
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= entry.energyLevel ? "bolt.fill" : "bolt")
                            .font(.system(size: 10))
                            .foregroundColor(level <= entry.energyLevel ? .yellow : .white.opacity(0.2))
                    }
                }
                
                // Note
                if let note = entry.note {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    MoodCheckInView()
        .modelContainer(for: [MoodEntry.self, Project.self])
        .environmentObject(HapticEngine.shared)
}
