//
//  SettingsView.swift
//  Pulse
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - State
    
    @State private var showingAbout = false
    @State private var showingExportData = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // Experience Section
                Section {
                    // Theme picker
                    VStack(alignment: .leading, spacing: 10) {
                        Label {
                            Text("Theme")
                        } icon: {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.pulseAccent)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AppTheme.all) { theme in
                                    ThemePickerCard(
                                        theme: theme,
                                        isSelected: appState.appTheme.id == theme.id
                                    ) {
                                        withAnimation(.spring(response: 0.35)) {
                                            appState.appTheme = theme
                                        }
                                        hapticEngine.playTap()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $appState.hapticsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                Text("Feel your projects pulse")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.pulseAccent)
                        }
                    }
                    .onChange(of: appState.hapticsEnabled) { _, newValue in
                        if newValue { hapticEngine.playSuccess() }
                    }
                } header: {
                    Text("Experience")
                }
                .listRowBackground(Color.pulseCardBackground)
                
                // Notifications Section
                Section {
                    Toggle(isOn: $appState.notificationsEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications")
                                Text("Stay on top of your projects")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.pulseOrange)
                        }
                    }
                    .onChange(of: appState.notificationsEnabled) { _, _ in
                        hapticEngine.playTap()
                    }

                    if appState.notificationsEnabled {
                        Toggle(isOn: $appState.morningReminderEnabled) {
                            Label {
                                Text("Morning Reminder")
                            } icon: {
                                Image(systemName: "sunrise.fill")
                                    .foregroundColor(.pulseYellow)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        if appState.morningReminderEnabled {
                            HStack {
                                Label {
                                    Text("Morning Time")
                                } icon: {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.pulseYellow)
                                }
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $appState.morningReminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Toggle(isOn: $appState.eveningReflectionEnabled) {
                            Label {
                                Text("Evening Reflection")
                            } icon: {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundColor(.pulseAccent)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))

                        if appState.eveningReflectionEnabled {
                            HStack {
                                Label {
                                    Text("Evening Time")
                                } icon: {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.pulseAccent)
                                }
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $appState.eveningReminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Picker(selection: $appState.weeklyReviewDay) {
                            Text("Sunday").tag(1)
                            Text("Monday").tag(2)
                            Text("Saturday").tag(7)
                        } label: {
                            Label {
                                Text("Weekly Review Day")
                            } icon: {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.pulseGreen)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } header: {
                    Text("Reminders")
                }
                .listRowBackground(Color.pulseCardBackground)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.notificationsEnabled)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.morningReminderEnabled)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.eveningReflectionEnabled)
                
                // GitHub Section
                Section {
                    if appState.githubUsername.isEmpty || appState.githubToken.isEmpty {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#6e40c9") ?? .purple)
                                .frame(width: 28)
                            TextField("GitHub Username", text: $appState.githubUsername)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }

                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#6e40c9") ?? .purple)
                                .frame(width: 28)
                            SecureField("Personal Access Token", text: $appState.githubToken)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pulseGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("@\(appState.githubUsername)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.pulseGreen)
                            }
                            Spacer()
                            Button("View") {
                                appState.showingGitHub = true
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#6e40c9") ?? .purple)
                        }

                        Button(role: .destructive) {
                            appState.githubToken    = ""
                            appState.githubUsername = ""
                        } label: {
                            Label("Disconnect GitHub", systemImage: "xmark.circle")
                                .foregroundColor(.pulseRed)
                        }
                    }
                } header: {
                    Text("GitHub")
                } footer: {
                    if appState.githubToken.isEmpty {
                        Text("Generate a Personal Access Token at github.com → Settings → Developer settings → Personal access tokens. Required scopes: read:user and repo.")
                    }
                }
                .listRowBackground(Color.pulseCardBackground)

                // Vercel Section
                Section {
                    if appState.vercelToken.isEmpty {
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(.pulseAccent)
                                .frame(width: 28)
                            SecureField("Access Token", text: $appState.vercelToken)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pulseGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Token saved")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.pulseGreen)
                            }
                            Spacer()
                            Button("View") { appState.showingVercel = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pulseAccent)
                        }
                        Button(role: .destructive) {
                            appState.vercelToken = ""
                        } label: {
                            Label("Disconnect Vercel", systemImage: "xmark.circle")
                                .foregroundColor(.pulseRed)
                        }
                    }
                } header: {
                    Text("Vercel")
                } footer: {
                    if appState.vercelToken.isEmpty {
                        Text("Generate a token at vercel.com → Settings → Tokens.")
                    }
                }
                .listRowBackground(Color.pulseCardBackground)

                // TestFlight Section
                Section {
                    if appState.ascIssuerID.isEmpty || appState.ascKeyID.isEmpty || appState.ascPrivateKey.isEmpty {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.key")
                                .font(.system(size: 16))
                                .foregroundColor(.pulseBlue)
                                .frame(width: 28)
                            TextField("Issuer ID", text: $appState.ascIssuerID)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.pulseBlue)
                                .frame(width: 28)
                            TextField("Key ID", text: $appState.ascKeyID)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                        HStack(alignment: .top) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.pulseBlue)
                                .frame(width: 28)
                                .padding(.top, 4)
                            TextEditor(text: $appState.ascPrivateKey)
                                .frame(height: 80)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .overlay(
                                    Group {
                                        if appState.ascPrivateKey.isEmpty {
                                            Text("Paste .p8 private key content…")
                                                .foregroundColor(.white.opacity(0.3))
                                                .padding(.leading, 4)
                                                .padding(.top, 8)
                                                .allowsHitTesting(false)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                )
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pulseGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Store Connect")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.pulseGreen)
                            }
                            Spacer()
                            Button("View") { appState.showingTestFlight = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pulseAccent)
                        }
                        Button(role: .destructive) {
                            appState.ascIssuerID   = ""
                            appState.ascKeyID      = ""
                            appState.ascPrivateKey = ""
                        } label: {
                            Label("Disconnect TestFlight", systemImage: "xmark.circle")
                                .foregroundColor(.pulseRed)
                        }
                    }
                } header: {
                    Text("TestFlight")
                } footer: {
                    if appState.ascPrivateKey.isEmpty {
                        Text("Create an API key at appstoreconnect.apple.com → Users & Access → Integrations → App Store Connect API. Required role: Developer or higher.")
                    }
                }
                .listRowBackground(Color.pulseCardBackground)

                // GoDaddy Section
                Section {
                    if appState.godaddyAPIKey.isEmpty || appState.godaddyAPISecret.isEmpty {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.pulseGreen)
                                .frame(width: 28)
                            TextField("API Key", text: $appState.godaddyAPIKey)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.pulseGreen)
                                .frame(width: 28)
                            SecureField("API Secret", text: $appState.godaddyAPISecret)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                        }
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pulseGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("GoDaddy")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.pulseGreen)
                            }
                            Spacer()
                            Button("View") { appState.showingGoDaddy = true }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.pulseAccent)
                        }
                        Button(role: .destructive) {
                            appState.godaddyAPIKey    = ""
                            appState.godaddyAPISecret = ""
                        } label: {
                            Label("Disconnect GoDaddy", systemImage: "xmark.circle")
                                .foregroundColor(.pulseRed)
                        }
                    }
                } header: {
                    Text("GoDaddy")
                } footer: {
                    if appState.godaddyAPIKey.isEmpty {
                        Text("Generate API credentials at developer.godaddy.com → Keys.")
                    }
                }
                .listRowBackground(Color.pulseCardBackground)

                // Integrations Section
                Section {
                    NavigationLink {
                        IntegrationsSettingsView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("All Integrations")
                                Text("View & manage connections")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.pulseAccent)
                        }
                    }
                } header: {
                    Text("Connections")
                }
                .listRowBackground(Color.pulseCardBackground)
                
                // Data Section
                Section {
                    Button {
                        showingExportData = true
                    } label: {
                        Label {
                            Text("Export Data")
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.pulseAccent)
                        }
                    }
                    
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label {
                            Text("Data Management")
                        } icon: {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.pulseGray)
                        }
                    }
                } header: {
                    Text("Data")
                }
                .listRowBackground(Color.pulseCardBackground)
                
                // About Section
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        Label {
                            Text("About Pulse")
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pulseRed)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label {
                            Text("Privacy Policy")
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.pulseGray)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label {
                            Text("Terms of Service")
                        } icon: {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.pulseGray)
                        }
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(spacing: 4) {
                        Text("Pulse v1.0.0")
                        Text("Made with 💜 for makers")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
                .listRowBackground(Color.pulseCardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Color.pulseBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportData) {
                ExportDataView()
            }
        }
    }
}

// MARK: - Integrations Settings

struct IntegrationsSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section {
                Button {
                    appState.showingGitHub = true
                } label: {
                    IntegrationRow(
                        name: "GitHub",
                        icon: "chevron.left.forwardslash.chevron.right",
                        description: "Repos and contribution chart",
                        isConnected: !appState.githubToken.isEmpty && !appState.githubUsername.isEmpty,
                        accentColor: Color(hex: "#6e40c9") ?? .purple
                    )
                }

                Button {
                    appState.showingTestFlight = true
                } label: {
                    IntegrationRow(
                        name: "TestFlight",
                        icon: "airplane",
                        description: "App builds and expiry dates",
                        isConnected: !appState.ascIssuerID.isEmpty && !appState.ascKeyID.isEmpty,
                        accentColor: .pulseBlue
                    )
                }

                Button {
                    appState.showingVercel = true
                } label: {
                    IntegrationRow(
                        name: "Vercel",
                        icon: "globe",
                        description: "Project deployment status",
                        isConnected: !appState.vercelToken.isEmpty,
                        accentColor: .white.opacity(0.8)
                    )
                }

                Button {
                    appState.showingGoDaddy = true
                } label: {
                    IntegrationRow(
                        name: "GoDaddy",
                        icon: "network",
                        description: "Domain portfolio and expiry",
                        isConnected: !appState.godaddyAPIKey.isEmpty,
                        accentColor: .pulseGreen
                    )
                }

                IntegrationRow(
                    name: "Linear",
                    icon: "list.bullet.rectangle",
                    description: "Sync issues and tasks",
                    isConnected: false,
                    accentColor: .pulseAccent
                )

                IntegrationRow(
                    name: "Notion",
                    icon: "doc.richtext",
                    description: "Link project docs",
                    isConnected: false,
                    accentColor: .white.opacity(0.6)
                )

                IntegrationRow(
                    name: "Figma",
                    icon: "paintbrush.fill",
                    description: "Quick access to designs",
                    isConnected: false,
                    accentColor: .pulseOrange
                )
            } footer: {
                Text("Connect your tools to see real-time status in your project cards.")
            }
            .listRowBackground(Color.pulseCardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.pulseBackground)
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.pulseBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct IntegrationRow: View {
    let name: String
    let icon: String
    let description: String
    let isConnected: Bool
    var accentColor: Color = .pulseAccent

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isConnected {
                Text("Connected")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pulseGreen)
            } else {
                Text("Connect")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.pulseAccent)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Management

struct DataManagementView: View {
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            Section {
                HStack {
                    Label("iCloud Sync", systemImage: "icloud.fill")
                    Spacer()
                    Text("Enabled")
                        .foregroundColor(.pulseGreen)
                }
            } footer: {
                Text("Your data is automatically synced across all your devices.")
            }
            .listRowBackground(Color.pulseCardBackground)
            
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete All Data", systemImage: "trash.fill")
                        .foregroundColor(.pulseRed)
                }
            } footer: {
                Text("This will permanently delete all your projects, entries, and settings. This action cannot be undone.")
            }
            .listRowBackground(Color.pulseCardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(Color.pulseBackground)
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.pulseBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                // Delete all data
            }
        } message: {
            Text("This will permanently delete all your projects and data. This cannot be undone.")
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.pulseAccent, .pulseAccent.opacity(0.5)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        Text("Pulse")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your projects are alive.\nThis app lets you feel their heartbeat.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Philosophy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Philosophy")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Every project has a life force. When you're shipping, it's thriving. When you neglect it, it's dying.\n\nPulse makes this visceral — not a boring list, but a living dashboard where you feel the health of everything you're building.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pulseCardBackground)
                    )
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text("Built with SwiftUI & SwiftData")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("v1.0.0")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pulseAccent)
                    }
                }
                .padding()
            }
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pulseAccent)
                
                Text("Export Your Data")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Download a complete copy of your projects, entries, and settings in JSON format.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button {
                    // Export logic
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Export JSON")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pulseAccent)
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 60)
            .background(Color.pulseBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Theme Picker Card

struct ThemePickerCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 7) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(
                            colors: [theme.topGlow, theme.background, theme.bottomGlow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 62, height: 48)

                    // Mini orb preview
                    Circle()
                        .fill(theme.accent.opacity(0.85))
                        .frame(width: 16, height: 16)
                        .shadow(color: theme.accent.opacity(0.6), radius: 6)

                    // Selection ring
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? theme.accent : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                        .frame(width: 62, height: 48)
                }

                Text("\(theme.emoji) \(theme.name)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? theme.accent : .white.opacity(0.45))
            }
        }
        .scaleEffect(isSelected ? 1.06 : (isPressed ? 0.94 : 1.0))
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.18), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .environmentObject(HapticEngine.shared)
}
