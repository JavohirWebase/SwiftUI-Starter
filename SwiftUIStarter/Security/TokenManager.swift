import Foundation
import OSLog

final class TokenManager {
    static let shared = TokenManager()
    private let keychain = KeychainService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TokenManager")
    
    private init() {}
    
    func saveToken(_ token: String) {
        keychain.save(token, for: .accessToken)
    }
    
    func saveRefreshToken(_ token: String) {
        keychain.save(token, for: .refreshToken)
    }
    
    func getAccessToken() -> String? {
        return keychain.get(.accessToken)
    }
    
    func getRefreshToken() -> String? {
        return keychain.get(.refreshToken)
    }
    
    func hasValidToken() -> Bool {
        return keychain.get(.accessToken) != nil
    }
    
    func clearTokens() {
        keychain.delete(.accessToken)
        keychain.delete(.refreshToken)
    }
}
