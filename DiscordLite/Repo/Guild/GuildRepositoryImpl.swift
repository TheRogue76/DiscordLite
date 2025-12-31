import DiscordLiteAPI
import Foundation

final class GuildRepositoryImpl: GuildRepository {
    private nonisolated(unsafe) let guildGRPCDatasource: GuildGRPCDatasource
    private nonisolated(unsafe) let logger: LoggerService

    nonisolated init(guildGRPCDatasource: GuildGRPCDatasource, logger: LoggerService) {
        self.guildGRPCDatasource = guildGRPCDatasource
        self.logger = logger
    }

    func getGuilds(sessionID: String, forceRefresh: Bool) async -> Result<[Guild], GuildRepositoryError> {
        logger.info("GuildRepo: Fetching guilds (forceRefresh: \(forceRefresh))")

        let result = await guildGRPCDatasource.getGuilds(
            sessionId: sessionID,
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let response):
            let guilds = response.guilds.map { guildProto in
                Guild(
                    id: guildProto.discordGuildID,
                    name: guildProto.name
                )
            }
            logger.info("GuildRepo: Fetched \(guilds.count) guilds")
            return .success(guilds)

        case .failure(let error):
            logger.error("GuildRepo: Failed to fetch guilds", error: error)

            switch error {
            case .unauthorized:
                return .failure(.unauthorized)
            case .networkError:
                return .failure(.networkError)
            case .fetchFailed:
                return .failure(.failedToFetchGuilds)
            }
        }
    }
}
