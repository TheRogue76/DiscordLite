//
//  GRPCClient.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import Foundation
import Connect
//import SwiftMockk

//@Mockable
protocol GRPCClient {
    var client: ProtocolClient { get }
}
