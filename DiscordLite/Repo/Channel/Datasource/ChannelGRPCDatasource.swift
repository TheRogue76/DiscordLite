import DiscordLiteAPI
import Foundation

enum ChannelGRPCDatasourceError: Error {
    case fetchFailed
    case unauthorized
    case networkError
    case invalidGuildId
}

protocol ChannelGRPCDatasource {
    func getChannels(
        sessionId: String,
        guildId: String,
        forceRefresh: Bool
    ) async -> Result<Discord_Channel_V1_GetChannelsResponse, ChannelGRPCDatasourceError>
}
