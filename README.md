# SwiftUI Starter - CRM Mobile Application

A production-ready iOS application built with SwiftUI, following enterprise-level architecture patterns and best practices.

## 📱 Overview

SwiftUI Starter is a modern CRM (Customer Relationship Management) mobile application designed for iOS 16.0+. The app provides secure authentication, user management, and comprehensive business modules for organization management.

## 🏗 Architecture

The project follows **MVVM-C (Model-View-ViewModel-Coordinator)** architecture with **Repository Pattern** and **Dependency Injection**.

### Core Architecture Components

- **MVVM Pattern**: Clean separation between Views, ViewModels, and Models
- **Coordinator Pattern**: Centralized navigation management
- **Repository Pattern**: Data layer abstraction for API and local storage
- **Dependency Injection**: Service registration and resolution via DIContainer
- **Protocol-Oriented Design**: Extensive use of protocols for flexibility and testability

## 🛠 Tech Stack

### Core Technologies
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Minimum iOS**: 16.0
- **Async Programming**: Swift Concurrency (async/await)
- **Networking**: Native URLSession
- **Storage**: Keychain Services
- **Logging**: OSLog

### Key Features
- ✅ Modern async/await for all API calls
- ✅ Secure token storage in Keychain
- ✅ Network monitoring with NWPathMonitor
- ✅ Environment-based configuration (Dev/Staging/Prod)
- ✅ Deep linking support
- ✅ Theme management (Light/Dark/System)
- ✅ Comprehensive error handling

## 📁 Project Structure

```
SwiftUIStarter/
├── App/
│   ├── SwiftUIStarterApp.swift    # App entry point
│   └── AppDelegate.swift           # App lifecycle management
│
├── Core/
│   └── AppState.swift              # Global app state management
│
├── Configuration/
│   ├── AppEnvironment.swift        # Environment configuration
│   └── AppearanceConfiguration.swift
│
├── Models/
│   ├── User.swift                  # User model with 30+ properties
│   └── AuthModels.swift            # Authentication models
│
├── Network/
│   ├── NetworkClient.swift         # Generic network client
│   ├── Endpoint.swift              # API endpoint configuration
│   ├── NetworkError.swift          # Network error types
│   └── NetworkMonitor.swift        # Connection monitoring
│
├── Security/
│   ├── TokenManager.swift          # Token lifecycle management
│   └── KeychainService.swift       # Secure storage wrapper
│
├── Repositories/
│   ├── AuthRepository.swift        # Authentication data layer
│   └── UserRepository.swift        # User data management
│
├── ViewModels/
│   └── SignInViewModel.swift       # Sign-in business logic
│
├── Views/
│   ├── Components/
│   │   └── CustomTextField.swift   # Reusable UI components
│   ├── Screens/
│   │   ├── SignInView.swift
│   │   ├── HomeView.swift
│   │   ├── ProfileView.swift
│   │   └── SettingsView.swift
│   └── Tabs/
│       └── MainTabView.swift
│
├── Navigation/
│   ├── AppCoordinator.swift        # Navigation management
│   └── CoordinatorView.swift       # Navigation container
│
├── DI/
│   └── DIContainer.swift           # Dependency injection
│
├── Services/
│   └── AnalyticsService.swift      # Analytics tracking
│
└── Extensions/
    └── Notification+Names.swift    # Swift extensions
```

## 🔌 API Integration

### Base Configuration
- **Development URL**: `https://crm-api.webase.uz`
- **Authentication**: Bearer Token (JWT)
- **Content-Type**: `application/json`

### Key Endpoints
```swift
POST /account/GenerateToken  // User authentication
GET  /user/profile           // Get user profile
PUT  /user/profile           // Update profile
```

### Request/Response Flow
1. All requests go through `NetworkClient`
2. Endpoints are configured via `Endpoint` struct
3. Repositories handle business logic
4. ViewModels manage UI state
5. Views react to state changes

## 🔐 Authentication Flow

1. **Login Process**:
   - User enters username/password
   - `SignInViewModel` validates input
   - `AuthRepository` calls `/account/GenerateToken`
   - Tokens stored in Keychain
   - User object saved to AppState
   - Navigation to MainTabView

2. **Token Management**:
   - Access token stored securely
   - Refresh token for session renewal
   - Automatic token injection in requests
   - Token expiration handling

## 🎨 UI/UX Features

### Design System
- Adaptive color scheme (Light/Dark/System)
- SF Symbols for consistent iconography
- Responsive layouts for all screen sizes
- Loading states and error handling
- Form validation with real-time feedback

### Navigation
- Tab-based navigation (Home, Profile, Settings)
- Coordinator pattern for complex flows
- Deep linking support
- Sheet and full-screen modal presentations

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Swift 5.9+

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/swiftui-starter.git
cd swiftui-starter
```

2. **Open in Xcode**
```bash
open SwiftUIStarter.xcodeproj
```

3. **Configure environment**
   - Update `AppEnvironment.swift` with your API URLs
   - Set your bundle identifier
   - Configure signing & capabilities

4. **Build and run**
   - Select target device/simulator
   - Press Cmd+R to build and run

## 🔧 Configuration

### Environment Setup
Edit `AppEnvironment.swift`:
```swift
var baseURL: String {
    switch self {
    case .development:
        return "https://your-dev-api.com"
    case .staging:
        return "https://your-staging-api.com"
    case .production:
        return "https://your-prod-api.com"
    }
}
```

### Adding New Features

#### 1. New API Endpoint
```swift
// In Endpoint extension
static func newFeature() -> Endpoint {
    Endpoint(
        path: "/api/feature",
        method: .get,
        requiresAuth: true
    )
}
```

#### 2. New Repository
```swift
protocol FeatureRepositoryProtocol {
    func fetchData() async throws -> FeatureModel
}

final class FeatureRepository: FeatureRepositoryProtocol {
    private let client: NetworkClientProtocol
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func fetchData() async throws -> FeatureModel {
        let endpoint = Endpoint.newFeature()
        return try await client.requestAsync(endpoint)
    }
}
```

#### 3. Register in DI Container
```swift
// In DIContainer.registerDependencies()
register(FeatureRepository.self) { 
    FeatureRepository(client: networkClient) 
}
```

## 📊 User Model

The User model supports comprehensive CRM functionality with 30+ properties:

### Key Properties
- **Identity**: id, userName, fullName, firstName, lastName, middleName
- **Organization**: organizationId, organization, organizationInn, position
- **Permissions**: isAdmin, isOrgAdmin, isSuperAdmin, roles, modules
- **Contact**: email, phoneNumber
- **Localization**: language, languageId, languageCode

### Module System
The app supports 100+ business modules including:
- Cash Management
- Invoice Processing
- Manufacturing Reports
- Contractor Management
- Warehouse Operations
- Employee Management
- Financial Reports

## 🔒 Security

### Implemented Security Measures
- ✅ Keychain storage for sensitive data
- ✅ Bearer token authentication
- ✅ Secure HTTPS connections
- ✅ Input validation
- ✅ Session management

### Best Practices
- No sensitive data in UserDefaults
- Tokens never logged in production
- Automatic session cleanup on logout
- Network monitoring for connection security

## 🧪 Testing Strategy

### Recommended Test Coverage
- **Unit Tests**: ViewModels, Repositories, Services
- **Integration Tests**: API communication
- **UI Tests**: Critical user flows
- **Snapshot Tests**: UI consistency

### Test Structure
```
SwiftUIStarterTests/
├── ViewModels/
├── Repositories/
├── Services/
└── Mocks/
```

## 📈 Performance

### Optimizations
- Lazy loading for heavy views
- Image caching strategy
- Efficient list rendering
- Memory leak prevention
- Background task management

### Monitoring
- OSLog for debugging
- Analytics service for user behavior
- Network request logging
- Performance metrics tracking

## 🚨 Error Handling

### Network Errors
```swift
enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case decodingError
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case unknown
}
```

### User-Facing Errors
- Descriptive error messages
- Retry mechanisms
- Fallback UI states
- Offline mode indication

## 📝 Code Style

### Conventions
- **Naming**: Swift API Design Guidelines
- **Formatting**: 4 spaces indentation
- **Comments**: Minimal, self-documenting code
- **File Organization**: One type per file
- **Access Control**: Explicit private/public

### SwiftLint Rules (Recommended)
```yaml
disabled_rules:
  - line_length
  - file_length
  
opt_in_rules:
  - empty_count
  - closure_spacing
  - collection_alignment
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential.

## 👥 Team

- **Architecture**: Lead Developer
- **Backend**: CRM API Team (Webase)
- **Platform**: iOS 16.0+

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact the development team
- Check the API documentation

## 🔄 Version History

### v1.0.0 (Current)
- Initial release
- Basic authentication
- User management
- Organization features
- Module system

### Roadmap
- [ ] Biometric authentication
- [ ] Offline mode
- [ ] Push notifications
- [ ] Data synchronization
- [ ] Advanced reporting

## 🏆 Why This Architecture?

### No External Dependencies
- **No Alamofire**: Native URLSession with async/await
- **No RxSwift**: SwiftUI + Combine
- **No Realm**: Core Data + Keychain
- **Result**: Smaller app size, better performance, fewer vulnerabilities

### Modern Swift
- Async/await for all asynchronous operations
- @MainActor for UI updates
- Property wrappers for state management
- Result types for error handling

### Enterprise Ready
- Scalable to 100+ screens
- Team collaboration friendly
- Testable architecture
- Production-proven patterns

---

**Built with ❤️ using SwiftUI and modern iOS development best practices**
