import DiscordLiteAPI
import Foundation

final class ChannelRepositoryImpl: ChannelRepository {
    private nonisolated(unsafe) let channelGRPCDatasource: ChannelGRPCDatasource
    private nonisolated(unsafe) let logger: LoggerService

    nonisolated init(channelGRPCDatasource: ChannelGRPCDatasource, logger: LoggerService) {
        self.channelGRPCDatasource = channelGRPCDatasource
        self.logger = logger
    }

    func getChannels(
        sessionID: String,
        guildId: String,
        forceRefresh: Bool
    ) async -> Result<[Channel], ChannelRepositoryError> {
        guard !guildId.isEmpty else {
            return .failure(.invalidGuildId)
        }

        logger.info("ChannelRepo: Fetching channels for guild \(guildId)")

        let result = await channelGRPCDatasource.getChannels(
            sessionId: sessionID,
            guildId: guildId,
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let response):
            let channels = response.channels.enumerated().map { index, channelProto in
                let channelType: ChannelType
                switch channelProto.type {
                case .guildText:
                    channelType = .text
                case .guildVoice:
                    channelType = .voice
                case .guildAnnouncement:
                    channelType = .announcement
                default:
                    channelType = .unknown
                }

                return Channel(
                    id: "\(guildId)-\(index)",
                    name: channelProto.name,
                    type: channelType,
                    guildId: guildId
                )
            }
            logger.info("ChannelRepo: Fetched \(channels.count) channels")
            return .success(channels)

        case .failure(let error):
            logger.error("ChannelRepo: Failed to fetch channels", error: error)

            switch error {
            case .unauthorized:
                return .failure(.unauthorized)
            case .networkError:
                return .failure(.networkError)
            case .fetchFailed, .invalidGuildId:
                return .failure(.failedToFetchChannels)
            }
        }
    }
}
