import SwiftUI

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Sheet?
    
    enum Route: Hashable {
        case signIn
        case home
        case profile
        case settings
        case detail(id: String)
    }
    
    enum Sheet: Identifiable {
        case editProfile
        
        var id: String {
            String(describing: self)
        }
    }
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func present(sheet: Sheet) {
        self.sheet = sheet
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "profile":
            navigate(to: .profile)
        case "settings":
            navigate(to: .settings)
        default:
            break
        }
    }
}
