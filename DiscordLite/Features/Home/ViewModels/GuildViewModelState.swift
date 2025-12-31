import SwiftUI

enum GuildViewModelState: Equatable {
    case idle
    case loading
    case loaded(guilds: [Guild])
    case error(LocalizedStringKey)
}
