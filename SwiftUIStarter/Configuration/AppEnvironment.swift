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
            return "https://crm-api.webase.uz"
        }
    }
    
    var apiVersion: String { "" }
}
