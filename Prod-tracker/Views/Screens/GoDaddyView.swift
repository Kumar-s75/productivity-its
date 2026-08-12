//
//  GoDaddyView.swift
//  Pulse
//
//  GoDaddy domain portfolio overview
//

import SwiftUI

struct GoDaddyView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @StateObject private var service = GoDaddyService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()

                if appState.godaddyAPIKey.isEmpty || appState.godaddyAPISecret.isEmpty {
                    notConnectedView
                } else if service.isLoading && service.domains.isEmpty {
                    loadingView
                } else if let error = service.errorMessage, service.domains.isEmpty {
                    errorView(error)
                } else {
                    connectedContent
                }
            }
            .navigationTitle("GoDaddy")
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
                if !service.domains.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await service.fetch(apiKey: appState.godaddyAPIKey, apiSecret: appState.godaddyAPISecret) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .task {
                if service.domains.isEmpty {
                    await service.fetch(apiKey: appState.godaddyAPIKey, apiSecret: appState.godaddyAPISecret)
                }
            }
        }
    }

    // MARK: - Not Connected

    private var notConnectedView: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.pulseGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "network")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.pulseGreen)
            }
            VStack(spacing: 10) {
                Text("Connect GoDaddy")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add your GoDaddy API Key and Secret in Settings → GoDaddy to view your domains.")
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
                .background(Capsule().fill(Color.pulseGreen)
                    .shadow(color: Color.pulseGreen.opacity(0.4), radius: 12, x: 0, y: 6))
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
            Text("Fetching domains…")
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
                Task { await service.fetch(apiKey: appState.godaddyAPIKey, apiSecret: appState.godaddyAPISecret) }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.pulseAccent)
        }
    }

    // MARK: - Connected Content

    private var connectedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                // Summary
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.pulseGreen)
                    Text("\(service.domains.count) domain\(service.domains.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    let expired = service.domains.filter { $0.status == "EXPIRED" }.count
                    if expired > 0 {
                        Text("\(expired) expired")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.pulseRed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ForEach(service.domains) { domain in
                    DomainCard(domain: domain)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Domain Card

struct DomainCard: View {
    let domain: GoDaddyDomain

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(domain.statusColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "network")
                    .font(.system(size: 17))
                    .foregroundColor(domain.statusColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(domain.domain)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !domain.expiryDescription.isEmpty {
                        Text(domain.expiryDescription)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    if domain.renewAuto {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9))
                            Text("Auto")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.pulseGreen.opacity(0.7))
                    }
                }
            }

            Spacer()

            Text(domain.statusLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(domain.statusColor)
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
    GoDaddyView()
        .environmentObject(AppState.shared)
}
