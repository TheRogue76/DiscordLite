//
//  GRPCClientImpl.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import Connect
import ConnectNIO

class GRPCClientImpl: GRPCClient {
    private let appConfig: AppConfig
    var client: ProtocolClient

    init(appConfig: AppConfig) {
        self.appConfig = appConfig
        client = ProtocolClient(
            httpClient: NIOHTTPClient(host: appConfig.grpcHost, port: appConfig.grpcPort),
            config: ProtocolClientConfig(
                host: "\(appConfig.grpcHost):\(appConfig.grpcPort)",
                networkProtocol: .grpc,
                codec: ProtoCodec(),
            )
        )
    }
}
