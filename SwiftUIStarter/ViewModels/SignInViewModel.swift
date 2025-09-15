import SwiftUI
import OSLog

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let repository: AuthRepository = DIContainer.shared.resolve()
    private let analytics: AnalyticsService = DIContainer.shared.resolve()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SignIn")
    
    var isValidForm: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    func signIn(appState: AppState) async {
        guard isValidForm else {
            showError(message: "Please enter username and password")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let user = try await repository.signIn(username: username, password: password)
            
            await MainActor.run {
                appState.setUser(user)
                clearForm()
            }
            
            analytics.track(.signIn(method: "username"))
            logger.info("User signed in successfully")
            
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            showError(message: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearForm() {
        username = ""
        password = ""
        errorMessage = ""
    }
}
