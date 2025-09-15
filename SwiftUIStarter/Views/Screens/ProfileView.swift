import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                if let user = appState.user {
                    Section {
                        HStack {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user.initials)
                                        .foregroundStyle(.white)
                                        .font(.title3.bold())
                                )
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                if let position = user.position {
                                    Text(position)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Information") {
                        if let email = user.email {
                            InfoRow(label: "Email", value: email)
                        }
                        if let phone = user.phoneNumber {
                            InfoRow(label: "Phone", value: phone)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
