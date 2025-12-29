//
//  Container+Logger.swift
//  DiscordLite
//
//  Created by Parsa's Content Creation Corner on 2025-12-29.
//
import FactoryKit

extension Container {
    var logger: Factory<LoggerService> {
        self { LoggerServiceImpl() }
            .singleton
    }
}
