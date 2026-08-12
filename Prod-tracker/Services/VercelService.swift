//
//  VercelService.swift
//  Pulse
//
//  Fetches Vercel projects and deployment status via REST API
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct VercelProject: Codable, Identifiable {
    let id: String
    let name: String
    let framework: String?
    let latestDeployments: [VercelDeployment]?
}

struct VercelProjectsResponse: Codable {
    let projects: [VercelProject]
}

struct VercelDeployment: Codable, Identifiable {
    let id: String
    let url: String?
    let readyState: String?  // READY, ERROR, BUILDING, QUEUED, CANCELED, INITIALIZING
    let target: String?      // "production" | "preview" | nil
    let createdAt: Double    // milliseconds

    var age: String {
        let date = Date(timeIntervalSince1970: createdAt / 1000)
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 60   { return "just now" }
        if secs < 3600 { return "\(secs / 60)m ago" }
        if secs < 86400 { return "\(secs / 3600)h ago" }
        return "\(secs / 86400)d ago"
    }

    var stateColor: Color {
        switch readyState {
        case "READY":       return .pulseGreen
        case "ERROR":       return .pulseRed
        case "BUILDING",
             "INITIALIZING": return .pulseYellow
        case "QUEUED":      return .white.opacity(0.4)
        case "CANCELED":    return .white.opacity(0.3)
        default:            return .white.opacity(0.4)
        }
    }

    var stateLabel: String {
        switch readyState {
        case "READY":        return "Ready"
        case "ERROR":        return "Error"
        case "BUILDING":     return "Building"
        case "INITIALIZING": return "Starting"
        case "QUEUED":       return "Queued"
        case "CANCELED":     return "Canceled"
        default:             return readyState ?? "Unknown"
        }
    }
}

// MARK: - Service

@MainActor
final class VercelService: ObservableObject {

    static let shared = VercelService()

    @Published var projects: [VercelProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    private init() {}

    func fetchProjects(token: String) async {
        guard !token.isEmpty else {
            errorMessage = "Enter your Vercel token in Settings."
            return
        }
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://api.vercel.com/v9/projects?limit=100") else {
            isLoading = false; return
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await session.data(for: req)
            let response = try JSONDecoder().decode(VercelProjectsResponse.self, from: data)
            projects = response.projects
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
