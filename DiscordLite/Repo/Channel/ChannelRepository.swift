import Foundation

protocol ChannelRepository {
    func getChannels(
        sessionID: String,
        guildId: String,
        forceRefresh: Bool
    ) async -> Result<[Channel], ChannelRepositoryError>
}
