import SwiftUI

struct CoordinatorView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .navigationDestination(for: AppCoordinator.Route.self) { route in
                switch route {
                case .signIn:
                    SignInView()
                case .home:
                    HomeView()
                case .profile:
                    ProfileView()
                case .settings:
                    SettingsView()
                case .detail(let id):
                    DetailView(id: id)
                }
            }
        }
        .sheet(item: $coordinator.sheet) { sheet in
            switch sheet {
            case .editProfile:
                EditProfileView()
            }
        }
    }
}
