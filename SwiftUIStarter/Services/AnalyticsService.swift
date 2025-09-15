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
