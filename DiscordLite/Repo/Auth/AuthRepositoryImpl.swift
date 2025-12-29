import DiscordLiteAPI
import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let authGRPCDataSource: AuthGRPCDatasource
    private let keychain: KeychainService
    private let logger: LoggerService
    private let sessionKey = "discord_session_id"

    init(authGRPCDataSource: AuthGRPCDatasource, keychain: KeychainService, logger: LoggerService) {
        self.authGRPCDataSource = authGRPCDataSource
        self.keychain = keychain
        self.logger = logger
    }

    func initAuth() async -> Result<(authURL: URL, sessionID: String), AuthRepositoryError> {
        let response = await authGRPCDataSource.getAuthUrl()

        switch response {
        case .success(let success):
            return .success((authURL: success.url, sessionID: success.sessionId))
        case .failure(let failure):
            logger.error("AuthRepo: Auth init failed", error: failure)
            return .failure(.failedToInitAuth)
        }
    }

    func pollAuthStatus(sessionID: String) async -> Result<AuthSession, AuthRepositoryError> {
        let startTime = Date()
        let timeout: TimeInterval = 60.0  // 60 seconds timeout
        let pollInterval: TimeInterval = 2.0  // Poll every 2 seconds

        while Date().timeIntervalSince(startTime) < timeout {
            let result = await authGRPCDataSource.getAuthStatus(sessionId: sessionID)

            switch result {
            case .success(let success):
                switch success.status {
                case .authenticated:
                    let session = AuthSession(
                        sessionID: sessionID
                    )
                    // Save session to keychain
                    switch keychain.save(key: sessionKey, value: sessionID) {
                    case .success:
                        return .success(session)
                    case .failure(let failure):
                        logger.error("AuthRepo: Failed to save token", error: failure)
                        return .failure(.failedToFetchStatus)
                    }
                case .pending:
                    logger.debug("Auth status: pending, continuing to poll...")
                case .UNRECOGNIZED, .failed, .unspecified:
                    logger.debug("AuthRepo: Received unrecognized auth status from backend: \(success)")
                    return .failure(.failedToFetchStatus)
                }
                try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
            case .failure(let failure):
                logger.error("AuthRepo: Failed to get auth status", error: failure)
                return .failure(.failedToFetchStatus)
            }
        }
        logger.error("AuthRepo: Polling for auth status timed out", error: nil)
        return .failure(.failedToFetchStatus)
    }

    func revokeAuth(sessionID: String) async -> Result<Void, AuthRepositoryError> {
        let response = await authGRPCDataSource.revokeAuth(sessionId: sessionID)
        switch response {
        case .success:
            let result = keychain.delete(key: sessionKey)
            switch result {
            case .success:
                return .success(())
            case .failure(let failure):
                logger.error("AuthRepo: Failed to clear token from storage", error: failure)
                return .failure(.failedToRevoke)
            }
        case .failure(let failure):
            logger.error("AuthRepo: API call to revoke session failed", error: failure)
            return .failure(.failedToRevoke)
        }
    }

    func getStoredSession() async -> Result<AuthSession?, AuthRepositoryError> {
        guard let sessionID = try? keychain.retrieve(key: sessionKey).get() else {
            return .success(nil)
        }

        return .success(
            AuthSession(
                sessionID: sessionID
            )
        )
    }
}
