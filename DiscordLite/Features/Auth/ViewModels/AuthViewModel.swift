import Foundation
import SwiftUI
import FactoryKit
import AppKit
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthViewModelState = .unauthenticated

    private let authRepository: AuthRepository
    private let logger: LoggerService

    private var pollingTask: Task<Void, Error>?
    
    init(authRepository: AuthRepository, logger: LoggerService) {
        self.authRepository = authRepository
        self.logger = logger
    }

    func checkExistingSession() async {
        logger.info("Checking for existing session")

        let result = await authRepository.getStoredSession()
        switch result {
        case .success(let success):
            guard let session = success else {
                state = .unauthenticated
                return
            }
            state = .authenticated(session: session)
        case .failure(_):
            state = .unauthenticated
        }
    }

    func startAuth() async {
        logger.info("Starting authentication flow")
        let result = await authRepository.initAuth()
        
        switch result {
        case .success((let url, let sessionID)):
            state = .authenticating

            // Open URL in default browser
            NSWorkspace.shared.open(url)

            // Start polling for auth status
            startPolling(sessionID: sessionID)
            break
        case .failure(let error):
            logger.error("Failed to start auth", error: error)
            state = .error("Failed to start auth")
        }
    }

    func startPolling(sessionID: String) {
        pollingTask?.cancel()

        pollingTask = Task { [weak self] in
            guard let self = self else { return }

            let result = await self.authRepository.pollAuthStatus(sessionID: sessionID)
            
            switch result {
            case .success(let success):
                await MainActor.run {
                    self.state = .authenticated(session: success)
                }
            case .failure(let failure):
                await MainActor.run {
                    if !Task.isCancelled {
                        self.state = .error("Failed to login with discord, please try again later")
                    }
                }
            }
        }
    }

    func cancelAuth() {
        logger.info("Cancelling authentication")
        pollingTask?.cancel()
        pollingTask = nil
        state = .unauthenticated
    }

    func logout() async {
        logger.info("Logging out")

        guard case .authenticated(let session) = state else {
            logger.error("Cannot logout: not authenticated", error: nil)
            return
        }

//        do {
        let result = await authRepository.revokeAuth(sessionID: session.sessionID)
        switch result {
        case .success():
            state = .unauthenticated
            logger.info("Logout successful")
        case .failure(let failure):
            logger.error("Logout failed", error: failure)
            // Even if revocation fails, clear local state
            state = .unauthenticated
        }
    }

    deinit {
        pollingTask?.cancel()
    }
}
