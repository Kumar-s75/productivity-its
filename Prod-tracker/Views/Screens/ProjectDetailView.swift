//
//  ProjectDetailView.swift
//  Pulse
//
//  Detailed project view with context, milestones, and actions
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    
    // MARK: - Properties
    
    @Bindable var project: Project
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var showingContextCapture = false
    @State private var showingLogPulse = false
    @State private var showingIntervention = false
    @State private var showingEditProject = false
    @State private var isPulsing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Hero Orb
                    heroSection
                    
                    // Stats Cards
                    statsSection
                    
                    // Latest Context
                    contextSection
                    
                    // Quick Actions
                    actionsSection
                    
                    // Integrations
                    if hasIntegrations {
                        integrationsSection
                    }
                    
                    // Milestones
                    milestonesSection
                    
                    // Danger Zone
                    dangerSection
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProject = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingContextCapture) {
                ContextCaptureSheet(project: project)
            }
            .sheet(isPresented: $showingLogPulse) {
                LogPulseSheet(project: project)
            }
            .sheet(isPresented: $showingIntervention) {
                InterventionSheet(project: project)
            }
            .sheet(isPresented: $showingEditProject) {
                EditProjectSheet(project: project)
            }
            .onAppear {
                startPulsing()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Orb
            PulseOrbView(
                project: project,
                size: 120,
                showLabel: false
            )
            .onTapGesture {
                hapticEngine.startContinuousPulse(for: project.healthLevel) {}
            }
            
            // Health Status
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(project.healthLevel.color)
                        .frame(width: 12, height: 12)
                    
                    Text(project.healthLevel.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(project.healthLevel.color)
                }
                
                Text(project.healthLevel.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            ProjectStatCard(
                title: "Streak",
                value: "\(project.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            ProjectStatCard(
                title: "Days Since Touch",
                value: "\(project.daysSinceLastTouch)",
                icon: "clock.fill",
                color: project.healthLevel.color
            )
            
            ProjectStatCard(
                title: "Total Active",
                value: "\(project.totalActiveDays)",
                icon: "calendar",
                color: .pulseAccent
            )
        }
    }
    
    // MARK: - Context Section
    
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Where You Left Off")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showingContextCapture = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.pulseAccent)
                }
            }
            
            if let snapshot = project.latestContextSnapshot {
                ContextCard(snapshot: snapshot)
            } else {
                EmptyContextCard {
                    showingContextCapture = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pulseBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Primary Action - Touch Project
            Button {
                touchProject()
            } label: {
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text("Touch Project")
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
            
            HStack(spacing: 12) {
                // Log Work
                ActionButton(
                    title: "Log Work",
                    icon: "plus.circle.fill",
                    color: .pulseGreen
                ) {
                    showingLogPulse = true
                }
                
                // Capture Context
                ActionButton(
                    title: "Capture",
                    icon: "text.bubble.fill",
                    color: .pulseAccent
                ) {
                    showingContextCapture = true
                }
            }
        }
    }
    
    // MARK: - Integrations Section
    
    private var hasIntegrations: Bool {
        project.githubRepoURL != nil ||
        project.testFlightAppID != nil ||
        project.vercelProjectID != nil
    }
    
    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integrations")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                if let github = project.githubRepoURL {
                    ProjectIntegrationRow(
                        name: "GitHub",
                        icon: "chevron.left.forwardslash.chevron.right",
                        status: "Connected",
                        url: github
                    )
                }
                
                if project.testFlightAppID != nil {
                    ProjectIntegrationRow(
                        name: "TestFlight",
                        icon: "airplane",
                        status: "Active",
                        url: nil
                    )
                }
                
                if project.vercelProjectID != nil {
                    ProjectIntegrationRow(
                        name: "Vercel",
                        icon: "globe",
                        status: "Deployed",
                        url: nil
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pulseBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Milestones Section
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Milestones")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    // Add milestone
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.pulseAccent)
                }
            }
            
            if let milestones = project.milestones, !milestones.isEmpty {
                ForEach(milestones.prefix(5)) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            } else {
                Text("No milestones yet")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pulseBorder, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Danger Section
    
    private var dangerSection: some View {
        VStack(spacing: 12) {
            if project.healthLevel == .dying || project.healthLevel == .dead {
                Button {
                    showingIntervention = true
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Intervention Required")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pulseRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pulseRed.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pulseRed.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            Button {
                showingIntervention = true
            } label: {
                HStack {
                    Image(systemName: "archivebox.fill")
                    Text("Archive Project")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Methods
    
    private func startPulsing() {
        isPulsing = true
    }
    
    private func touchProject() {
        project.touch()
        hapticEngine.playSuccess()
        
        // Add pulse entry
        let entry = PulseEntry(intensityLevel: 3)
        entry.project = project
        modelContext.insert(entry)
        
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct ProjectStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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

struct ContextCard: View {
    let snapshot: ContextSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: snapshot.snapshotType.icon)
                    .font(.system(size: 12))
                    .foregroundColor(.pulseAccent)
                
                Text(snapshot.timeAgo)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text(snapshot.displayContent)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseAccent.opacity(0.1))
        )
    }
}

struct EmptyContextCard: View {
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.white.opacity(0.4))
                Text("Capture where you left off...")
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
            .font(.system(size: 14))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pulseBorder, style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct ProjectIntegrationRow: View {
    let name: String
    let icon: String
    let status: String
    let url: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.pulseAccent)
                .frame(width: 24)
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(status)
                .font(.system(size: 12))
                .foregroundColor(.pulseGreen)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 8)
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.isCompleted ? .pulseGreen : .white.opacity(0.3))
            
            Text(milestone.title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(milestone.isCompleted ? 0.5 : 0.9))
                .strikethrough(milestone.isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    ProjectDetailView(project: PreviewData.healthyProject)
        .environmentObject(HapticEngine.shared)
        .modelContainer(for: [Project.self, ContextSnapshot.self, Milestone.self, PulseEntry.self], inMemory: true)
}
