import Foundation

enum GuildRepositoryError: Error, Equatable {
    case failedToFetchGuilds
    case unauthorized
    case networkError
    case unknown(String)
}
