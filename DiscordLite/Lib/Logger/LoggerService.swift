import Foundation
import OSLog

// import SwiftMockk

// @Mockable
protocol LoggerService {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String, error: Error?)
}
