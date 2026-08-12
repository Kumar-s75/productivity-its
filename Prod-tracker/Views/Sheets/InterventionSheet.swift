//
//  InterventionSheet.swift
//  Pulse
//
//  Intervention mode for dying/dead projects
//

import SwiftUI
import SwiftData

struct InterventionSheet: View {
    
    // MARK: - Properties
    
    @Bindable var project: Project
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var selectedAction: InterventionAction?
    @State private var postMortem: String = ""
    @State private var lessonsLearned: String = ""
    @State private var showingConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning Header
                    warningHeader
                    
                    // Project Info
                    projectInfo
                    
                    // Action Options
                    actionOptions
                    
                    // Additional Info (if archiving)
                    if selectedAction == .kill || selectedAction == .complete {
                        archiveInfoSection
                    }
                    
                    Spacer(minLength: 24)
                    
                    // Action Button
                    actionButton
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle("Intervention")
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
            .alert("Confirm Action", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(confirmButtonText, role: selectedAction == .kill ? .destructive : nil) {
                    executeAction()
                }
            } message: {
                Text(confirmMessage)
            }
        }
    }
    
    // MARK: - Warning Header
    
    private var warningHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pulseRed.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.pulseRed)
            }
            
            Text("Is this project still alive?")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("This project hasn't been touched in \(project.daysSinceLastTouch) days.\nIt's time to make a decision.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Project Info
    
    private var projectInfo: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(project.color.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: project.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(project.color.opacity(0.7))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label("\(project.totalActiveDays) active days", systemImage: "calendar")
                    Label("\(project.longestStreak) best streak", systemImage: "flame")
                }
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(project.healthLevel.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Options
    
    private var actionOptions: some View {
        VStack(spacing: 12) {
            InterventionOption(
                action: .revive,
                isSelected: selectedAction == .revive,
                onTap: { selectAction(.revive) }
            )
            
            InterventionOption(
                action: .hibernate,
                isSelected: selectedAction == .hibernate,
                onTap: { selectAction(.hibernate) }
            )
            
            InterventionOption(
                action: .complete,
                isSelected: selectedAction == .complete,
                onTap: { selectAction(.complete) }
            )
            
            InterventionOption(
                action: .kill,
                isSelected: selectedAction == .kill,
                onTap: { selectAction(.kill) }
            )
        }
    }
    
    // MARK: - Archive Info Section
    
    private var archiveInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Post Mortem
            VStack(alignment: .leading, spacing: 8) {
                Text("Post Mortem (optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("", text: $postMortem, prompt: Text("What happened with this project?").foregroundColor(.white.opacity(0.3)), axis: .vertical)
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
            
            // Lessons Learned
            VStack(alignment: .leading, spacing: 8) {
                Text("Lessons Learned (optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("", text: $lessonsLearned, prompt: Text("What did you learn?").foregroundColor(.white.opacity(0.3)), axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(3...5)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pulseAccent.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pulseAccent.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            showingConfirmation = true
        } label: {
            HStack {
                if let action = selectedAction {
                    Image(systemName: action.icon)
                    Text(action.buttonText)
                } else {
                    Text("Select an action")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonColor)
            )
        }
        .disabled(selectedAction == nil)
    }
    
    private var buttonColor: Color {
        guard let action = selectedAction else {
            return Color.pulseGray
        }
        return action.color
    }
    
    private var confirmButtonText: String {
        selectedAction?.buttonText ?? "Confirm"
    }
    
    private var confirmMessage: String {
        guard let action = selectedAction else { return "" }
        
        switch action {
        case .revive:
            return "This will reset your streak and mark the project as active."
        case .hibernate:
            return "This will move the project to hibernation. You can wake it up later."
        case .complete:
            return "Congratulations! This will archive the project as completed."
        case .kill:
            return "This will archive the project. You can revive it later if needed."
        }
    }
    
    // MARK: - Methods
    
    private func selectAction(_ action: InterventionAction) {
        hapticEngine.playSelection()
        withAnimation {
            selectedAction = action
        }
    }
    
    private func executeAction() {
        guard let action = selectedAction else { return }
        
        switch action {
        case .revive:
            project.revive()
            hapticEngine.playSuccess()
            
        case .hibernate:
            project.archive(
                reason: .hibernating,
                postMortem: postMortem.isEmpty ? nil : postMortem,
                lessons: lessonsLearned.isEmpty ? nil : lessonsLearned
            )
            hapticEngine.playTap()
            
        case .complete:
            project.archive(
                reason: .completed,
                postMortem: postMortem.isEmpty ? nil : postMortem,
                lessons: lessonsLearned.isEmpty ? nil : lessonsLearned
            )
            hapticEngine.playSuccess()
            
        case .kill:
            project.archive(
                reason: .killed,
                postMortem: postMortem.isEmpty ? nil : postMortem,
                lessons: lessonsLearned.isEmpty ? nil : lessonsLearned
            )
            hapticEngine.playProjectKilled()
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Intervention Action

enum InterventionAction {
    case revive
    case hibernate
    case complete
    case kill
    
    var title: String {
        switch self {
        case .revive: return "Yes, I'll revive it"
        case .hibernate: return "Hibernating"
        case .complete: return "Actually, it's done!"
        case .kill: return "Kill it"
        }
    }
    
    var description: String {
        switch self {
        case .revive: return "Schedule focus time and get back to work"
        case .hibernate: return "Move to cold storage, stop pulsing"
        case .complete: return "Archive as a success"
        case .kill: return "Archive with a post-mortem"
        }
    }
    
    var icon: String {
        switch self {
        case .revive: return "arrow.clockwise.heart"
        case .hibernate: return "moon.zzz.fill"
        case .complete: return "checkmark.circle.fill"
        case .kill: return "xmark.circle.fill"
        }
    }
    
    var buttonText: String {
        switch self {
        case .revive: return "Revive Project"
        case .hibernate: return "Hibernate Project"
        case .complete: return "Mark Complete"
        case .kill: return "Kill Project"
        }
    }
    
    var color: Color {
        switch self {
        case .revive: return .pulseGreen
        case .hibernate: return .pulseAccent
        case .complete: return .pulseGreen
        case .kill: return .pulseRed
        }
    }
}

// MARK: - Intervention Option

struct InterventionOption: View {
    let action: InterventionAction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 20))
                    .foregroundColor(action.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(action.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? action.color : .white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? action.color.opacity(0.1) : Color.pulseCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? action.color.opacity(0.5) : Color.pulseBorder, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    InterventionSheet(project: PreviewData.dyingProject)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
