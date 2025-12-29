import Foundation

struct AppConfig {
    let grpcHost: String
    let grpcPort: Int

    static let `default` = AppConfig(
        grpcHost: "http://localhost",
        grpcPort: 50051
    )
}
