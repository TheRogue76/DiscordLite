import DiscordLiteAPI
import Foundation

enum GuildGRPCDatasourceError: Error {
    case fetchFailed
    case unauthorized
    case networkError
}

protocol GuildGRPCDatasource {
    func getGuilds(
        sessionId: String,
        forceRefresh: Bool
    ) async -> Result<Discord_Channel_V1_GetGuildsResponse, GuildGRPCDatasourceError>
}
