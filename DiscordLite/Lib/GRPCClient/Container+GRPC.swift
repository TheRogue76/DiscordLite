//
//  Container+GRPC.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import FactoryKit

extension Container {
    var grpcClient: Factory<GRPCClient> {
        self {
            GRPCClientImpl(
                appConfig: self.appConfig()
            )
        }
            .singleton
    }
}
