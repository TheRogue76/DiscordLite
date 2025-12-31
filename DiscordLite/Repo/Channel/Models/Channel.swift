import Foundation

struct Channel: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let type: ChannelType
    let guildId: String
}

enum ChannelType: String, Codable {
    case text = "TEXT"
    case voice = "VOICE"
    case announcement = "ANNOUNCEMENT"
    case unknown = "UNKNOWN"

    var icon: String {
        switch self {
        case .text: return "number"
        case .voice: return "speaker.wave.2"
        case .announcement: return "megaphone"
        case .unknown: return "questionmark.circle"
        }
    }
}
