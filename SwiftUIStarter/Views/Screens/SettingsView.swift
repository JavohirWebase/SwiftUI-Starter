import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $appState.theme) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            Text(theme.rawValue.capitalized)
                        }
                    }
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        Task {
                            await viewModel.signOut()
                            appState.setUser(nil)
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    private let repository: AuthRepository = DIContainer.shared.resolve()
    
    func signOut() async {
        await repository.signOut()
    }
}
