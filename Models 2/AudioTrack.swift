//
//  AudioTrack.swift
//  Spotify
//
//  Created by Mesut Aygun on 2/14/21.
//

import Foundation

struct AudioTrack: Codable {
    var album: Album?
    let artists: [Artist]
    let available_markets: [String]
    let disc_number: Int
    let duration_ms: Int
    let explicit: Bool
    let external_urls: [String: String]
    let id: String
    let name: String
    let preview_url: String?

    enum CodingKeys: String, CodingKey {
        case album, artists, available_markets, disc_number, duration_ms,
             explicit, external_urls, id, name, preview_url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        album = try container.decodeIfPresent(Album.self, forKey: .album)
        artists = try container.decodeIfPresent([Artist].self, forKey: .artists) ?? []
        available_markets = try container.decodeIfPresent([String].self, forKey: .available_markets) ?? []
        disc_number = try container.decodeIfPresent(Int.self, forKey: .disc_number) ?? 0
        duration_ms = try container.decodeIfPresent(Int.self, forKey: .duration_ms) ?? 0
        explicit = try container.decodeIfPresent(Bool.self, forKey: .explicit) ?? false
        external_urls = try container.decodeIfPresent([String: String].self, forKey: .external_urls) ?? [:]
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        preview_url = try container.decodeIfPresent(String.self, forKey: .preview_url)
    }
}

