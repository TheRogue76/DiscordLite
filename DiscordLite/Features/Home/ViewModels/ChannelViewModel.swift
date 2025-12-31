import Combine
import Foundation
import SwiftUI

@MainActor
final class ChannelViewModel: ObservableObject {
    @Published var state: ChannelViewModelState = .idle
    @Published var selectedChannel: Channel?

    private let channelRepository: ChannelRepository
    private let logger: LoggerService
    private let sessionID: String

    private var currentGuildId: String?

    init(
        channelRepository: ChannelRepository,
        logger: LoggerService,
        sessionID: String
    ) {
        self.channelRepository = channelRepository
        self.logger = logger
        self.sessionID = sessionID
    }

    func loadChannels(guildId: String, forceRefresh: Bool = false) async {
        // Reset selection if guild changed
        if currentGuildId != guildId {
            selectedChannel = nil
            currentGuildId = guildId
        }

        logger.info("ChannelViewModel: Loading channels for guild \(guildId)")
        state = .loading

        let result = await channelRepository.getChannels(
            sessionID: sessionID,
            guildId: guildId,
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let channels):
            // Filter to only text/announcement channels
            let textChannels = channels.filter { $0.type == .text || $0.type == .announcement }
            state = .loaded(channels: textChannels)
            logger.info("ChannelViewModel: Loaded \(textChannels.count) text channels")

            // Auto-select first text channel
            if selectedChannel == nil, let firstChannel = textChannels.first {
                selectedChannel = firstChannel
            }

        case .failure(let error):
            logger.error("ChannelViewModel: Failed to load channels", error: error)

            switch error {
            case .unauthorized:
                state = .error("Session expired. Please log in again.")
            case .networkError:
                state = .error("Network error. Please check your connection.")
            case .invalidGuildId:
                state = .error("Invalid server selected.")
            case .failedToFetchChannels, .unknown:
                state = .error("Failed to load channels. Please try again.")
            }
        }
    }

    func selectChannel(_ channel: Channel) {
        logger.info("ChannelViewModel: Selected channel: \(channel.name)")
        selectedChannel = channel
    }

    func refresh(guildId: String) async {
        await loadChannels(guildId: guildId, forceRefresh: true)
    }
}
