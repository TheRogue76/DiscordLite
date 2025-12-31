import Combine
import Foundation
import SwiftUI

@MainActor
final class GuildViewModel: ObservableObject {
    @Published var state: GuildViewModelState = .idle
    @Published var selectedGuild: Guild?

    private let guildRepository: GuildRepository
    private let logger: LoggerService
    private let sessionID: String

    init(
        guildRepository: GuildRepository,
        logger: LoggerService,
        sessionID: String
    ) {
        self.guildRepository = guildRepository
        self.logger = logger
        self.sessionID = sessionID
    }

    func loadGuilds(forceRefresh: Bool = false) async {
        logger.info("GuildViewModel: Loading guilds (forceRefresh: \(forceRefresh))")
        state = .loading

        let result = await guildRepository.getGuilds(
            sessionID: sessionID,
            forceRefresh: forceRefresh
        )

        switch result {
        case .success(let guilds):
            state = .loaded(guilds: guilds)
            logger.info("GuildViewModel: Loaded \(guilds.count) guilds")

            // Auto-select first guild if none selected
            if selectedGuild == nil, let firstGuild = guilds.first {
                selectedGuild = firstGuild
            }

        case .failure(let error):
            logger.error("GuildViewModel: Failed to load guilds", error: error)

            switch error {
            case .unauthorized:
                state = .error("Session expired. Please log in again.")
            case .networkError:
                state = .error("Network error. Please check your connection.")
            case .failedToFetchGuilds, .unknown:
                state = .error("Failed to load servers. Please try again.")
            }
        }
    }

    func selectGuild(_ guild: Guild) {
        logger.info("GuildViewModel: Selected guild: \(guild.name)")
        selectedGuild = guild
    }

    func refresh() async {
        await loadGuilds(forceRefresh: true)
    }
}
