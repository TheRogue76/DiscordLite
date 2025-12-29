import Foundation
//import SwiftMockk

enum AuthRepositoryError: Error {
    case failedToInitAuth
    case failedToFetchStatus
    case failedToRevoke
}

//@Mockable
protocol AuthRepository {
    func initAuth() async -> Result<(authURL: URL, sessionID: String), AuthRepositoryError>
    func pollAuthStatus(sessionID: String) async -> Result<AuthSession, AuthRepositoryError>
    func revokeAuth(sessionID: String) async -> Result<Void, AuthRepositoryError>
    func getStoredSession() async -> Result<AuthSession?, AuthRepositoryError>
}
