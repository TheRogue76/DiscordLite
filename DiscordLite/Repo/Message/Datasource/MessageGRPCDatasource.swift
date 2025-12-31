import DiscordLiteAPI
import Foundation

enum MessageGRPCDatasourceError: Error {
    case fetchFailed
    case unauthorized
    case networkError
    case invalidChannelId
    case streamFailed
}

protocol MessageGRPCDatasource {
    func getMessages(
        sessionId: String,
        channelId: String,
        limit: UInt32,
        before: String,
        forceRefresh: Bool
    ) async -> Result<Discord_Message_V1_GetMessagesResponse, MessageGRPCDatasourceError>

    func streamMessages(
        sessionId: String,
        channelIds: [String]
    ) async -> AsyncStream<Result<Discord_Message_V1_MessageEvent, MessageGRPCDatasourceError>>
}
