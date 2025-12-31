import SwiftUI

enum ChannelViewModelState: Equatable {
    case idle
    case loading
    case loaded(channels: [Channel])
    case error(LocalizedStringKey)
}
