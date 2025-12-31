import SwiftUI

enum MessageViewModelState: Equatable {
    case idle
    case loading
    case loaded(messages: [Message], hasMore: Bool)
    case loadingMore
    case error(LocalizedStringKey)
}
