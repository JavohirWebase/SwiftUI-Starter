#!/bin/bash

# SwiftUI Starter Project Setup Script
echo "Creating SwiftUI Starter Project Structure..."

# Create directory structure
mkdir -p SwiftUIStarter/App
mkdir -p SwiftUIStarter/Core
mkdir -p SwiftUIStarter/Configuration
mkdir -p SwiftUIStarter/Models
mkdir -p SwiftUIStarter/Network
mkdir -p SwiftUIStarter/Security
mkdir -p SwiftUIStarter/Services
mkdir -p SwiftUIStarter/Repositories
mkdir -p SwiftUIStarter/Navigation
mkdir -p SwiftUIStarter/ViewModels
mkdir -p SwiftUIStarter/Views/Components
mkdir -p SwiftUIStarter/Views/Screens
mkdir -p SwiftUIStarter/Views/Tabs
mkdir -p SwiftUIStarter/Extensions
mkdir -p SwiftUIStarter/DI

# Create App files
cat > SwiftUIStarter/App/SwiftUIStarterApp.swift << 'EOF'
import SwiftUI

@main
struct SwiftUIStarterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var coordinator = AppCoordinator()
    
    init() {
        DIContainer.shared.registerDependencies()
        AppearanceConfiguration.setup()
    }
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .environmentObject(appState)
                .environmentObject(coordinator)
                .preferredColorScheme(appState.theme.colorScheme)
                .onOpenURL { url in
                    coordinator.handleDeepLink(url)
                }
        }
    }
}
EOF

cat > SwiftUIStarter/App/AppDelegate.swift << 'EOF'
import UIKit
import OSLog

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NetworkMonitor.shared.startMonitoring()
        logger.info("App launched with environment: \(AppEnvironment.current.rawValue)")
        return true
    }
}
EOF

# Configuration
cat > SwiftUIStarter/Configuration/AppEnvironment.swift << 'EOF'
import Foundation

enum AppEnvironment: String {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://crm-api.webase.uz"
        case .staging:
            return "https://staging-api.webase.uz"
        case .production:
            return "https://api.webase.uz"
        }
    }
    
    var apiVersion: String { "" }
}
EOF

cat > SwiftUIStarter/Configuration/AppearanceConfiguration.swift << 'EOF'
import SwiftUI

enum AppearanceConfiguration {
    static func setup() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
EOF

# Core
cat > SwiftUIStarter/Core/AppState.swift << 'EOF'
import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var theme = Theme.system
    @Published var isLoading = false
    @Published var networkStatus: NetworkStatus = .connected
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeNetworkStatus()
        loadStoredUser()
    }
    
    private func observeNetworkStatus() {
        NetworkMonitor.shared.$status
            .assign(to: &$networkStatus)
    }
    
    private func loadStoredUser() {
        if let userData = UserDefaults.standard.data(forKey: "cached_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = user
            self.isAuthenticated = TokenManager.shared.hasValidToken()
        }
    }
    
    func setUser(_ user: User?) {
        self.user = user
        self.isAuthenticated = user != nil
        
        if let user = user,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "cached_user")
        } else {
            UserDefaults.standard.removeObject(forKey: "cached_user")
        }
    }
}

enum Theme: String, CaseIterable {
    case system, light, dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
EOF

# Models
cat > SwiftUIStarter/Models/User.swift << 'EOF'
import Foundation

struct User: Codable {
    let email: String?
    let firstName: String?
    let fullName: String?
    let id: Int?
    let employeeId: Int?
    let inn: String?
    let language: String?
    let languageId: Int?
    let lastName: String?
    let middleName: String?
    let modules: [String]?
    let organization: String?
    let organizationAddress: String?
    let organizationId: Int?
    let organizationInn: String?
    let organizationVatCode: String?
    let phoneNumber: String?
    let pinfl: String?
    let position: String?
    let roles: [String]?
    let shortName: String?
    let stateId: Int?
    let userName: String?
    let isOrgAdmin: Bool
    let isAdmin: Bool
    
    var displayName: String {
        fullName ?? shortName ?? userName ?? "User"
    }
    
    var initials: String {
        guard let firstName = firstName?.first,
              let lastName = lastName?.first else {
            return displayName.prefix(2).uppercased()
        }
        return "\(firstName)\(lastName)".uppercased()
    }
}
EOF

cat > SwiftUIStarter/Models/AuthModels.swift << 'EOF'
import Foundation

struct SignInRequest: Encodable {
    let username: String
    let password: String
}

struct SignInResponse: Decodable {
    let token: String
    let user: User
}
EOF

# Network
cat > SwiftUIStarter/Network/NetworkClient.swift << 'EOF'
import Foundation
import Combine
import OSLog

protocol NetworkClientProtocol {
    func requestAsync<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func requestAsync<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard NetworkMonitor.shared.isConnected else {
            throw NetworkError.noConnection
        }
        
        let request = try buildRequest(for: endpoint)
        
        logger.debug("Request: \(endpoint.method.rawValue) \(endpoint.path)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        logger.debug("Response: \(httpResponse.statusCode) \(endpoint.path)")
        
        try handleHTTPResponse(httpResponse, data: data)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = buildURL(for: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        var headers = endpoint.headers ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        if endpoint.requiresAuth {
            if let token = TokenManager.shared.getAccessToken() {
                headers["Authorization"] = "Bearer \(token)"
            }
        }
        
        request.allHTTPHeaderFields = headers
        
        if let parameters = endpoint.parameters {
            request.httpBody = try JSONEncoder().encode(parameters)
        }
        
        return request
    }
    
    private func buildURL(for endpoint: Endpoint) -> URL? {
        var components = URLComponents(string: AppEnvironment.current.baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems
        return components?.url
    }
    
    private func handleHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            NotificationCenter.default.post(name: .unauthorized, object: nil)
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError("Server error")
        default:
            throw NetworkError.unknown
        }
    }
}
EOF

cat > SwiftUIStarter/Network/Endpoint.swift << 'EOF'
import Foundation

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let parameters: Encodable?
    let queryItems: [URLQueryItem]?
    let headers: [String: String]?
    let requiresAuth: Bool
    
    init(
        path: String,
        method: HTTPMethod = .get,
        parameters: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.queryItems = queryItems
        self.headers = headers
        self.requiresAuth = requiresAuth
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
EOF

cat > SwiftUIStarter/Network/NetworkError.swift << 'EOF'
import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case decodingError
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noConnection:
            return "No internet connection"
        case .decodingError:
            return "Failed to process server response"
        case .unauthorized:
            return "Session expired. Please sign in again"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .serverError(let message):
            return message
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
EOF

cat > SwiftUIStarter/Network/NetworkMonitor.swift << 'EOF'
import Network
import Combine

enum NetworkStatus {
    case connected, disconnected, unknown
}

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var status: NetworkStatus = .unknown
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool {
        status == .connected
    }
    
    private init() {}
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.status = path.status == .satisfied ? .connected : .disconnected
            }
        }
        monitor.start(queue: queue)
    }
}
EOF

# Security
cat > SwiftUIStarter/Security/TokenManager.swift << 'EOF'
import Foundation

final class TokenManager {
    static let shared = TokenManager()
    private let keychain = KeychainService()
    
    private init() {}
    
    func saveToken(_ token: String) {
        keychain.save(token, for: .accessToken)
    }
    
    func getAccessToken() -> String? {
        return keychain.get(.accessToken)
    }
    
    func hasValidToken() -> Bool {
        return keychain.get(.accessToken) != nil
    }
    
    func clearTokens() {
        keychain.delete(.accessToken)
    }
}
EOF

cat > SwiftUIStarter/Security/KeychainService.swift << 'EOF'
import Security
import Foundation

final class KeychainService {
    enum Key: String {
        case accessToken = "app.auth.access_token"
    }
    
    private let service = Bundle.main.bundleIdentifier ?? "com.app.swiftuistarter"
    
    func save(_ value: String, for key: Key) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
EOF

# Navigation
cat > SwiftUIStarter/Navigation/AppCoordinator.swift << 'EOF'
import SwiftUI

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Sheet?
    
    enum Route: Hashable {
        case signIn
        case home
        case profile
        case settings
        case detail(id: String)
    }
    
    enum Sheet: Identifiable {
        case editProfile
        
        var id: String {
            String(describing: self)
        }
    }
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func present(sheet: Sheet) {
        self.sheet = sheet
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "profile":
            navigate(to: .profile)
        case "settings":
            navigate(to: .settings)
        default:
            break
        }
    }
}
EOF

cat > SwiftUIStarter/Navigation/CoordinatorView.swift << 'EOF'
import SwiftUI

struct CoordinatorView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .navigationDestination(for: AppCoordinator.Route.self) { route in
                switch route {
                case .signIn:
                    SignInView()
                case .home:
                    HomeView()
                case .profile:
                    ProfileView()
                case .settings:
                    SettingsView()
                case .detail(let id):
                    DetailView(id: id)
                }
            }
        }
        .sheet(item: $coordinator.sheet) { sheet in
            switch sheet {
            case .editProfile:
                EditProfileView()
            }
        }
    }
}
EOF

# DI
cat > SwiftUIStarter/DI/DIContainer.swift << 'EOF'
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
EOF

# Repositories
cat > SwiftUIStarter/Repositories/AuthRepository.swift << 'EOF'
import Foundation

protocol AuthRepositoryProtocol {
    func signIn(username: String, password: String) async throws -> User
    func signOut() async
}

final class AuthRepository: AuthRepositoryProtocol {
    private let client: NetworkClientProtocol
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func signIn(username: String, password: String) async throws -> User {
        let endpoint = Endpoint(
            path: "/Account/Login",
            method: .post,
            parameters: SignInRequest(username: username, password: password),
            requiresAuth: false
        )
        
        let response: SignInResponse = try await client.requestAsync(endpoint)
        TokenManager.shared.saveToken(response.token)
        return response.user
    }
    
    func signOut() async {
        TokenManager.shared.clearTokens()
    }
}
EOF

cat > SwiftUIStarter/Repositories/UserRepository.swift << 'EOF'
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
EOF

# ViewModels
cat > SwiftUIStarter/ViewModels/SignInViewModel.swift << 'EOF'
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
    
    func signIn() async {
        guard isValidForm else {
            showError(message: "Please enter username and password")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let user = try await repository.signIn(username: username, password: password)
            
            await MainActor.run {
                let appState = AppState()
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
EOF

# Services
cat > SwiftUIStarter/Services/AnalyticsService.swift << 'EOF'
import Foundation
import OSLog

final class AnalyticsService {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Analytics")
    
    enum Event {
        case signIn(method: String)
        case signOut
        case screenView(name: String)
        
        var name: String {
            switch self {
            case .signIn: return "sign_in"
            case .signOut: return "sign_out"
            case .screenView: return "screen_view"
            }
        }
        
        var parameters: [String: Any] {
            switch self {
            case .signIn(let method):
                return ["method": method]
            case .screenView(let name):
                return ["screen_name": name]
            default:
                return [:]
            }
        }
    }
    
    func track(_ event: Event) {
        logger.info("Event: \(event.name)")
    }
}
EOF

# Extensions
cat > SwiftUIStarter/Extensions/Notification+Names.swift << 'EOF'
import Foundation

extension Notification.Name {
    static let unauthorized = Notification.Name("app.unauthorized")
    static let sessionExpired = Notification.Name("app.session.expired")
}
EOF

# Views - SignInView
cat > SwiftUIStarter/Views/Screens/SignInView.swift << 'EOF'
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
                        await viewModel.signIn()
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
                await viewModel.signIn()
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
EOF

# Views - Components
cat > SwiftUIStarter/Views/Components/CustomTextField.swift << 'EOF'
import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var focused: FocusState<SignInView.Field?>.Binding
    let field: SignInView.Field
    var onSubmit: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .padding()
                .frame(height: 52)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused(focused, equals: field)
                .submitLabel(field == .username ? .next : .done)
                .onSubmit(onSubmit)
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var focused: FocusState<SignInView.Field?>.Binding
    let field: SignInView.Field
    var onSubmit: () -> Void = {}
    
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            HStack {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .focused(focused, equals: field)
                .submitLabel(.done)
                .onSubmit(onSubmit)
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(height: 52)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
EOF

# Views - MainTabView
cat > SwiftUIStarter/Views/Tabs/MainTabView.swift << 'EOF'
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}
EOF

# Views - HomeView
cat > SwiftUIStarter/Views/Screens/HomeView.swift << 'EOF'
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
EOF

# Views - ProfileView
cat > SwiftUIStarter/Views/Screens/ProfileView.swift << 'EOF'
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
EOF

# Views - SettingsView
cat > SwiftUIStarter/Views/Screens/SettingsView.swift << 'EOF'
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
EOF

# Views - Other screens
cat > SwiftUIStarter/Views/Screens/DetailView.swift << 'EOF'
import SwiftUI

struct DetailView: View {
    let id: String
    
    var body: some View {
        Text("Detail: \(id)")
            .navigationTitle("Detail")
    }
}
EOF

cat > SwiftUIStarter/Views/Screens/EditProfileView.swift << 'EOF'
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Edit Profile")
                .navigationTitle("Edit Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
EOF

echo "✅ SwiftUI Starter project created successfully!"
echo ""
echo "Files created in: ./SwiftUIStarter/"
echo ""
echo "Next steps:"
echo "1. Open Xcode and create a new SwiftUI project"
echo "2. Project Name: SwiftUI Starter"
echo "3. Drag the SwiftUIStarter folder into Xcode"
echo "4. Build and run!"
