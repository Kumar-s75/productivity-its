//
//  VoicePulse.swift
//  Pulse
//
//  Voice recording model
//

import Foundation
import SwiftData

@Model
final class VoicePulse {
    var id: UUID
    var createdAt: Date
    var duration: TimeInterval
    var transcription: String?
    var linkedProjectID: UUID?
    var audioFilePath: String?
    
    init(
        duration: TimeInterval,
        transcription: String? = nil,
        linkedProjectID: UUID? = nil,
        audioFilePath: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.duration = duration
        self.transcription = transcription
        self.linkedProjectID = linkedProjectID
        self.audioFilePath = audioFilePath
    }
}
