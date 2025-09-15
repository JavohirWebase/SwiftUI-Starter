
import Foundation
import OSLog

protocol AuthRepositoryProtocol {
    func signIn(username: String, password: String) async throws -> User
    func signOut() async
}

final class AuthRepository: AuthRepositoryProtocol {
    private let client: NetworkClientProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AuthRepository")
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func signIn(username: String, password: String) async throws -> User {
        let endpoint = Endpoint(
            path: "/account/GenerateToken",
            method: .post,
            parameters: SignInRequest(username: username, password: password),
            requiresAuth: false
        )
        
        logger.info("Attempting login for user: \(username)")
        
        let response: SignInResponse = try await client.requestAsync(endpoint)
        
        // Save tokens
        TokenManager.shared.saveToken(response.accessToken)
        TokenManager.shared.saveRefreshToken(response.refreshToken)
        
        logger.info("Login successful for user: \(response.userInfo.userName ?? "unknown")")
        
        return response.userInfo
    }
    
    func signOut() async {
        TokenManager.shared.clearTokens()
    }
}
