import Foundation
import OSLog

final class LoggerServiceImpl: LoggerService {
    private let subsystem = "com.nasirimehr.DiscordLite"

    private lazy var authLogger = Logger(subsystem: subsystem, category: "Auth")
    private lazy var networkLogger = Logger(subsystem: subsystem, category: "Network")
    private lazy var keychainLogger = Logger(subsystem: subsystem, category: "Keychain")
    private lazy var generalLogger = Logger(subsystem: subsystem, category: "General")

    func debug(_ message: String) {
        generalLogger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        generalLogger.info("\(message, privacy: .public)")
    }

    func error(_ message: String, error: Error?) {
        if let error = error {
            generalLogger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            generalLogger.error("\(message, privacy: .public)")
        }
    }
}
