//
//  GoDaddyService.swift
//  Pulse
//
//  Fetches GoDaddy domain portfolio via REST API
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct GoDaddyDomain: Codable, Identifiable {
    var id: String { domain }
    let domain: String
    let status: String      // ACTIVE, EXPIRED, PENDING_RENEWAL, CANCELLED
    let expires: String?    // ISO8601
    let renewAuto: Bool
    let createdAt: String?

    var expiryDescription: String {
        guard let raw = expires else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        guard let date = iso.date(from: raw) else { return "" }
        let days = Int(date.timeIntervalSinceNow / 86400)
        if days < 0 { return "Expired \(abs(days))d ago" }
        if days == 0 { return "Expires today" }
        if days < 30 { return "Expires in \(days)d" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Exp. \(formatter.string(from: date))"
    }

    var statusColor: Color {
        switch status {
        case "ACTIVE":           return .pulseGreen
        case "EXPIRED",
             "CANCELLED":        return .pulseRed
        case "PENDING_RENEWAL":  return .pulseYellow
        default:                 return .white.opacity(0.4)
        }
    }

    var statusLabel: String {
        switch status {
        case "ACTIVE":           return "Active"
        case "EXPIRED":          return "Expired"
        case "CANCELLED":        return "Cancelled"
        case "PENDING_RENEWAL":  return "Renewing"
        default:                 return status.capitalized
        }
    }
}

// MARK: - Service

@MainActor
final class GoDaddyService: ObservableObject {

    static let shared = GoDaddyService()

    @Published var domains: [GoDaddyDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    private init() {}

    func fetch(apiKey: String, apiSecret: String) async {
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            errorMessage = "Enter your GoDaddy API Key and Secret in Settings."
            return
        }
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://api.godaddy.com/v1/domains?limit=100") else {
            isLoading = false; return
        }
        var req = URLRequest(url: url)
        req.setValue("sso-key \(apiKey):\(apiSecret)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await session.data(for: req)
            domains = try JSONDecoder().decode([GoDaddyDomain].self, from: data)
        } catch {
            errorMessage = "Failed to load domains: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
