import Connect
import DiscordLiteAPI
import Foundation

final class GuildGRPCDatasourceImpl: GuildGRPCDatasource {
    private let grpcClient: GRPCClient
    private let logger: LoggerService
    private let channelService: Discord_Channel_V1_ChannelServiceClientInterface

    init(grpcClient: GRPCClient, logger: LoggerService) {
        self.grpcClient = grpcClient
        self.logger = logger
        self.channelService = Discord_Channel_V1_ChannelServiceClient(client: grpcClient.client)
    }

    func getGuilds(
        sessionId: String,
        forceRefresh: Bool
    ) async -> Result<Discord_Channel_V1_GetGuildsResponse, GuildGRPCDatasourceError> {
        var request = Discord_Channel_V1_GetGuildsRequest()
        request.sessionID = sessionId
        request.forceRefresh = forceRefresh

        let response = await channelService.getGuilds(request: request, headers: .init())

        switch response.result {
        case .success(let success):
            logger.info("GuildGRPCDatasource: Successfully fetched guilds")
            return .success(success)

        case .failure(let failure):
            logger.error("GuildGRPCDatasource: Failed to fetch guilds", error: failure)

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
