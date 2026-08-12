//
//  VercelView.swift
//  Pulse
//
//  Vercel project and deployment status
//

import SwiftUI

struct VercelView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var service = VercelService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()

                if appState.vercelToken.isEmpty {
                    notConnectedView
                } else if service.isLoading && service.projects.isEmpty {
                    loadingView
                } else if let error = service.errorMessage, service.projects.isEmpty {
                    errorView(error)
                } else {
                    connectedContent
                }
            }
            .navigationTitle("Vercel")
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
                if !service.projects.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await service.fetchProjects(token: appState.vercelToken) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .task {
                if service.projects.isEmpty {
                    await service.fetchProjects(token: appState.vercelToken)
                }
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.pulseAccent.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.pulseAccent)
            }
            VStack(spacing: 10) {
                Text("Connect Vercel")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add your Vercel token in Settings → Vercel to view your deployments.")
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
                .background(Capsule().fill(Color.pulseAccent)
                    .shadow(color: Color.pulseAccent.opacity(0.4), radius: 12, x: 0, y: 6))
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
            Text("Fetching Vercel projects…")
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
                Task { await service.fetchProjects(token: appState.vercelToken) }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.pulseAccent)
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Summary row
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.pulseGreen)
                    Text("\(service.projects.count) project\(service.projects.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ForEach(service.projects) { project in
                    VercelProjectCard(project: project)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Project Card

struct VercelProjectCard: View {
    let project: VercelProject

    @State private var isPressed = false

    private var latestDeployment: VercelDeployment? {
        project.latestDeployments?.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let fw = project.framework {
                        Text(fw.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.pulseAccent.opacity(0.8))
                    }
                }
                Spacer()

                if let dep = latestDeployment {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(dep.stateColor)
                                .frame(width: 7, height: 7)
                            Text(dep.stateLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(dep.stateColor)
                        }
                        Text(dep.age)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }

            if let dep = latestDeployment {
                HStack(spacing: 10) {
                    if let target = dep.target {
                        Text(target == "production" ? "prod" : target)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    if let url = dep.url {
                        Text(url)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
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

// MARK: - Preview

#Preview {
    VercelView()
        .environmentObject(AppState.shared)
}
