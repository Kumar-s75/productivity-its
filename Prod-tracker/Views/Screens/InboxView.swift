//
//  InboxView.swift
//  Pulse
//
//  GTD-style inbox for processing captures
//

import SwiftUI
import SwiftData

struct InboxView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    // MARK: - Queries
    
    @Query(
        filter: #Predicate<QuickCapture> { $0.processedAt == nil },
        sort: \QuickCapture.createdAt,
        order: .reverse
    )
    private var unprocessedCaptures: [QuickCapture]
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    // MARK: - State
    
    @State private var showingQuickCapture = false
    @State private var selectedCapture: QuickCapture?
    @State private var showProcessSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                if unprocessedCaptures.isEmpty {
                    emptyState
                } else {
                    captureList
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingQuickCapture = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.pulseAccent)
                    }
                }
            }
            .sheet(isPresented: $showingQuickCapture) {
                QuickCaptureView()
            }
            .sheet(isPresented: $showProcessSheet) {
                if let capture = selectedCapture {
                    ProcessCaptureSheet(capture: capture)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.pulseGreen.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "tray.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.pulseGreen)
            }
            
            Text("Inbox Zero! 🎉")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("All your captures have been processed.\nKeep capturing thoughts and ideas!")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Button {
                showingQuickCapture = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Quick Capture")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.pulseAccent)
                )
            }
        }
        .padding()
    }
    
    // MARK: - Capture List
    
    private var captureList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("\(unprocessedCaptures.count) items to process")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Captures
                ForEach(unprocessedCaptures) { capture in
                    CaptureCard(capture: capture) {
                        selectedCapture = capture
                        showProcessSheet = true
                    } onQuickProcess: {
                        quickProcess(capture)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Methods
    
    private func quickProcess(_ capture: QuickCapture) {
        capture.markProcessed()
        hapticEngine.playTap()
    }
}

// MARK: - Capture Card

struct CaptureCard: View {
    let capture: QuickCapture
    let onTap: () -> Void
    let onQuickProcess: () -> Void
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background action
            HStack {
                Spacer()
                
                Button(action: onQuickProcess) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.pulseGreen)
                }
                .padding(.trailing, 20)
            }
            
            // Main card
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Type icon
                    ZStack {
                        Circle()
                            .fill(capture.type.color.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: capture.type.icon)
                            .font(.system(size: 18))
                            .foregroundColor(capture.type.color)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(capture.content)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Text(capture.type.label)
                                .font(.system(size: 12))
                                .foregroundColor(capture.type.color)
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text(capture.createdAt, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width < -40 {
                                offset = -80
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Process Capture Sheet

struct ProcessCaptureSheet: View {
    let capture: QuickCapture
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var hapticEngine: HapticEngine
    
    @Query(filter: #Predicate<Project> { $0.archivedAt == nil })
    private var activeProjects: [Project]
    
    @State private var selectedAction: ProcessAction?
    @State private var selectedProjectID: UUID?
    @State private var todoTitle: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pulseBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Capture preview
                        capturePreview
                        
                        // Actions
                        actionButtons
                        
                        // Action-specific content
                        if selectedAction != nil {
                            actionContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Process")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if selectedAction != nil {
                        Button("Done") {
                            processCapture()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.pulseAccent)
                    }
                }
            }
        }
        .onAppear {
            todoTitle = capture.content
        }
    }
    
    // MARK: - Capture Preview
    
    private var capturePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: capture.type.icon)
                    .foregroundColor(capture.type.color)
                Text(capture.type.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(capture.type.color)
            }
            
            Text(capture.content)
                .font(.system(size: 17))
                .foregroundColor(.white)
            
            Text(capture.createdAt, style: .relative)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to do?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ProcessAction.allCases, id: \.self) { action in
                    Button {
                        selectedAction = action
                        hapticEngine.playTap()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedAction == action ? action.color : .white.opacity(0.5))
                            
                            Text(action.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedAction == action ? .white : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedAction == action ? action.color.opacity(0.2) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedAction == action ? action.color.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Action Content
    
    @ViewBuilder
    private var actionContent: some View {
        switch selectedAction {
        case .createTask:
            VStack(alignment: .leading, spacing: 12) {
                Text("Task Title")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Task title", text: $todoTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
                
                projectPicker
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            
        case .linkProject:
            projectPicker
                .transition(.move(edge: .bottom).combined(with: .opacity))
            
        case .archive, .delete:
            EmptyView()
            
        case .none:
            EmptyView()
        }
    }
    
    private var projectPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to Project")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(activeProjects) { project in
                        Button {
                            selectedProjectID = project.id
                            hapticEngine.playTap()
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(project.color)
                                    .frame(width: 8, height: 8)
                                Text(project.name)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedProjectID == project.id ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedProjectID == project.id ? project.color.opacity(0.4) : Color.white.opacity(0.08))
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func processCapture() {
        switch selectedAction {
        case .createTask:
            let todo = Todo(
                title: todoTitle,
                linkedProjectID: selectedProjectID
            )
            modelContext.insert(todo)
            capture.markProcessed()
            
        case .linkProject:
            capture.linkedProjectID = selectedProjectID
            capture.markProcessed()
            
        case .archive:
            capture.markProcessed()
            
        case .delete:
            modelContext.delete(capture)
            
        case .none:
            break
        }
        
        hapticEngine.playSuccess()
        dismiss()
    }
}

// MARK: - Process Action

enum ProcessAction: CaseIterable {
    case createTask
    case linkProject
    case archive
    case delete
    
    var label: String {
        switch self {
        case .createTask: return "Create Task"
        case .linkProject: return "Link Project"
        case .archive: return "Archive"
        case .delete: return "Delete"
        }
    }
    
    var icon: String {
        switch self {
        case .createTask: return "checkmark.circle"
        case .linkProject: return "link"
        case .archive: return "archivebox"
        case .delete: return "trash"
        }
    }
    
    var color: Color {
        switch self {
        case .createTask: return .green
        case .linkProject: return .blue
        case .archive: return .orange
        case .delete: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    InboxView()
        .modelContainer(for: [QuickCapture.self, Project.self, Todo.self])
        .environmentObject(HapticEngine.shared)
}
