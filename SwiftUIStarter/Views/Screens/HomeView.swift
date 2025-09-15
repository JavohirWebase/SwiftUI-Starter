import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = appState.user {
                        welcomeCard(user: user)
                        
                        if user.isAdmin {
                            adminPanel()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private func welcomeCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(user.displayName)
                        .font(.title2.bold())
                }
                Spacer()
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.initials)
                            .foregroundStyle(.white)
                            .font(.headline)
                    )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func adminPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Admin Panel", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            
            Text("You have administrator privileges")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}
