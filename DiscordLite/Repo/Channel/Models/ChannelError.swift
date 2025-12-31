import Foundation

enum ChannelRepositoryError: Error, Equatable {
    case failedToFetchChannels
    case unauthorized
    case networkError
    case invalidGuildId
    case unknown(String)
}
