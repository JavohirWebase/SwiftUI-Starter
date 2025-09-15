import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = SignInViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var appState: AppState
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                formSection
                footerSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .disabled(viewModel.isLoading)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 60)
            
            Text("CRM System")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            
            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 30)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Username",
                text: $viewModel.username,
                placeholder: "Enter your username",
                focused: $focusedField,
                field: .username,
                onSubmit: {
                    focusedField = .password
                }
            )
            
            CustomSecureField(
                title: "Password",
                text: $viewModel.password,
                placeholder: "Enter your password",
                focused: $focusedField,
                field: .password,
                onSubmit: {
                    Task {
                        await viewModel.signIn(appState: appState)
                    }
                }
            )
            
            signInButton
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Powered by Webase")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
    
    private var signInButton: some View {
        Button {
            Task {
                await viewModel.signIn(appState: appState)
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(viewModel.isValidForm ? Color.blue : Color.gray.opacity(0.3))
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValidForm || viewModel.isLoading)
        .padding(.top, 8)
    }
}
