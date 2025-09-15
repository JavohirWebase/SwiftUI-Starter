import SwiftUI

@main
struct SwiftUIStarterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var coordinator = AppCoordinator()
    
    init() {
        DIContainer.shared.registerDependencies()
        AppearanceConfiguration.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .environmentObject(appState)
                .environmentObject(coordinator)
                .preferredColorScheme(appState.theme.colorScheme)
                .onOpenURL { url in
                    coordinator.handleDeepLink(url)
                }
        }
    }
}
