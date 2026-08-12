//
//  TestFlightService.swift
//  Pulse
//
//  Fetches App Store Connect apps and builds via JWT-authenticated REST API
//

import Foundation
import CryptoKit
import SwiftUI
import Combine

// MARK: - Models

struct ASCApp: Codable, Identifiable {
    let id: String
    let attributes: ASCAppAttributes

    struct ASCAppAttributes: Codable {
        let name: String
        let bundleId: String
    }
}

struct ASCBuild: Codable, Identifiable {
    let id: String
    let attributes: ASCBuildAttributes
    let relationships: ASCBuildRelationships?

    struct ASCBuildAttributes: Codable {
        let version: String
        let uploadedDate: String
        let processingState: String  // PROCESSING, FAILED, INVALID, VALID
        let minOsVersion: String?
    }

    struct ASCBuildRelationships: Codable {
        let app: AppRel?
        struct AppRel: Codable {
            let data: AppData?
            struct AppData: Codable { let id: String }
        }
    }

    var appID: String { relationships?.app?.data?.id ?? "" }

    var stateColor: Color {
        switch attributes.processingState {
        case "VALID":       return .pulseGreen
        case "FAILED",
             "INVALID":     return .pulseRed
        case "PROCESSING":  return .pulseYellow
        default:            return .white.opacity(0.4)
        }
    }

    var expiryDescription: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let uploaded = iso.date(from: attributes.uploadedDate) else { return "" }
        let expiry = uploaded.addingTimeInterval(90 * 86400)
        let days = Int(expiry.timeIntervalSinceNow / 86400)
        if days < 0 { return "Expired" }
        if days == 0 { return "Expires today" }
        return "Expires in \(days)d"
    }

    var uploadedAgo: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: attributes.uploadedDate) else {
            // fallback: try without fractional seconds
            let iso2 = ISO8601DateFormatter()
            iso2.formatOptions = [.withInternetDateTime]
            guard let d2 = iso2.date(from: attributes.uploadedDate) else { return "" }
            return relativeAge(d2)
        }
        return relativeAge(date)
    }

    private func relativeAge(_ date: Date) -> String {
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 60    { return "just now" }
        if secs < 3600  { return "\(secs / 60)m ago" }
        if secs < 86400 { return "\(secs / 3600)h ago" }
        if secs < 86400 * 30 { return "\(secs / 86400)d ago" }
        return "\(secs / (86400 * 30))mo ago"
    }
}

struct ASCDataResponse<T: Codable>: Codable {
    let data: [T]
}

// MARK: - Service

@MainActor
final class TestFlightService: ObservableObject {

    static let shared = TestFlightService()

    @Published var apps: [ASCApp]    = []
    @Published var builds: [ASCBuild] = []
    @Published var isLoading          = false
    @Published var errorMessage: String?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        return URLSession(configuration: cfg)
    }()

    private init() {}

    // MARK: - Public

    func fetchAll(issuerID: String, keyID: String, privateKeyPEM: String) async {
        guard !issuerID.isEmpty, !keyID.isEmpty, !privateKeyPEM.isEmpty else {
            errorMessage = "Enter your App Store Connect credentials in Settings."
            return
        }
        isLoading = true
        errorMessage = nil

        do {
            let jwt = try generateJWT(issuerID: issuerID, keyID: keyID, privateKeyPEM: privateKeyPEM)
            async let appsTask   = fetchApps(jwt: jwt)
            async let buildsTask = fetchBuilds(jwt: jwt)
            let (a, b) = await (appsTask, buildsTask)
            apps   = a ?? []
            builds = b ?? []
        } catch {
            errorMessage = "Auth failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - JWT

    private func generateJWT(issuerID: String, keyID: String, privateKeyPEM: String) throws -> String {
        let cleaned = privateKeyPEM
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        guard let keyData = Data(base64Encoded: cleaned) else {
            throw TestFlightAuthError.invalidKey
        }
        let privateKey = try P256.Signing.PrivateKey(derRepresentation: keyData)

        let header  = ["alg": "ES256", "kid": keyID, "typ": "JWT"]
        let hData   = try JSONEncoder().encode(header)
        let hB64    = b64url(hData)

        let iat = Int(Date().timeIntervalSince1970)
        let payload: [String: Any] = ["iss": issuerID, "iat": iat, "exp": iat + 1200, "aud": "appstoreconnect-v1"]
        let pData   = try JSONSerialization.data(withJSONObject: payload)
        let pB64    = b64url(pData)

        let msg     = "\(hB64).\(pB64)"
        let sig     = try privateKey.signature(for: Data(msg.utf8))
        return "\(msg).\(b64url(sig.rawRepresentation))"
    }

    private func b64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Requests

    private func fetchApps(jwt: String) async -> [ASCApp]? {
        guard let url = URL(string: "https://api.appstoreconnect.apple.com/v1/apps?limit=100") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await session.data(for: req) else { return nil }
        return (try? JSONDecoder().decode(ASCDataResponse<ASCApp>.self, from: data))?.data
    }

    private func fetchBuilds(jwt: String) async -> [ASCBuild]? {
        guard let url = URL(string: "https://api.appstoreconnect.apple.com/v1/builds?sort=-uploadedDate&limit=50") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await session.data(for: req) else { return nil }
        return (try? JSONDecoder().decode(ASCDataResponse<ASCBuild>.self, from: data))?.data
    }
}

enum TestFlightAuthError: LocalizedError {
    case invalidKey
    var errorDescription: String? { "Invalid private key — paste the full .p8 file content including headers." }
}
