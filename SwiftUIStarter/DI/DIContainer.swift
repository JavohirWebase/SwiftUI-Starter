import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private var services: [String: Any] = [:]
    
    private init() {}
    
    func registerDependencies() {
        let networkClient = NetworkClient()
        let analyticsService = AnalyticsService()
        
        register(NetworkClientProtocol.self) { networkClient }
        register(NetworkClient.self) { networkClient }
        
        register(AuthRepositoryProtocol.self) {
            AuthRepository(client: networkClient)
        }
        register(AuthRepository.self) {
            AuthRepository(client: networkClient)
        }
        
        register(UserRepositoryProtocol.self) {
            UserRepository(client: networkClient)
        }
        register(UserRepository.self) {
            UserRepository(client: networkClient)
        }
        
        register(AnalyticsService.self) { analyticsService }
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        services[String(describing: type)] = factory
    }
    
    func resolve<T>() -> T {
        let key = String(describing: T.self)
        guard let factory = services[key] as? () -> T else {
            fatalError("Dependency \(T.self) not registered")
        }
        return factory()
    }
}
