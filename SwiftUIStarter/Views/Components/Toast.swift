//
//  Toast.swift
//  SwiftUI Starter
//
//  Created by Webase on 16/09/25.
//


import SwiftUI

// MARK: - Toast Model
struct Toast: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: Double
    
    enum ToastType {
        case success
        case error
        case warning
        case info
        
        var backgroundColor: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    static func success(_ message: String, duration: Double = 3) -> Toast {
        Toast(message: message, type: .success, duration: duration)
    }
    
    static func error(_ message: String, duration: Double = 4) -> Toast {
        Toast(message: message, type: .error, duration: duration)
    }
    
    static func warning(_ message: String, duration: Double = 3) -> Toast {
        Toast(message: message, type: .warning, duration: duration)
    }
    
    static func info(_ message: String, duration: Double = 3) -> Toast {
        Toast(message: message, type: .info, duration: duration)
    }
}

// MARK: - Toast Manager
@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toasts: [Toast] = []
    @Published var currentToast: Toast?
    
    private init() {}
    
    func show(_ toast: Toast) {
        withAnimation(.spring()) {
            toasts.append(toast)
            
            // Auto-hide after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                self.hide(toast)
            }
        }
    }
    
    func show(_ message: String, type: Toast.ToastType = .info, duration: Double = 3) {
        let toast = Toast(message: message, type: type, duration: duration)
        show(toast)
    }
    
    func showSuccess(_ message: String) {
        show(Toast.success(message))
    }
    
    func showError(_ message: String) {
        show(Toast.error(message))
    }
    
    func showWarning(_ message: String) {
        show(Toast.warning(message))
    }
    
    func showInfo(_ message: String) {
        show(Toast.info(message))
    }
    
    private func hide(_ toast: Toast) {
        withAnimation(.spring()) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    @State private var isShowing = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundColor(.white)
            
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(toast.type.backgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .scaleEffect(isShowing ? 1 : 0.5)
        .opacity(isShowing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isShowing = true
            }
        }
    }
}

// MARK: - Toast Container (Multiple Toasts)
struct ToastContainer: View {
    @ObservedObject private var toastManager = ToastManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(toastManager.toasts, id: \.id) { toast in
                ToastView(toast: toast)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.spring(), value: toastManager.toasts)
    }
}

// MARK: - Modern Snackbar Style
struct SnackbarView: View {
    let toast: Toast
    let onDismiss: () -> Void
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.type == .error ? "Xatolik" : 
                     toast.type == .success ? "Muvaffaqiyat" :
                     toast.type == .warning ? "Ogohlantirish" : "Ma'lumot")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(toast.message)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 400
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onDismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toast.type.backgroundColor.gradient)
                .shadow(color: toast.type.backgroundColor.opacity(0.3), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
        .offset(x: offset)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if abs(value.translation.width) > 100 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            offset = value.translation.width > 0 ? 400 : -400
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring()) {
                            offset = 0
                        }
                    }
                }
        )
    }
}

// MARK: - View Modifier for Toast
struct ToastModifier: ViewModifier {
    @ObservedObject private var toastManager = ToastManager.shared
    let alignment: Alignment
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if alignment == .top {
                    ToastContainer()
                        .padding(.top, 50)
                    Spacer()
                } else {
                    Spacer()
                    ToastContainer()
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

extension View {
    func toastView(alignment: Alignment = .top) -> some View {
        modifier(ToastModifier(alignment: alignment))
    }
}