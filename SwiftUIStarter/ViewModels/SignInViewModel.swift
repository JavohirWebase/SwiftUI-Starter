import SwiftUI
import OSLog

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isLoading = false
    
    private let repository: AuthRepository = DIContainer.shared.resolve()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SignIn")
    private let toastManager = ToastManager.shared
    
    private var appState: AppState?
    
    var isValidForm: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
    }
    
    func signIn() async {
        guard isValidForm else {
            toastManager.showWarning("Login va parolni kiriting")
            return
        }
        
        isLoading = true
        
        do {
            let user = try await repository.signIn(username: username, password: password)
            
            await MainActor.run {
                self.appState?.setUser(user)
                toastManager.showSuccess("Muvaffaqiyatli kirdingiz!")
                clearForm()
            }
            
            logger.info("User signed in successfully")
            
        } catch NetworkError.validationError(let message) {
            toastManager.showError(message)
            
        } catch NetworkError.unauthorized {
            toastManager.showError("Login yoki parol noto'g'ri")
            
        } catch NetworkError.noConnection {
            toastManager.showError("Internet ulanishi yo'q")
            
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            toastManager.showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func clearForm() {
        username = ""
        password = ""
    }
}
