//
//  CurrentlyPlayingResponse.swift
//  Spotify
//
//  Created by Mesut Aygün on 23.04.2025.
//

struct CurrentlyPlayingResponse: Codable {
    let timestamp: Int?
    let context: Context?
    let progress_ms: Int?
    let item: AudioTrack?
    let currently_playing_type: String?
    let actions: Actions?
    let is_playing: Bool?
}

struct Context: Codable {
    let external_urls: [String: String]?
    let href: String?
    let type: String?
    let uri: String?
}

struct Actions: Codable {
    let disallows: [String: Bool]?
}
