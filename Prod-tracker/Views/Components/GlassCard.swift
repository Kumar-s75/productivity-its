//
//  GlassCard.swift
//  Pulse
//
//  Glassmorphism card component for modern UI
//

import SwiftUI

struct GlassCard<Content: View>: View {
    
    let content: Content
    var cornerRadius: CGFloat = 20
    var blur: CGFloat = 10
    var opacity: Double = 0.15
    var borderOpacity: Double = 0.2
    
    init(
        cornerRadius: CGFloat = 20,
        blur: CGFloat = 10,
        opacity: Double = 0.15,
        borderOpacity: Double = 0.2,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.blur = blur
        self.opacity = opacity
        self.borderOpacity = borderOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Blur background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(opacity),
                                    Color.white.opacity(opacity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(borderOpacity),
                                    Color.white.opacity(borderOpacity * 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    
    let title: String
    var icon: String? = nil
    var color: Color = .pulseAccent
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Glass Text Field

struct GlassTextField: View {
    
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20)
            }
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .tint(.pulseAccent)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Toggle

struct GlassToggle: View {
    
    let title: String
    @Binding var isOn: Bool
    var icon: String? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.pulseAccent)
                    .frame(width: 24)
            }
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.pulseAccent)
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

// MARK: - Glass Picker Row

struct GlassPickerRow<Content: View>: View {
    
    let title: String
    var icon: String? = nil
    let content: Content
    
    init(
        title: String,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.pulseAccent)
                    .frame(width: 24)
            }
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            content
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.pulseBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Beautiful glassmorphism effect")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }
            
            GlassButton(title: "Continue", icon: "arrow.right") {
                print("Tapped!")
            }
            
            GlassTextField(placeholder: "Enter project name", text: .constant(""), icon: "folder")
            
            GlassToggle(title: "Enable Haptics", isOn: .constant(true), icon: "hand.tap.fill")
        }
        .padding()
    }
}
