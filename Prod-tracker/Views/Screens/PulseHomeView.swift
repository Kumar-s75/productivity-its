//
//  PulseHomeView.swift
//  Pulse
//
//  Main heartbeat home screen — draggable, pinch-resizable floating orbs
//

import SwiftUI
import SwiftData

// MARK: - Orb Layout Store

/// Persists per-project orb positions and scale multipliers in UserDefaults.
final class OrbLayoutStore {
    static let shared = OrbLayoutStore()

    private let posKey   = "pulse.orbPositions.v2"
    private let scaleKey = "pulse.orbScales.v2"

    func loadPositions() -> [UUID: CGPoint] {
        guard
            let data = UserDefaults.standard.data(forKey: posKey),
            let raw  = try? JSONDecoder().decode([String: [Double]].self, from: data)
        else { return [:] }
        return raw.compactMapKeys { UUID(uuidString: $0) }
                  .mapValues { CGPoint(x: $0[0], y: $0[1]) }
    }

    func savePositions(_ dict: [UUID: CGPoint]) {
        let raw = Dictionary(uniqueKeysWithValues:
            dict.map { (k, v) in (k.uuidString, [Double(v.x), Double(v.y)]) }
        )
        UserDefaults.standard.set(try? JSONEncoder().encode(raw), forKey: posKey)
    }

    func loadScales() -> [UUID: CGFloat] {
        guard
            let data = UserDefaults.standard.data(forKey: scaleKey),
            let raw  = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return [:] }
        return raw.compactMapKeys { UUID(uuidString: $0) }
                  .mapValues { CGFloat($0) }
    }

    func saveScales(_ dict: [UUID: CGFloat]) {
        let raw = Dictionary(uniqueKeysWithValues:
            dict.map { (k, v) in (k.uuidString, Double(v)) }
        )
        UserDefaults.standard.set(try? JSONEncoder().encode(raw), forKey: scaleKey)
    }
}

// Dictionary helpers
private extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        forEach { k, v in if let t = transform(k) { result[t] = v } }
        return result
    }
}

// MARK: - PulseHomeView

struct PulseHomeView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    @EnvironmentObject private var appState: AppState

    // MARK: - Query

    @Query(
        filter: #Predicate<Project> { $0.archivedAt == nil },
        sort: [SortDescriptor(\Project.lastTouchedAt, order: .reverse)]
    )
    private var projects: [Project]

    // MARK: - State

    @State private var showingAddProject   = false
    @State private var selectedProject: Project?
    @State private var showingQuickActions = false
    @State private var appeared            = false

    // Layout persistence
    @State private var orbPositions: [UUID: CGPoint] = [:]
    @State private var orbScales:    [UUID: CGFloat]  = [:]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    BackgroundView().ignoresSafeArea()

                    if projects.isEmpty {
                        EmptyPulseView(onAddProject: { showingAddProject = true })
                    } else {
                        // Draggable orbs
                        ForEach(projects) { project in
                            DraggableOrbView(
                                project: project,
                                position: positionBinding(for: project, geo: geo),
                                scaleMult: scaleBinding(for: project),
                                canvasSize: geo.size,
                                onTap: {
                                    hapticEngine.playTap()
                                    selectedProject = project
                                }
                            )
                        }
                    }

                    // Header
                    VStack {
                        headerSection(geo: geo)
                        Spacer()
                    }

                    // Action bar
                    VStack {
                        Spacer()
                        bottomActionBar(safeAreaBottom: geo.safeAreaInsets.bottom)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                orbPositions = OrbLayoutStore.shared.loadPositions()
                orbScales    = OrbLayoutStore.shared.loadScales()
                withAnimation(.spring(response: 0.6).delay(0.1)) { appeared = true }
            }
            .sheet(isPresented: $showingAddProject)   { AddProjectSheet() }
            .sheet(item: $selectedProject)            { ProjectDetailView(project: $0) }
            .sheet(isPresented: $showingQuickActions) { QuickActionsSheet() }
        }
    }

    // MARK: - Header

    private func headerSection(geo: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Projects")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(projects.isEmpty ? "Add your first project" : "\(projects.count) active")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                HStack(spacing: 10) {
                    HeaderButton(icon: "magnifyingglass") {
                        hapticEngine.playTap(); appState.showingSearch = true
                    }
                    HeaderButton(icon: "arrow.counterclockwise") {
                        hapticEngine.playTap()
                        withAnimation(.spring(response: 0.5)) { orbPositions = [:]; orbScales = [:] }
                        OrbLayoutStore.shared.savePositions([:])
                        OrbLayoutStore.shared.saveScales([:])
                    }
                    HeaderButton(icon: "ellipsis.circle") {
                        hapticEngine.playTap(); showingQuickActions = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)

            if !projects.isEmpty {
                HStack(spacing: 12) {
                    HealthPill(count: projects.filter { $0.healthLevel == .healthy }.count,
                               color: .pulseGreen, icon: "heart.fill")
                    HealthPill(count: projects.filter {
                        $0.healthLevel == .needsAttention || $0.healthLevel == .critical
                    }.count, color: .pulseYellow, icon: "exclamationmark.circle.fill")
                    HealthPill(count: projects.filter {
                        $0.healthLevel == .dying || $0.healthLevel == .dead
                    }.count, color: .pulseRed, icon: "heart.slash.fill")
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
            }
        }
        .animation(.spring(response: 0.4), value: projects.isEmpty)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -12)
    }

    // MARK: - Bottom Bar

    private func bottomActionBar(safeAreaBottom: CGFloat) -> some View {
        HStack(spacing: 12) {
            ActionPill(icon: "bolt.fill",    label: "Capture", color: .purple) {
                hapticEngine.playTap(); appState.showingQuickCapture = true
            }
            ActionPill(icon: "mic.fill",     label: "Voice",   color: .orange) {
                hapticEngine.playTap(); appState.showingVoicePulse = true
            }

            // Add project FAB
            Button {
                hapticEngine.playTap(); showingAddProject = true
            } label: {
                ZStack {
                    Circle()
                        .fill(appState.appTheme.accent)
                        .frame(width: 56, height: 56)
                        .shadow(color: appState.appTheme.accent.opacity(0.55), radius: 12)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            ActionPill(icon: "timer",         label: "Focus",  color: .cyan) {
                hapticEngine.playTap(); appState.showingFocusTimer = true
            }
            ActionPill(icon: "face.smiling",  label: "Mood",   color: .pink) {
                hapticEngine.playTap(); appState.showingMoodCheckIn = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, max(safeAreaBottom, 16))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Bindings

    private func positionBinding(for project: Project, geo: GeometryProxy) -> Binding<CGPoint> {
        Binding(
            get: {
                orbPositions[project.id] ?? defaultPosition(for: project, geo: geo)
            },
            set: { newPos in
                orbPositions[project.id] = newPos
                OrbLayoutStore.shared.savePositions(orbPositions)
            }
        )
    }

    private func scaleBinding(for project: Project) -> Binding<CGFloat> {
        Binding(
            get: { orbScales[project.id] ?? 1.0 },
            set: { newScale in
                orbScales[project.id] = newScale
                OrbLayoutStore.shared.saveScales(orbScales)
            }
        )
    }

    // MARK: - Default layout (evenly distributed within the visible canvas)

    private func defaultPosition(for project: Project, geo: GeometryProxy) -> CGPoint {
        let index = projects.firstIndex(of: project) ?? 0
        let count = max(projects.count, 1)

        // Canvas zone: below header, above action bar + safe area
        let canvasTop: CGFloat    = 158
        let canvasBottom: CGFloat = geo.size.height - 108 - max(geo.safeAreaInsets.bottom, 0)
        let canvasH = max(canvasBottom - canvasTop, 220)
        let cx = geo.size.width / 2
        let cy = canvasTop + canvasH / 2

        if count == 1 { return CGPoint(x: cx, y: cy) }

        // Largest circle that fits inside the canvas rectangle with margin
        let margin: CGFloat = 72
        let radius = min(geo.size.width / 2 - margin, canvasH / 2 - margin, 138)

        // Evenly spread around the circle starting from the top (-π/2)
        let angle = (Double(index) / Double(count)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: cx + cos(angle) * radius,
            y: cy + sin(angle) * radius
        )
    }
}

// MARK: - Draggable Orb View

struct DraggableOrbView: View {

    let project: Project
    @Binding var position:  CGPoint
    @Binding var scaleMult: CGFloat
    var canvasSize: CGSize = .zero
    let onTap: () -> Void

    @GestureState private var dragDelta:   CGSize  = .zero
    @GestureState private var pinchDelta:  CGFloat = 1.0
    @State private var isDragging = false
    @State private var didDrag    = false   // distinguish tap vs drag

    // Base orb size driven by health + user scale
    private var baseSize: CGFloat {
        let health: CGFloat = 62 + project.pulseIntensity * 22
        return (health * scaleMult * pinchDelta).clamped(36, 170)
    }

    private var livePosition: CGPoint {
        CGPoint(
            x: position.x + dragDelta.width,
            y: position.y + dragDelta.height
        )
    }

    var body: some View {
        PulseOrbView(
            project: project,
            size: baseSize,
            showLabel: true
        ) {
            if !didDrag { onTap() }
        }
        // lift shadow while dragging
        .shadow(
            color: project.color.opacity(isDragging ? 0.6 : 0),
            radius: isDragging ? 30 : 0
        )
        .scaleEffect(isDragging ? 1.07 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
        .position(livePosition)
        // Drag gesture
        .gesture(
            DragGesture(minimumDistance: 6)
                .updating($dragDelta) { value, state, _ in state = value.translation }
                .onChanged { _ in
                    if !isDragging {
                        isDragging = true
                        didDrag    = true
                    }
                }
                .onEnded { value in
                    isDragging = false
                    let edgePad: CGFloat = 44
                    let topPad: CGFloat  = 155
                    let botPad: CGFloat  = 110
                    let rawX = position.x + value.translation.width
                    let rawY = position.y + value.translation.height
                    position = CGPoint(
                        x: canvasSize.width  > 0 ? rawX.clamped(edgePad, canvasSize.width  - edgePad) : rawX,
                        y: canvasSize.height > 0 ? rawY.clamped(topPad,  canvasSize.height - botPad)  : rawY
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { didDrag = false }
                }
        )
        // Pinch gesture (simultaneous so drag still works)
        .simultaneousGesture(
            MagnificationGesture()
                .updating($pinchDelta) { value, state, _ in state = value }
                .onEnded { value in
                    scaleMult = (scaleMult * value).clamped(0.38, 2.6)
                }
        )
    }
}

// MARK: - Header Button

struct HeaderButton: View {
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(isPressed ? 0.18 : 0.1)))
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Action Pill

struct ActionPill: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.4), radius: isPressed ? 6 : 0)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(width: 52, height: 46)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Quick Actions Sheet

struct QuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var hapticEngine: HapticEngine

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickActionCard(icon: "checkmark.circle.fill", title: "Todos",       color: .green)  { show { appState.showingTodos = true } }
                        QuickActionCard(icon: "trophy.fill",           title: "Achievements", color: .yellow) { show { appState.showingAchievements = true } }
                        QuickActionCard(icon: "chart.bar.fill",        title: "Stats",        color: .cyan)   { show { appState.showingStats = true } }
                        QuickActionCard(icon: "link.circle.fill",      title: "Habits",       color: .purple) { show { appState.showingHabitStack = true } }
                        QuickActionCard(icon: "tray.fill",             title: "Inbox",        color: .orange) { show { appState.showingInbox = true } }
                        QuickActionCard(icon: "arrow.left.arrow.right",title: "Compare",      color: .pink)   { show { appState.showingProjectCompare = true } }
                        QuickActionCard(icon: "sparkles",              title: "Year Review",  color: .indigo) { show { appState.showingYearInReview = true } }
                        QuickActionCard(icon: "face.smiling.fill",     title: "Mood",         color: .mint)   { show { appState.showingMoodCheckIn = true } }
                        QuickActionCard(icon: "chevron.left.forwardslash.chevron.right",
                                                                       title: "GitHub",       color: Color(hex: "#6e40c9") ?? .purple) {
                            show { appState.showingGitHub = true }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.pulseBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func show(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: action)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.4), radius: 8)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(isPressed ? 0.14 : 0.08))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(isPressed ? 0.25 : 0), lineWidth: 1))
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Overall Health Indicator

struct OverallHealthIndicator: View {
    let projects: [Project]

    private var overallHealth: Double {
        guard !projects.isEmpty else { return 0 }
        return projects.reduce(0) { $0 + $1.pulseIntensity } / Double(projects.count)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Your Projects")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 16) {
                HealthPill(count: projects.filter { $0.healthLevel == .healthy }.count,
                           color: .pulseGreen, icon: "heart.fill")
                HealthPill(count: projects.filter {
                    $0.healthLevel == .needsAttention || $0.healthLevel == .critical
                }.count, color: .pulseYellow, icon: "exclamationmark.circle.fill")
                HealthPill(count: projects.filter {
                    $0.healthLevel == .dying || $0.healthLevel == .dead
                }.count, color: .pulseRed, icon: "heart.slash.fill")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Health Pill

struct HealthPill: View {
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold))
            Text("\(count)").font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
        )
    }
}

// MARK: - Empty State

struct EmptyPulseView: View {
    let onAddProject: () -> Void

    @State private var pulse    = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(Color.pulseAccent.opacity(0.18 - Double(i) * 0.04), lineWidth: 1.5)
                        .frame(width: CGFloat(110 + i * 34), height: CGFloat(110 + i * 34))
                        .scaleEffect(pulse ? 1 + CGFloat(i) * 0.03 : 1 - CGFloat(i) * 0.02)
                        .animation(
                            .easeInOut(duration: 2.2).repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.25), value: pulse)
                }
                Circle()
                    .fill(Color.pulseAccent.opacity(0.22))
                    .frame(width: 90, height: 90).blur(radius: 24)
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pulseAccent, Color.pulseAccent.opacity(0.7)],
                        center: .topLeading, startRadius: 0, endRadius: 55))
                    .frame(width: 90, height: 90)
                    .overlay(Circle()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42).offset(x: -16, y: -16))
                    .shadow(color: Color.pulseAccent.opacity(0.5), radius: 20, x: 0, y: 8)
                    .scaleEffect(pulse ? 1.05 : 0.98)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(height: 220)

            VStack(spacing: 10) {
                Text("No Projects Yet")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Add your first project and watch it\ncome to life with a pulse.")
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center).lineSpacing(3)
            }

            Button(action: onAddProject) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 17))
                    Text("Add First Project").font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28).padding(.vertical, 15)
                .background(Capsule().fill(Color.pulseAccent)
                    .shadow(color: Color.pulseAccent.opacity(0.45), radius: 14, x: 0, y: 6))
            }
        }
        .padding(.horizontal, 32)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.92)
        .onAppear {
            pulse = true
            withAnimation(.spring(response: 0.5).delay(0.1)) { appeared = true }
        }
    }
}

// MARK: - CGFloat clamped helper

extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        Swift.max(lo, Swift.min(hi, self))
    }
}

// MARK: - Preview

#Preview {
    PulseHomeView()
        .environmentObject(HapticEngine.shared)
        .environmentObject(AppState.shared)
        .modelContainer(for: [Project.self], inMemory: true)
}
