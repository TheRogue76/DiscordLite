import Connect
import DiscordLiteAPI
import Foundation

final class ChannelGRPCDatasourceImpl: ChannelGRPCDatasource {
    private nonisolated(unsafe) let grpcClient: GRPCClient
    private nonisolated(unsafe) let logger: LoggerService
    private let channelService: Discord_Channel_V1_ChannelServiceClientInterface

    init(grpcClient: GRPCClient, logger: LoggerService) {
        self.grpcClient = grpcClient
        self.logger = logger
        self.channelService = Discord_Channel_V1_ChannelServiceClient(client: grpcClient.client)
    }

    func getChannels(
        sessionId: String,
        guildId: String,
        forceRefresh: Bool
    ) async -> Result<Discord_Channel_V1_GetChannelsResponse, ChannelGRPCDatasourceError> {
        guard !guildId.isEmpty else {
            logger.error("ChannelGRPCDatasource: Invalid guild ID", error: nil)
            return .failure(.invalidGuildId)
        }

        var request = Discord_Channel_V1_GetChannelsRequest()
        request.sessionID = sessionId
        request.guildID = guildId
        request.forceRefresh = forceRefresh

        let response = await channelService.getChannels(request: request, headers: .init())

        switch response.result {
        case .success(let success):
            logger.info("ChannelGRPCDatasource: Successfully fetched channels")
            return .success(success)

        case .failure(let failure):
            logger.error("ChannelGRPCDatasource: Failed to fetch channels", error: failure)

            let message = failure.message ?? ""
            if message.contains("unauthorized") || message.contains("401") {
                return .failure(.unauthorized)
            } else if message.contains("network") || failure.code == .unavailable {
                return .failure(.networkError)
            } else {
                return .failure(.fetchFailed)
            }
        }
    }
}
