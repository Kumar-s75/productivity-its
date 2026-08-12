//
//  SoundManager.swift
//  Pulse
//
//  Handles all sound effects for satisfying audio feedback
//

import Foundation
import AVFoundation
import SwiftUI
import Combine

@MainActor
final class SoundManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SoundManager()
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isEnabled: Bool = false
    @Published var volume: Float = 0.5
    
    // MARK: - Sound Types
    
    enum Sound: String {
        case tap = "tap"
        case success = "success"
        case complete = "complete"
        case streak = "streak"
        case levelUp = "levelup"
        case whoosh = "whoosh"
        case pop = "pop"
        case ding = "ding"
        case heartbeat = "heartbeat"
        case flatline = "flatline"
        case confetti = "confetti"
        
        var filename: String {
            return rawValue
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        configureAudioSession()
    }
    
    // MARK: - Configuration
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Play Sounds
    
    func play(_ sound: Sound) {
        guard isEnabled else { return }
        
        // Use system sounds as fallback since we can't bundle custom sounds here
        playSystemSound(for: sound)
    }
    
    private func playSystemSound(for sound: Sound) {
        let systemSoundID: SystemSoundID
        
        switch sound {
        case .tap:
            systemSoundID = 1104 // Tock
        case .success, .complete:
            systemSoundID = 1025 // New Mail
        case .streak, .levelUp:
            systemSoundID = 1057 // Tweet
        case .whoosh:
            systemSoundID = 1001 // Received message
        case .pop:
            systemSoundID = 1306 // Pop
        case .ding:
            systemSoundID = 1315 // Tink
        case .heartbeat:
            systemSoundID = 1052 // Low power
        case .flatline:
            systemSoundID = 1073 // Alarm
        case .confetti:
            systemSoundID = 1026 // SMS Received
        }
        
        AudioServicesPlaySystemSoundWithCompletion(systemSoundID, nil)
    }
    
    // MARK: - Convenience Methods
    
    func playTap() {
        play(.tap)
    }
    
    func playSuccess() {
        play(.success)
    }
    
    func playComplete() {
        play(.complete)
    }
    
    func playStreak() {
        play(.streak)
    }
    
    func playConfetti() {
        play(.confetti)
    }
    
    func playPop() {
        play(.pop)
    }
}
