import SwiftUI

enum AuthViewModelState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(session: AuthSession)
    case error(LocalizedStringKey)
}
