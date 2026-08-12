//
//  DailyFocusOverlay.swift
//  Pulse
//
//  Morning overlay to pick your daily three
//

import SwiftUI
import SwiftData

struct DailyFocusOverlay: View {
    
    // MARK: - Binding
    
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Query
    
    @Query(
        filter: #Predicate<Project> { $0.archivedAt == nil },
        sort: [SortDescriptor(\Project.lastTouchedAt, order: .reverse)]
    )
    private var projects: [Project]
    
    // MARK: - State
    
    @State private var selectedProjectIDs: Set<UUID> = []
    @State private var animateIn = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap
                }
            
            // Content
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.pulseOrange)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                    
                    Text("Good Morning")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                    
                    Text("Which 3 projects get your energy today?")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
                .padding(.bottom, 8)
                
                // Project Selection
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                            FocusSelectionRow(
                                project: project,
                                isSelected: selectedProjectIDs.contains(project.id),
                                isDisabled: selectedProjectIDs.count >= 3 && !selectedProjectIDs.contains(project.id)
                            ) {
                                toggleSelection(project)
                            }
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.3 + Double(index) * 0.05),
                                value: animateIn
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 400)
                
                // Selection indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < selectedProjectIDs.count ? Color.pulseAccent : Color.white.opacity(0.2))
                            .frame(width: 10, height: 10)
                            .animation(.spring(), value: selectedProjectIDs.count)
                    }
                }
                .padding(.vertical, 8)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        saveFocus()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Let's Go")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedProjectIDs.isEmpty ? Color.pulseGray : Color.pulseAccent)
                        )
                    }
                    .disabled(selectedProjectIDs.isEmpty)
                    
                    Button {
                        skipFocus()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                .opacity(animateIn ? 1 : 0)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Methods
    
    private func toggleSelection(_ project: Project) {
        hapticEngine.playSelection()
        
        if selectedProjectIDs.contains(project.id) {
            selectedProjectIDs.remove(project.id)
        } else if selectedProjectIDs.count < 3 {
            selectedProjectIDs.insert(project.id)
        }
    }
    
    private func saveFocus() {
        let focus = DailyFocus(projectIDs: Array(selectedProjectIDs))
        modelContext.insert(focus)
        
        do {
            try modelContext.save()
            hapticEngine.playSuccess()
            onComplete()
            
            withAnimation {
                isPresented = false
            }
        } catch {
            print("Failed to save daily focus: \(error)")
        }
    }
    
    private func skipFocus() {
        hapticEngine.playTap()
        onComplete()
        
        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Focus Selection Row

struct FocusSelectionRow: View {
    let project: Project
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Orb
                ZStack {
                    Circle()
                        .fill(project.color.opacity(isDisabled ? 0.3 : 1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: project.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(isDisabled ? 0.5 : 0.9))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isDisabled ? .white.opacity(0.4) : .white)
                    
                    HStack(spacing: 8) {
                        // Health indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(project.healthLevel.color)
                                .frame(width: 6, height: 6)
                            Text(project.healthLevel.rawValue)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(project.healthLevel.color.opacity(isDisabled ? 0.5 : 0.8))
                        
                        // Streak
                        if project.currentStreak > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                Text("\(project.currentStreak)")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.orange.opacity(isDisabled ? 0.5 : 0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Selection
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.pulseAccent)
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? project.color.opacity(0.15) : Color.pulseCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? project.color.opacity(0.5) : Color.pulseBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .disabled(isDisabled && !isSelected)
    }
}

// MARK: - Preview

#Preview {
    DailyFocusOverlay(isPresented: .constant(true)) {
        print("Complete")
    }
    .environmentObject(HapticEngine.shared)
    .modelContainer(for: [Project.self, DailyFocus.self], inMemory: true)
}
