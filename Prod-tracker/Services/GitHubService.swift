//
//  GitHubService.swift
//  Pulse
//
//  Fetches GitHub profile, repos, and contribution calendar via REST + GraphQL APIs
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct GitHubProfile: Codable {
    let login: String
    let name: String?
    let avatarURL: String
    let publicRepos: Int
    let followers: Int
    let following: Int

    enum CodingKeys: String, CodingKey {
        case login, name, followers, following
        case avatarURL    = "avatar_url"
        case publicRepos  = "public_repos"
    }
}

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let updatedAt: String
    let htmlURL: String
    let isPrivate: Bool
    let fork: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, language, fork
        case fullName       = "full_name"
        case stargazersCount = "stargazers_count"
        case forksCount     = "forks_count"
        case updatedAt      = "updated_at"
        case htmlURL        = "html_url"
        case isPrivate      = "private"
    }

    var languageColor: Color {
        switch language?.lowercased() {
        case "swift":      return Color(hex: "#F05138") ?? .orange
        case "kotlin":     return Color(hex: "#7F52FF") ?? .purple
        case "python":     return Color(hex: "#3572A5") ?? .blue
        case "javascript": return Color(hex: "#F1E05A") ?? .yellow
        case "typescript": return Color(hex: "#2B7489") ?? .cyan
        case "rust":       return Color(hex: "#DEA584") ?? .orange
        case "go":         return Color(hex: "#00ADD8") ?? .cyan
        case "java":       return Color(hex: "#B07219") ?? .brown
        case "c++":        return Color(hex: "#F34B7D") ?? .pink
        case "ruby":       return Color(hex: "#CC342D") ?? .red
        default:           return .white.opacity(0.5)
        }
    }
}

struct ContributionDay: Codable {
    let contributionCount: Int
    let date: String
    let color: String
}

struct ContributionWeek: Codable {
    let contributionDays: [ContributionDay]
}

struct ContributionCalendar: Codable {
    let totalContributions: Int
    let weeks: [ContributionWeek]
}

// MARK: - Service

@MainActor
final class GitHubService: ObservableObject {

    static let shared = GitHubService()

    @Published var profile:       GitHubProfile?
    @Published var repos:         [GitHubRepo] = []
    @Published var contributions: ContributionCalendar?
    @Published var isLoading      = false
    @Published var errorMessage:  String?

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        return URLSession(configuration: cfg)
    }()

    private init() {}

    // MARK: - Public API

    func fetchAll(token: String, username: String) async {
        guard !token.isEmpty, !username.isEmpty else {
            errorMessage = "Enter your GitHub username and token in Settings."
            return
        }
        isLoading     = true
        errorMessage  = nil

        async let profileTask       = fetchProfile(token: token, username: username)
        async let reposTask         = fetchRepos(token: token)
        async let contributionsTask = fetchContributions(token: token, username: username)

        let (p, r, c) = await (profileTask, reposTask, contributionsTask)
        profile       = p
        repos         = r ?? []
        contributions = c
        isLoading     = false
    }

    // MARK: - REST: Profile

    private func fetchProfile(token: String, username: String) async -> GitHubProfile? {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(GitHubProfile.self, from: data)
        } catch {
            errorMessage = "Profile fetch failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - REST: Repos

    private func fetchRepos(token: String) async -> [GitHubRepo]? {
        guard let url = URL(string: "https://api.github.com/user/repos?sort=updated&per_page=100&affiliation=owner") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await session.data(for: req)
            let all = try JSONDecoder().decode([GitHubRepo].self, from: data)
            return all.filter { !$0.fork }
        } catch {
            errorMessage = "Repos fetch failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - GraphQL: Contributions

    private func fetchContributions(token: String, username: String) async -> ContributionCalendar? {
        guard let url = URL(string: "https://api.github.com/graphql") else { return nil }

        let query = """
        {
          user(login: "\(username)") {
            contributionsCollection {
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                    color
                  }
                }
              }
            }
          }
        }
        """

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["query": query])

        do {
            let (data, _) = try await session.data(for: req)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard
                let dataDict = json?["data"] as? [String: Any],
                let userDict = dataDict["user"] as? [String: Any],
                let collDict = userDict["contributionsCollection"] as? [String: Any],
                let calDict  = collDict["contributionCalendar"] as? [String: Any],
                let calData  = try? JSONSerialization.data(withJSONObject: calDict)
            else { return nil }
            return try JSONDecoder().decode(ContributionCalendar.self, from: calData)
        } catch {
            return nil
        }
    }
}
