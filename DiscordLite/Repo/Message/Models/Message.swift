import Foundation

struct Message: Codable, Equatable, Identifiable {
    let id: String
    let author: MessageAuthor
    let content: String
    let timestamp: Date
    let channelId: String

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct MessageAuthor: Codable, Equatable {
    let username: String
    let avatarURL: String?

    var initial: String {
        String(username.prefix(1).uppercased())
    }
}
