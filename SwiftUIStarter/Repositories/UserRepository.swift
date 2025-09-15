import Foundation

protocol UserRepositoryProtocol {
    func fetchProfile() async throws -> User
}

final class UserRepository: UserRepositoryProtocol {
    private let client: NetworkClientProtocol
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func fetchProfile() async throws -> User {
        let endpoint = Endpoint(path: "/user/profile")
        return try await client.requestAsync(endpoint)
    }
}
