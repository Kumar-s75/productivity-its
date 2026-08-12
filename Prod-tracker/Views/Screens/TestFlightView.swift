//
//  TestFlightView.swift
//  Pulse
//
//  App Store Connect apps and TestFlight build status
//

import SwiftUI

struct TestFlightView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var service = TestFlightService.shared

    private var isConnected: Bool {
        !appState.ascIssuerID.isEmpty && !appState.ascKeyID.isEmpty && !appState.ascPrivateKey.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()

                if !isConnected {
                    notConnectedView
                } else if service.isLoading && service.apps.isEmpty {
                    loadingView
                } else if let error = service.errorMessage, service.apps.isEmpty {
                    errorView(error)
                } else {
                    connectedContent
                }
            }
            .navigationTitle("TestFlight")
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
                if !service.apps.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await service.fetchAll(
                                    issuerID: appState.ascIssuerID,
                                    keyID: appState.ascKeyID,
                                    privateKeyPEM: appState.ascPrivateKey
                                )
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .task {
                if service.apps.isEmpty, isConnected {
                    await service.fetchAll(
                        issuerID: appState.ascIssuerID,
                        keyID: appState.ascKeyID,
                        privateKeyPEM: appState.ascPrivateKey
                    )
                }
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.pulseBlue.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "airplane")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.pulseBlue)
            }
            VStack(spacing: 10) {
                Text("Connect TestFlight")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add your App Store Connect API credentials in Settings → TestFlight to view your builds.")
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
                .background(Capsule().fill(Color.pulseBlue)
                    .shadow(color: Color.pulseBlue.opacity(0.4), radius: 12, x: 0, y: 6))
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
            Text("Fetching builds…")
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
                Task {
                    await service.fetchAll(
                        issuerID: appState.ascIssuerID,
                        keyID: appState.ascKeyID,
                        privateKeyPEM: appState.ascPrivateKey
                    )
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.pulseAccent)
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if service.apps.isEmpty {
                    emptyAppsView
                } else {
                    ForEach(service.apps) { app in
                        AppBuildSection(
                            app: app,
                            builds: service.builds.filter { $0.appID == app.id }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
    }

    private var emptyAppsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.dashed")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.25))
            Text("No apps found")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 60)
    }
}

// MARK: - App Build Section

struct AppBuildSection: View {
    let app: ASCApp
    let builds: [ASCBuild]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // App header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.pulseBlue.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: "airplane")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pulseBlue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.attributes.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(app.attributes.bundleId)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text("\(builds.count) build\(builds.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pulseCardBackground)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.pulseBorder, lineWidth: 1))
            )

            // Builds
            if builds.isEmpty {
                Text("No recent builds")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.horizontal, 4)
            } else {
                ForEach(builds.prefix(5)) { build in
                    BuildRow(build: build)
                }
            }
        }
    }
}

// MARK: - Build Row

struct BuildRow: View {
    let build: ASCBuild

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("v\(build.attributes.version)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(build.uploadedAgo)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(build.stateColor)
                        .frame(width: 7, height: 7)
                    Text(build.attributes.processingState.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(build.stateColor)
                }
                if build.attributes.processingState == "VALID" {
                    Text(build.expiryDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pulseCardBackground.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pulseBorder.opacity(0.6), lineWidth: 1))
        )
    }
}

// MARK: - Preview

#Preview {
    TestFlightView()
        .environmentObject(AppState.shared)
}
