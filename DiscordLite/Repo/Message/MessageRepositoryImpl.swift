import DiscordLiteAPI
import Foundation

final class MessageRepositoryImpl: MessageRepository {
    private nonisolated(unsafe) let messageGRPCDatasource: MessageGRPCDatasource
    private nonisolated(unsafe) let logger: LoggerService

    nonisolated init(messageGRPCDatasource: MessageGRPCDatasource, logger: LoggerService) {
        self.messageGRPCDatasource = messageGRPCDatasource
        self.logger = logger
    }

    func getMessages(
        sessionID: String,
        channelId: String,
        limit: Int,
        before: String?,
        forceRefresh: Bool
    ) async -> Result<MessagePage, MessageRepositoryError> {
        guard !channelId.isEmpty else {
            return .failure(.invalidChannelId)
        }

        guard limit > 0 && limit <= 100 else {
            logger.error("MessageRepo: Invalid limit: \(limit)", error: nil)
            return .failure(.invalidPagination)
        }

        logger.info("MessageRepo: Fetching messages for channel \(channelId)")

        let result = await messageGRPCDatasource.getMessages(
            sessionId: sessionID,
            channelId: channelId,
            limit: UInt32(limit),
            before: before ?? "",
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let response):
            let messages = response.messages.map { msgProto -> Message in
                let date = Date(timeIntervalSince1970: TimeInterval(msgProto.timestamp))

                return Message(
                    id: msgProto.discordMessageID,
                    author: MessageAuthor(
                        username: msgProto.author.username,
                        avatarURL: nil
                    ),
                    content: msgProto.content,
                    timestamp: date,
                    channelId: channelId
                )
            }

            let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
            let hasMore = messages.count == limit
            let oldestId = sortedMessages.first?.id

            let page = MessagePage(
                messages: sortedMessages,
                hasMore: hasMore,
                oldestMessageId: oldestId
            )

            logger.info("MessageRepo: Fetched \(messages.count) messages")
            return .success(page)

        case .failure(let error):
            logger.error("MessageRepo: Failed to fetch messages", error: error)

            switch error {
            case .unauthorized:
                return .failure(.unauthorized)
            case .networkError:
                return .failure(.networkError)
            case .fetchFailed, .invalidChannelId, .streamFailed:
                return .failure(.failedToFetchMessages)
            }
        }
    }

    func streamMessages(
        sessionID: String,
        channelIds: [String]
    ) async -> AsyncStream<Result<MessageEvent, MessageRepositoryError>> {
        logger.info("MessageRepo: Starting message stream for channels: \(channelIds)")

        return AsyncStream { continuation in
            let task = Task {
                let stream = await messageGRPCDatasource.streamMessages(
                    sessionId: sessionID,
                    channelIds: channelIds
                )

                for await result in stream {
                    switch result {
                    case .success(let eventProto):
                        let messageEvent = self.mapToMessageEvent(eventProto)
                        continuation.yield(.success(messageEvent))

                    case .failure(let error):
                        logger.error("MessageRepo: Stream error", error: error)

                        let repoError: MessageRepositoryError
                        switch error {
                        case .unauthorized:
                            repoError = .unauthorized
                        case .networkError:
                            repoError = .networkError
                        case .fetchFailed, .streamFailed, .invalidChannelId:
                            repoError = .streamFailed
                        }

                        continuation.yield(.failure(repoError))
                        continuation.finish()
                        return
                    }
                }

                logger.info("MessageRepo: Stream completed")
                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    private func mapToMessageEvent(_ eventProto: Discord_Message_V1_MessageEvent) -> MessageEvent {
        // Extract message from event
        guard eventProto.hasMessage else {
            return MessageEvent(type: .unknown, message: nil, deletedMessageId: nil)
        }

        let msgProto = eventProto.message
        let date = Date(timeIntervalSince1970: TimeInterval(msgProto.timestamp))

        let message = Message(
            id: msgProto.discordMessageID,
            author: MessageAuthor(
                username: msgProto.author.username,
                avatarURL: nil
            ),
            content: msgProto.content,
            timestamp: date,
            channelId: msgProto.channelID
        )

        // For now, assume all events are message creates
        // The event type differentiation will need proper protobuf mapping
        return MessageEvent.create(message: message)
    }
}
