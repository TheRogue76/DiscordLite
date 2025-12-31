import Foundation

enum MessageEventType: String, Codable {
    case create = "MESSAGE_EVENT_TYPE_CREATE"
    case update = "MESSAGE_EVENT_TYPE_UPDATE"
    case delete = "MESSAGE_EVENT_TYPE_DELETE"
    case unknown = "MESSAGE_EVENT_TYPE_UNSPECIFIED"
}

struct MessageEvent: Equatable {
    let type: MessageEventType
    let message: Message?
    let deletedMessageId: String?

    static func create(message: Message) -> MessageEvent {
        MessageEvent(type: .create, message: message, deletedMessageId: nil)
    }

    static func update(message: Message) -> MessageEvent {
        MessageEvent(type: .update, message: message, deletedMessageId: nil)
    }

    static func delete(messageId: String) -> MessageEvent {
        MessageEvent(type: .delete, message: nil, deletedMessageId: messageId)
    }
}
