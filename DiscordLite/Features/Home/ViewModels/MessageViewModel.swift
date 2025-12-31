import Combine
import Foundation
import SwiftUI

@MainActor
final class MessageViewModel: ObservableObject {
    @Published var state: MessageViewModelState = .idle
    @Published var messages: [Message] = []

    private let messageRepository: MessageRepository
    private let logger: LoggerService
    private let sessionID: String

    private var currentChannelId: String?
    private var hasMore: Bool = false
    private var oldestMessageId: String?
    private var streamTask: Task<Void, Never>?

    private let pageSize = 50

    init(
        messageRepository: MessageRepository,
        logger: LoggerService,
        sessionID: String
    ) {
        self.messageRepository = messageRepository
        self.logger = logger
        self.sessionID = sessionID
    }

    deinit {
        streamTask?.cancel()
    }

    func loadMessages(channelId: String, forceRefresh: Bool = false) async {
        if currentChannelId != channelId {
            messages = []
            currentChannelId = channelId
            hasMore = false
            oldestMessageId = nil
        }

        logger.info("MessageViewModel: Loading messages for channel \(channelId)")
        state = .loading

        let result = await messageRepository.getMessages(
            sessionID: sessionID,
            channelId: channelId,
            limit: pageSize,
            before: nil,
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let page):
            messages = page.messages
            hasMore = page.hasMore
            oldestMessageId = page.oldestMessageId
            state = .loaded(messages: messages, hasMore: hasMore)
            logger.info("MessageViewModel: Loaded \(messages.count) messages")

        case .failure(let error):
            logger.error("MessageViewModel: Failed to load messages", error: error)
            handleError(error)
        }
    }

    func loadMoreMessages() async {
        guard let channelId = currentChannelId,
              let oldestId = oldestMessageId,
              hasMore,
              case .loaded = state else {
            return
        }

        logger.info("MessageViewModel: Loading more messages before \(oldestId)")
        state = .loadingMore

        let result = await messageRepository.getMessages(
            sessionID: sessionID,
            channelId: channelId,
            limit: pageSize,
            before: oldestId,
            forceRefresh: false
        )

        switch result {
        case .success(let page):
            messages = page.messages + messages
            hasMore = page.hasMore
            oldestMessageId = page.oldestMessageId
            state = .loaded(messages: messages, hasMore: hasMore)
            logger.info("MessageViewModel: Loaded \(page.messages.count) more messages")

        case .failure(let error):
            logger.error("MessageViewModel: Failed to load more messages", error: error)
            state = .loaded(messages: messages, hasMore: hasMore)
        }
    }

    func refresh() async {
        guard let channelId = currentChannelId else { return }
        await loadMessages(channelId: channelId, forceRefresh: true)
    }

    func startStreaming(channelId: String) {
        stopStreaming()

        logger.info("MessageViewModel: Starting message stream for channel \(channelId)")

        streamTask = Task {
            let stream = await messageRepository.streamMessages(
                sessionID: sessionID,
                channelIds: [channelId]
            )

            for await result in stream {
                guard !Task.isCancelled else {
                    logger.info("MessageViewModel: Stream cancelled")
                    break
                }

                switch result {
                case .success(let event):
                    await handleMessageEvent(event, for: channelId)

                case .failure(let error):
                    logger.error("MessageViewModel: Stream error", error: error)
                    break
                }
            }

            logger.info("MessageViewModel: Stream ended")
        }
    }

    func stopStreaming() {
        if streamTask != nil {
            logger.info("MessageViewModel: Stopping message stream")
            streamTask?.cancel()
            streamTask = nil
        }
    }

    private func handleMessageEvent(_ event: MessageEvent, for channelId: String) async {
        guard currentChannelId == channelId else {
            return
        }

        switch event.type {
        case .create:
            if let message = event.message {
                logger.debug("MessageViewModel: New message created: \(message.id)")
                messages.append(message)
                if case .loaded = state {
                    state = .loaded(messages: messages, hasMore: hasMore)
                }
            }

        case .update:
            if let updatedMessage = event.message,
               let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                logger.debug("MessageViewModel: Message updated: \(updatedMessage.id)")
                messages[index] = updatedMessage
                if case .loaded = state {
                    state = .loaded(messages: messages, hasMore: hasMore)
                }
            }

        case .delete:
            if let deletedId = event.deletedMessageId,
               let index = messages.firstIndex(where: { $0.id == deletedId }) {
                logger.debug("MessageViewModel: Message deleted: \(deletedId)")
                messages.remove(at: index)
                if case .loaded = state {
                    state = .loaded(messages: messages, hasMore: hasMore)
                }
            }

        case .unknown:
            logger.debug("MessageViewModel: Unknown event type received")
        }
    }

    private func handleError(_ error: MessageRepositoryError) {
        switch error {
        case .unauthorized:
            state = .error("Session expired. Please log in again.")
        case .networkError:
            state = .error("Network error. Please check your connection.")
        case .invalidChannelId:
            state = .error("Invalid channel selected.")
        case .invalidPagination:
            state = .error("Pagination error. Please try again.")
        case .streamFailed:
            state = .error("Message stream failed. Please refresh.")
        case .failedToFetchMessages, .unknown:
            state = .error("Failed to load messages. Please try again.")
        }
    }
}
