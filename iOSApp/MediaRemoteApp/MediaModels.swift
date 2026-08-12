import SwiftUI

struct MediaInfo: Decodable, Equatable {
    let title: String
    let artist: String
    let album: String
    let albumArtURL: URL?
    let isPlaying: Bool
    let duration: TimeInterval
    let position: TimeInterval

    private enum CodingKeys: String, CodingKey {
        case title, artist, album, albumArtURL, albumArtUrl, isPlaying, duration, position
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        artist = try values.decodeIfPresent(String.self, forKey: .artist) ?? ""
        album = try values.decodeIfPresent(String.self, forKey: .album) ?? ""
        let preferredArtworkURL = try values.decodeIfPresent(URL.self, forKey: .albumArtURL)
        let alternateArtworkURL = try values.decodeIfPresent(URL.self, forKey: .albumArtUrl)
        albumArtURL = preferredArtworkURL ?? alternateArtworkURL
        isPlaying = try values.decodeIfPresent(Bool.self, forKey: .isPlaying) ?? false
        duration = try values.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        position = try values.decodeIfPresent(TimeInterval.self, forKey: .position) ?? 0
    }
}

enum MediaCommand: String {
    case play
    case pause
    case next
    case previous
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected

    var title: String {
        switch self {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting"
        case .connected: "Connected"
        }
    }

    var icon: String {
        switch self {
        case .disconnected: "wifi.slash"
        case .connecting: "wifi"
        case .connected: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .disconnected: .secondary
        case .connecting: .orange
        case .connected: .green
        }
    }
}
