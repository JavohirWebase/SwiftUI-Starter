import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var theme = Theme.system
    @Published var isLoading = false
    @Published var networkStatus: NetworkStatus = .connected
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeNetworkStatus()
        loadStoredUser()
    }
    
    private func observeNetworkStatus() {
        NetworkMonitor.shared.$status
            .assign(to: &$networkStatus)
    }
    
    private func loadStoredUser() {
        if let userData = UserDefaults.standard.data(forKey: "cached_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = user
            self.isAuthenticated = TokenManager.shared.hasValidToken()
        }
    }
    
    func setUser(_ user: User?) {
        self.user = user
        self.isAuthenticated = user != nil
        
        if let user = user,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "cached_user")
        } else {
            UserDefaults.standard.removeObject(forKey: "cached_user")
        }
    }
}

enum Theme: String, CaseIterable {
    case system, light, dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
