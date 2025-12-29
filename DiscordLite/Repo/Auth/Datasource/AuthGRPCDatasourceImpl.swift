//
//  AuthGRPCDatasourceImpl.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import Foundation
import DiscordLiteAPI
import Connect

class AuthGRPCDatasourceImpl: AuthGRPCDatasource {
    private let grpcClient: GRPCClient
    private let loggerService: LoggerService
    private let authService: Discord_Auth_V1_AuthServiceClientInterface
    
    init(grpcClient: GRPCClient, loggerService: LoggerService) {
        self.grpcClient = grpcClient
        self.loggerService = loggerService
        self.authService = Discord_Auth_V1_AuthServiceClient(client: grpcClient.client)
    }
    
    func getAuthUrl() async -> Result<(url: URL, sessionId: String), AuthGRPCDatasourceError> {
        let response = await authService.initAuth(request: .init(), headers: .init())
        
        switch response.result {
        case .success(let success):
            guard let url = URL(string: success.authURL) else {
                loggerService.error("Couldn't parse url from server", error: AuthGRPCDatasourceError.couldntParseUrlFromServer(url: success.authURL))
                return .failure(.couldntParseUrlFromServer(url: success.authURL))
            }
            return .success((url, success.sessionID))
        case .failure(let failure):
            loggerService.error("Failed to initialize auth", error: failure)
            return .failure(.getAuthUrlFailed)
        }
    }
    
    func getAuthStatus(sessionId: String) async -> Result<Discord_Auth_V1_GetAuthStatusResponse, AuthGRPCDatasourceError> {
        var payload = Discord_Auth_V1_GetAuthStatusRequest()
        payload.sessionID = sessionId
        let response = await authService.getAuthStatus(request: payload, headers: .init())
        
        switch response.result {
        case .success(let success):
            return .success(success)
        case .failure(let failure):
            loggerService.error("Failed to get auth state for sessionId: \(sessionId)", error: failure)
            return .failure(.getStatusFailed)
        }
    }
    
    
    func revokeAuth(sessionId: String) async -> Result<Bool, AuthGRPCDatasourceError> {
        var payload = Discord_Auth_V1_RevokeAuthRequest()
        payload.sessionID = sessionId
        let response = await authService.revokeAuth(request: payload, headers: .init())
        
        switch response.result {
        case .success(let success):
            return .success(success.success)
        case .failure(let failure):
            loggerService.error("AuthGRPCDatasource: Failed to revoke auth for sessionId: \(sessionId)", error: failure)
            return .failure(.failedToRevokeSession)
        }
    }
}
