//
//  HapticEngine.swift
//  Pulse
//
//  Custom haptic patterns for visceral project feedback
//

import Foundation
import CoreHaptics
import UIKit
import SwiftUI
import Combine

final class HapticEngine: ObservableObject {
    
    // MARK: - Singleton
    
    @MainActor static let shared = HapticEngine()
    
    // MARK: - Properties
    
    private var engine: CHHapticEngine?
    private var isEngineRunning = false
    
    @Published var isSupported: Bool = false
    @Published var isEnabled: Bool = true
    
    // MARK: - Initialization
    
    @MainActor
    private init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        prepareEngine()
    }
    
    // MARK: - Engine Management
    
    @MainActor
    private func prepareEngine() {
        guard isSupported else { return }
        
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            
            engine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.isEngineRunning = false
                }
            }
            
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }
            
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine creation failed: \(error)")
        }
    }
    
    @MainActor
    private func restartEngine() {
        guard isSupported, let engine = engine else { return }
        
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine restart failed: \(error)")
        }
    }
    
    @MainActor
    private func ensureEngineRunning() {
        guard isSupported && isEnabled else { return }
        
        if !isEngineRunning {
            restartEngine()
        }
    }
    
    // MARK: - Pulse Patterns
    
    /// Healthy project - strong, confident pulse
    @MainActor
    func playHealthyPulse() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let pattern = createPulsePattern(
            intensity: 0.9,
            sharpness: 0.6,
            duration: 0.15,
            count: 2,
            interval: 0.12
        )
        playPattern(pattern)
    }
    
    /// Needs attention - slower, weaker pulse
    @MainActor
    func playAttentionPulse() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let pattern = createPulsePattern(
            intensity: 0.6,
            sharpness: 0.4,
            duration: 0.2,
            count: 2,
            interval: 0.25
        )
        playPattern(pattern)
    }
    
    /// Critical - irregular, weak flutter
    @MainActor
    func playCriticalPulse() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.15
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.4
            )
        ]
        
        playEvents(events)
    }
    
    /// Dying project - faint, irregular
    @MainActor
    func playDyingPulse() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let pattern = createPulsePattern(
            intensity: 0.2,
            sharpness: 0.2,
            duration: 0.3,
            count: 1,
            interval: 0
        )
        playPattern(pattern)
    }
    
    // MARK: - Action Haptics
    
    /// Success - triple tap celebration
    @MainActor
    func playSuccess() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.1
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.2
            )
        ]
        
        playEvents(events)
    }
    
    /// Streak broken - sharp snap
    @MainActor
    func playStreakBroken() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0
            )
        ]
        
        playEvents(events)
    }
    
    /// Project killed - deep final thud
    @MainActor
    func playProjectKilled() {
        guard isEnabled else { return }
        ensureEngineRunning()
        
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: 0.3
            )
        ]
        
        playEvents(events)
    }
    
    /// Light tap for UI interactions
    @MainActor
    func playTap() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium tap for selections
    @MainActor
    func playSelection() {
        guard isEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Generic pulse for timer
    @MainActor
    func playPulse() {
        guard isEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Warning haptic
    @MainActor
    func playWarning() {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Urgent haptic
    @MainActor
    func playUrgent() {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Notification for alerts
    @MainActor
    func playNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createPulsePattern(
        intensity: Float,
        sharpness: Float,
        duration: TimeInterval,
        count: Int,
        interval: TimeInterval
    ) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var currentTime: TimeInterval = 0
        
        for _ in 0..<count {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: currentTime
            )
            events.append(event)
            currentTime += duration + interval
        }
        
        return events
    }
    
    @MainActor
    private func playPattern(_ events: [CHHapticEvent]) {
        playEvents(events)
    }
    
    @MainActor
    private func playEvents(_ events: [CHHapticEvent]) {
        guard isSupported, isEngineRunning, let engine = engine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
    
    // MARK: - Continuous Pulse for Detail View
    
    @MainActor
    func startContinuousPulse(for healthLevel: HealthLevel, completion: @escaping () -> Void) {
        guard isEnabled && isSupported else { return }
        
        Task {
            switch healthLevel {
            case .healthy:
                playHealthyPulse()
            case .needsAttention:
                playAttentionPulse()
            case .critical:
                playCriticalPulse()
            case .dying:
                playDyingPulse()
            case .dead:
                break // No pulse for dead projects
            }
            
            try? await Task.sleep(nanoseconds: UInt64(healthLevel.pulseInterval * 1_000_000_000))
            completion()
        }
    }
}

// MARK: - HealthLevel Extension

extension HealthLevel {
    var pulseInterval: TimeInterval {
        switch self {
        case .healthy: return 1.0
        case .needsAttention: return 1.5
        case .critical: return 2.0
        case .dying: return 3.0
        case .dead: return 0
        }
    }
}
