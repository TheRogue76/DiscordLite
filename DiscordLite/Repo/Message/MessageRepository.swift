import Foundation

struct MessagePage {
    let messages: [Message]
    let hasMore: Bool
    let oldestMessageId: String?
}

protocol MessageRepository {
    func getMessages(
        sessionID: String,
        channelId: String,
        limit: Int,
        before: String?,
        forceRefresh: Bool
    ) async -> Result<MessagePage, MessageRepositoryError>

    func streamMessages(
        sessionID: String,
        channelIds: [String]
    ) async -> AsyncStream<Result<MessageEvent, MessageRepositoryError>>
}
