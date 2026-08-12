//
//  GitHubView.swift
//  Pulse
//
//  GitHub integration: profile, contribution chart, and repos
//

import SwiftUI

struct GitHubView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var service = GitHubService.shared

    @State private var appeared = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()

                if appState.githubToken.isEmpty || appState.githubUsername.isEmpty {
                    notConnectedView
                } else if service.isLoading && service.profile == nil {
                    loadingView
                } else if let error = service.errorMessage, service.profile == nil {
                    errorView(error)
                } else {
                    connectedContent
                }
            }
            .navigationTitle("GitHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                if service.profile != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await service.fetchAll(token: appState.githubToken,
                                                         username: appState.githubUsername) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .task {
                if service.profile == nil {
                    await service.fetchAll(token: appState.githubToken,
                                           username: appState.githubUsername)
                }
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#6e40c9")!.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color(hex: "#6e40c9") ?? .purple)
            }

            VStack(spacing: 10) {
                Text("Connect GitHub")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add your username and personal access token in Settings → GitHub to see your repos and contribution chart.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    appState.selectedTab = .settings
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 14)
                .background(Capsule().fill(Color(hex: "#6e40c9") ?? .purple)
                    .shadow(color: (Color(hex: "#6e40c9") ?? .purple).opacity(0.4), radius: 12, x: 0, y: 6))
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.4)
            Text("Fetching GitHub data…")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Error

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.pulseYellow)
            Text(msg)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                Task { await service.fetchAll(token: appState.githubToken,
                                              username: appState.githubUsername) }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.pulseAccent)
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if let profile = service.profile {
                    profileHeader(profile)
                }

                if let calendar = service.contributions {
                    contributionSection(calendar)
                }

                if !service.repos.isEmpty {
                    reposSection
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Profile Header

    private func profileHeader(_ p: GitHubProfile) -> some View {
        HStack(spacing: 16) {
            // Avatar
            AsyncImage(url: URL(string: p.avatarURL)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Circle().fill(Color.pulseCardBackground)
                        .overlay(Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.4)))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(p.name ?? p.login)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("@\(p.login)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))

                HStack(spacing: 14) {
                    GitHubStatChip(value: p.publicRepos, label: "repos")
                    GitHubStatChip(value: p.followers,   label: "followers")
                    GitHubStatChip(value: p.following,   label: "following")
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.pulseCardBackground)
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.pulseBorder, lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Contribution Chart

    private func contributionSection(_ calendar: ContributionCalendar) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Contributions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(calendar.totalContributions) this year")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pulseGreen)
            }
            .padding(.horizontal, 16)

            ContributionChartView(calendar: calendar)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Repos

    private var reposSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Repositories")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(service.repos.count)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)

            ForEach(service.repos) { repo in
                RepoCard(repo: repo)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Contribution Chart

struct ContributionChartView: View {
    let calendar: ContributionCalendar

    // Show last 26 weeks (half-year) in a scrollable view
    private var weeks: [ContributionWeek] { calendar.weeks }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day labels
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(["M", "W", "F"], id: \.self) { label in
                        Text(label)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 12, height: cellSize + cellSpacing)
                            .offset(y: label == "M" ? cellSize : label == "W" ? cellSize * 2 + cellSpacing : cellSize * 4 + cellSpacing * 3)
                    }
                }
                .frame(width: 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: cellSpacing) {
                        ForEach(weeks.indices, id: \.self) { wi in
                            VStack(spacing: cellSpacing) {
                                ForEach(weeks[wi].contributionDays.indices, id: \.self) { di in
                                    let day = weeks[wi].contributionDays[di]
                                    ContributionCell(count: day.contributionCount, hexColor: day.color)
                                }
                                // Pad incomplete weeks
                                ForEach(0..<max(0, 7 - weeks[wi].contributionDays.count), id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
                ForEach([0, 2, 5, 9, 15], id: \.self) { count in
                    ContributionCell(count: count, hexColor: nil)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pulseCardBackground)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pulseBorder, lineWidth: 1))
        )
    }

    private let cellSize: CGFloat    = 10
    private let cellSpacing: CGFloat = 2
}

struct ContributionCell: View {
    let count: Int
    let hexColor: String?   // GitHub's color string e.g. "#216e39"

    private var cellColor: Color {
        if count == 0 { return Color.white.opacity(0.06) }
        // Try to use GitHub's hex color directly; fall back to green scale
        if let hex = hexColor, let c = Color(hex: hex) { return c.opacity(0.9) }
        switch count {
        case 1...3:   return Color(hex: "#0e4429") ?? .green
        case 4...6:   return Color(hex: "#006d32") ?? .green
        case 7...9:   return Color(hex: "#26a641") ?? .green
        default:      return Color(hex: "#39d353") ?? .green
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 10, height: 10)
    }
}

// MARK: - Repo Card

struct RepoCard: View {
    let repo: GitHubRepo

    @State private var isPressed = false

    private var updatedAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: repo.updatedAt) else { return "" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        if days < 30 { return "\(days)d ago" }
        let months = days / 30
        return "\(months)mo ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if repo.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        Text(repo.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    if let desc = repo.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pulseYellow)
                        Text("\(repo.stargazersCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text(updatedAgo)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }
            }

            // Language + forks row
            HStack(spacing: 12) {
                if let lang = repo.language {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(repo.languageColor)
                            .frame(width: 9, height: 9)
                        Text(lang)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                if repo.forksCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "tuningfork")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                        Text("\(repo.forksCount)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.pulseCardBackground.opacity(isPressed ? 0.6 : 1))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.pulseBorder, lineWidth: 1))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - GitHub Stat Chip

struct GitHubStatChip: View {
    let value: Int
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

// MARK: - Preview

#Preview {
    GitHubView()
        .environmentObject(AppState.shared)
}
