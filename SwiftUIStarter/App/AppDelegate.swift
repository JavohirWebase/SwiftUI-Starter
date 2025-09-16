import UIKit
import OSLog

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NetworkMonitor.shared.startMonitoring()
        logger.info("App launched with environment: \(AppEnvironment.current.rawValue)")
#if DEBUG
        // Barcha constraint xatolarini o'chirish
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // UIKit debug log'larini o'chirish
        UserDefaults.standard.set(false, forKey: "_UIViewLayoutFeedbackLoopDebuggingThreshold")
#endif
        return true
    }
}
