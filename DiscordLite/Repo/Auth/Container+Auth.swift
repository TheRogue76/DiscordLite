//
//  Container+Auth.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import FactoryKit

extension Container {
    // MARK: - Repo Layer
    var authGRPCDataSource: Factory<AuthGRPCDatasource> {
        self {
            AuthGRPCDatasourceImpl(
                grpcClient: self.grpcClient(),
                loggerService: self.logger()
            )
        }
        .singleton
    }

    var authRepository: Factory<AuthRepository> {
        self {
            AuthRepositoryImpl(
                authGRPCDataSource: self.authGRPCDataSource(),
                keychain: self.keychainService(),
                logger: self.logger()
            )
        }
        .singleton
    }
}
