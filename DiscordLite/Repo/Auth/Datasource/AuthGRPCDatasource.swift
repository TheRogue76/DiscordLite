//
//  AuthGRPCDatasource.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import DiscordLiteAPI
import Foundation

// import SwiftMockk

enum AuthGRPCDatasourceError: Error {
    case getAuthUrlFailed
    case couldntParseUrlFromServer(url: String)
    case getStatusFailed
    case failedToRevokeSession
}

// @Mockable
protocol AuthGRPCDatasource {
    func getAuthUrl() async -> Result<(url: URL, sessionId: String), AuthGRPCDatasourceError>
    func getAuthStatus(sessionId: String) async -> Result<
        Discord_Auth_V1_GetAuthStatusResponse, AuthGRPCDatasourceError
    >
    func revokeAuth(sessionId: String) async -> Result<Bool, AuthGRPCDatasourceError>
}
