import Foundation

protocol GuildRepository {
    func getGuilds(sessionID: String, forceRefresh: Bool) async -> Result<[Guild], GuildRepositoryError>
}
