import Foundation

struct AppConfig {
    let grpcHost: String
    let grpcPort: Int
    let authPollingInterval: TimeInterval
    let authTimeout: TimeInterval

    static let `default` = AppConfig(
        grpcHost: "localhost",
        grpcPort: 50051,
        authPollingInterval: 2.0,
        authTimeout: 60.0
    )
}
