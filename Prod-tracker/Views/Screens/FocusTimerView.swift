//
//  FocusTimerView.swift
//  Pulse
//
//  Beautiful Pomodoro-style focus timer with project integration
//

import SwiftUI
import SwiftData

struct FocusTimerView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    @EnvironmentObject private var soundManager: SoundManager
    
    // MARK: - Properties
    
    var project: Project? = nil
    
    // MARK: - State
    
    @State private var timerState: TimerState = .idle
    @State private var selectedDuration: Int = 25 // minutes
    @State private var remainingSeconds: Int = 25 * 60
    @State private var totalSeconds: Int = 25 * 60
    @State private var timer: Timer?
    @State private var sessionsCompleted: Int = 0
    @State private var showingCompletion = false
    @State private var pulseAnimation = false
    @State private var breatheAnimation = false
    
    private let durations = [15, 25, 45, 60, 90]
    
    // MARK: - Computed
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }
    
    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var accentColor: Color {
        project?.color ?? .pulseAccent
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: 40) {
                // Header
                headerView
                
                Spacer()
                
                // Timer circle
                timerCircle
                
                Spacer()
                
                // Duration selector (only when idle)
                if timerState == .idle {
                    durationSelector
                }
                
                // Control buttons
                controlButtons
                
                // Sessions completed
                sessionsView
            }
            .padding()
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingCompletion) {
            SessionCompletionSheet(
                project: project,
                duration: selectedDuration,
                sessionsCompleted: sessionsCompleted
            )
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        ZStack {
            Color.pulseBackground.ignoresSafeArea()
            
            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(breatheAnimation ? 0.15 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 600, height: 600)
                .blur(radius: 60)
                .animation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: breatheAnimation
                )
        }
        .onAppear {
            breatheAnimation = true
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            if let project = project {
                HStack(spacing: 8) {
                    Circle()
                        .fill(project.color)
                        .frame(width: 12, height: 12)
                    
                    Text(project.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Text("Focus Session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Placeholder for balance
            Circle()
                .fill(Color.clear)
                .frame(width: 28, height: 28)
        }
    }
    
    // MARK: - Timer Circle
    
    private var timerCircle: some View {
        ZStack {
            // Outer pulse rings (when running)
            if timerState == .running {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(accentColor.opacity(0.1 - Double(index) * 0.03), lineWidth: 2)
                        .frame(
                            width: 280 + CGFloat(index * 30),
                            height: 280 + CGFloat(index * 30)
                        )
                        .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
            }
            
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)
                .frame(width: 260, height: 260)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accentColor, accentColor.opacity(0.5), accentColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
            
            // Glow on the progress end
            Circle()
                .fill(accentColor)
                .frame(width: 16, height: 16)
                .offset(y: -130)
                .rotationEffect(.degrees(360 * progress - 90))
                .shadow(color: accentColor, radius: 10)
                .opacity(timerState == .running ? 1 : 0)
            
            // Center content
            VStack(spacing: 8) {
                // Time
                Text(timeString)
                    .font(.system(size: 64, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // State label
                Text(timerState.label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .onAppear {
            if timerState == .running {
                pulseAnimation = true
            }
        }
        .onChange(of: timerState) { _, newState in
            pulseAnimation = newState == .running
        }
    }
    
    // MARK: - Duration Selector
    
    private var durationSelector: some View {
        VStack(spacing: 12) {
            Text("Duration")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    Button {
                        selectedDuration = duration
                        remainingSeconds = duration * 60
                        totalSeconds = duration * 60
                        hapticEngine.playTap()
                    } label: {
                        Text("\(duration)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedDuration == duration ? .white : .white.opacity(0.5))
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(selectedDuration == duration ? accentColor : Color.white.opacity(0.08))
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            // Reset button
            if timerState != .idle {
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            // Main button (Start/Pause/Resume)
            Button {
                handleMainButton()
            } label: {
                ZStack {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: accentColor.opacity(0.4), radius: 20)
                    
                    Image(systemName: mainButtonIcon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            
            // Skip button (only when running)
            if timerState == .running || timerState == .paused {
                Button {
                    skipSession()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private var mainButtonIcon: String {
        switch timerState {
        case .idle: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .completed: return "checkmark"
        }
    }
    
    // MARK: - Sessions View
    
    private var sessionsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < sessionsCompleted ? accentColor : Color.white.opacity(0.2))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Timer Logic
    
    private func handleMainButton() {
        switch timerState {
        case .idle:
            startTimer()
        case .running:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .completed:
            resetTimer()
        }
    }
    
    private func startTimer() {
        timerState = .running
        pulseAnimation = true
        hapticEngine.playPulse()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            Task { @MainActor in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                    
                    // Haptic feedback at certain intervals
                    if remainingSeconds == 60 {
                        hapticEngine.playWarning()
                    } else if remainingSeconds == 10 {
                        hapticEngine.playUrgent()
                    }
                } else {
                    completeSession()
                }
            }
        }
    }
    
    private func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
        hapticEngine.playTap()
    }
    
    private func resumeTimer() {
        timerState = .running
        hapticEngine.playTap()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                completeSession()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timerState = .idle
        remainingSeconds = selectedDuration * 60
        totalSeconds = selectedDuration * 60
        hapticEngine.playTap()
    }
    
    private func skipSession() {
        completeSession()
    }
    
    private func completeSession() {
        stopTimer()
        timerState = .completed
        sessionsCompleted += 1
        
        // Touch the project
        if let project = project {
            project.touch()
            
            // Log a pulse entry
            let entry = PulseEntry(
                date: Date(),
                intensityLevel: 4, // High intensity for focused work
                notes: "Focus session completed",
                durationMinutes: selectedDuration
            )
            entry.project = project
            modelContext.insert(entry)
        }
        
        hapticEngine.playSuccess()
        soundManager.playComplete()
        showingCompletion = true
        
        // Reset for next session after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            remainingSeconds = selectedDuration * 60
            totalSeconds = selectedDuration * 60
            timerState = .idle
        }
    }
}

// MARK: - Timer State

enum TimerState {
    case idle
    case running
    case paused
    case completed
    
    var label: String {
        switch self {
        case .idle: return "Ready"
        case .running: return "Focused"
        case .paused: return "Paused"
        case .completed: return "Done!"
        }
    }
}

// MARK: - Session Completion Sheet

struct SessionCompletionSheet: View {
    let project: Project?
    let duration: Int
    let sessionsCompleted: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.pulseBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Celebration icon
                ZStack {
                    Circle()
                        .fill(Color.pulseGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pulseGreen)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("Session Complete!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("You focused for \(duration) minutes")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Stats
                HStack(spacing: 30) {
                    VStack {
                        Text("\(sessionsCompleted)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.pulseAccent)
                        Text("Sessions")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    VStack {
                        Text("\(sessionsCompleted * duration)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Minutes")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                
                // Project touched
                if let project = project {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(project.color)
                            .frame(width: 10, height: 10)
                        
                        Text("\(project.name) touched!")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.pink)
                    }
                }
                
                Spacer()
                
                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pulseAccent)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            
            ConfettiView(isActive: $showConfetti, intensity: .heavy)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FocusTimerView(project: nil)
        .environmentObject(HapticEngine.shared)
        .environmentObject(SoundManager.shared)
}
