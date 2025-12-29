import Foundation
import OSLog

final class LoggerServiceImpl: LoggerService {
    private let subsystem = "com.nasirimehr.DiscordLite"

    private lazy var generalLogger = Logger(subsystem: subsystem, category: "General")

    func debug(_ message: String) {
        generalLogger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        generalLogger.info("\(message, privacy: .public)")
    }

    func error(_ message: String, error: Error?) {
        if let error = error {
            generalLogger.error("\(message, privacy: .private): \(error.localizedDescription, privacy: .public)")
        } else {
            generalLogger.error("\(message, privacy: .private)")
        }
    }
}
