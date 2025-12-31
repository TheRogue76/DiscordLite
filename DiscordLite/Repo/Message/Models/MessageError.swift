import Foundation

enum MessageRepositoryError: Error, Equatable {
    case failedToFetchMessages
    case unauthorized
    case networkError
    case invalidChannelId
    case invalidPagination
    case streamFailed
    case unknown(String)
}
