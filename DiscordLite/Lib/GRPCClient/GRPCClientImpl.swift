//
//  GRPCClientImpl.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import Connect
import ConnectNIO

class GRPCClientImpl: GRPCClient {
    var client: ProtocolClient
    
    init() {
        client = ProtocolClient(
            httpClient: NIOHTTPClient(host: "http://localhost", port: 50051),
            config: ProtocolClientConfig(
                host: "http://localhost:50051",
                networkProtocol: .grpc,
                codec: ProtoCodec(),
            )
        )
    }
}
